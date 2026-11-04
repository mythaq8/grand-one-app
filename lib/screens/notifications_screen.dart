// lib/screens/notifications_screen.dart
// ============================================================
// NotificationsScreen — شاشة الإشعارات للمستخدم
// ============================================================

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_colors.dart';
import '../services/api_exceptions.dart';
import '../services/api_service.dart';
import '../utils/error_handler.dart';
import '../widgets/brand_decorations.dart';
import '../ui/shell/app_shell.dart';
import 'my_bookings_screen.dart';
import 'my_occasion_requests_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  Object? _error;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await ApiService.getNotifications(limit: 50);
      final list = _extractList(data, 'data');

      // احسب غير المقروء
      int unread = 0;
      for (final n in list) {
        if (n['is_read'] != true) unread++;
      }

      if (!mounted) return;

      setState(() {
        _notifications = list;
        _unreadCount = unread;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e;
      });
    }
  }

  List<Map<String, dynamic>> _extractList(
    Map<String, dynamic> data,
    String key,
  ) {
    final value = data[key];
    if (value is List) {
      return value
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }

  Future<void> _markRead(Map<String, dynamic> userNotif) async {
    final id = userNotif['id']?.toString();
    if (id == null || id.isEmpty) return;

    if (userNotif['is_read'] == true) {
      await _openStage(userNotif);
      return;
    }

    try {
      await ApiService.markNotificationRead(id);

      if (!mounted) return;

      setState(() {
        userNotif['is_read'] = true;
        userNotif['read_at'] = DateTime.now().toIso8601String();
        if (_unreadCount > 0) _unreadCount--;
      });
      await _openStage(userNotif);
    } catch (_) {
      // نتجاهل
    }
  }

  Future<void> _openStage(Map<String, dynamic> userNotif) async {
    if (!mounted) return;
    final notification = userNotif['notification'];
    if (notification is! Map) return;
    final n = Map<String, dynamic>.from(notification);
    final text = '${n['title'] ?? ''} ${n['body'] ?? ''}';
    final data = n['data'];
    final dataType = data is Map ? data['type']?.toString() : null;

    final role = await _currentRole();
    if (!mounted) return;

    Widget? screen;
    if (text.contains('حجز') ||
        text.contains('سعر') ||
        dataType == 'booking' ||
        dataType == 'service_booking') {
      screen = const MyBookingsScreen();
    } else if (text.contains('حفلة') ||
        text.contains('سهرة') ||
        text.contains('مناسبة') ||
        dataType == 'occasion' ||
        dataType == 'party') {
      screen = const MyOccasionRequestsScreen();
    } else if (text.contains('توثيق') || dataType == 'account') {
      screen = const AppShell();
    }
    // تجاهل إشعارات الزواج القديمة إن وُجدت في الحسابات القديمة.
    if (role == 'groom' || role == 'bride') {
      screen = null;
    }

    if (screen == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen!),
    );
  }

  Future<String?> _currentRole() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return null;
      final row = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .maybeSingle();
      return row?['role']?.toString();
    } catch (_) {
      return null;
    }
  }

  Future<void> _markAllRead() async {
    if (_unreadCount == 0) return;

    try {
      await ApiService.markAllNotificationsRead();

      if (!mounted) return;

      setState(() {
        for (final n in _notifications) {
          n['is_read'] = true;
          n['read_at'] = DateTime.now().toIso8601String();
        }
        _unreadCount = 0;
      });

      ErrorHandler.showSuccess(context, 'تم تعليم الكل كمقروء');
    } catch (_) {
      // نتجاهل
    }
  }

  @override
  Widget build(BuildContext context) {
    return BrandScaffold(
      showPattern: false,
      appBar: BrandAppBar(
        title: 'الإشعارات',
        actions: [
          if (_unreadCount > 0)
            IconButton(
              tooltip: 'تعليم الكل',
              onPressed: _markAllRead,
              icon: const Icon(Icons.done_all_rounded),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_notifications.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
        itemCount: _notifications.length,
        itemBuilder: (context, index) =>
            _buildNotificationCard(_notifications[index]),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> userNotif) {
    final isRead = userNotif['is_read'] == true;
    final notification = userNotif['notification'];

    if (notification is! Map) {
      return const SizedBox.shrink();
    }

    final n = Map<String, dynamic>.from(notification);
    final title = n['title']?.toString() ?? '';
    final body = n['body']?.toString() ?? '';
    final createdAt =
        n['created_at']?.toString() ?? userNotif['created_at']?.toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => _markRead(userNotif),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isRead
                  ? AppColors.borderLight
                  : AppColors.gold.withValues(alpha: 0.45),
            ),
            boxShadow: AppColors.shadowSubtle,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ═══ أيقونة ═══
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isRead
                      ? AppColors.surfaceTint
                      : AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isRead
                        ? AppColors.borderLight
                        : AppColors.gold.withValues(alpha: 0.35),
                  ),
                ),
                child: Icon(
                  isRead
                      ? Icons.notifications_none_rounded
                      : Icons.notifications_active_rounded,
                  color: isRead
                      ? AppColors.mutedText
                      : AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // ═══ المحتوى ═══
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 14,
                              fontWeight: isRead
                                  ? FontWeight.w600
                                  : FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (!isRead) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.gold,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      body,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 13,
                        height: 1.6,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDateTime(createdAt),
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 11,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(dynamic value) {
    if (value == null) return '';
    try {
      final date = DateTime.parse(value.toString()).toLocal();
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return 'الآن';
      if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
      if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
      if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';

      final y = date.year;
      final m = date.month.toString().padLeft(2, '0');
      final d = date.day.toString().padLeft(2, '0');
      return '$y/$m/$d';
    } catch (_) {
      return value.toString();
    }
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: BrandCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.errorLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 38,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'فشل تحميل الإشعارات',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              BrandButton(
                label: 'إعادة المحاولة',
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _loadNotifications,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.4),
                ),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'لا توجد إشعارات',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'ستظهر هنا التحديثات المهمة عن طلباتك وحسابك.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}