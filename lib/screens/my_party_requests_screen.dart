// lib/screens/my_party_requests_screen.dart
// ============================================================
// MyPartyRequestsScreen — طلبات المستخدم
// ============================================================

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../services/api_exceptions.dart';
import '../services/api_service.dart';
import '../utils/error_handler.dart';
import '../widgets/brand_decorations.dart';
import 'party_request_screen.dart';

class MyPartyRequestsScreen extends StatefulWidget {
  const MyPartyRequestsScreen({Key? key, this.embedded = false})
      : super(key: key);

  /// عند العرض داخل تبويب «طلباتي» لا نعيد شريط عنوان.
  final bool embedded;

  @override
  State<MyPartyRequestsScreen> createState() =>
      _MyPartyRequestsScreenState();
}

class _MyPartyRequestsScreenState extends State<MyPartyRequestsScreen> {
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService.getMyPartyRequests(limit: 50);
      final list = _extractList(response, 'data');

      if (!mounted) return;

      setState(() {
        _requests = list;
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

  String _getPartyTypeLabel(String? type) {
    switch (type) {
      case 'wedding':
        return 'عرس';
      case 'engagement':
        return 'خطبة';
      case 'birthday':
        return 'عيد ميلاد';
      case 'graduation':
        return 'تخرج';
      case 'other':
        return 'أخرى';
      default:
        return type ?? '';
    }
  }

  String _getStatusLabel(String? status) {
    switch (status) {
      case 'new':
        return 'جديد';
      case 'reviewed':
        return 'تمت المراجعة';
      default:
        return status ?? '';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'new':
        return AppColors.warning;
      case 'reviewed':
        return AppColors.success;
      default:
        return AppColors.mutedText;
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return '';
    try {
      final date = DateTime.parse(value.toString()).toLocal();
      final y = date.year;
      final m = date.month.toString().padLeft(2, '0');
      final d = date.day.toString().padLeft(2, '0');
      final h = date.hour.toString().padLeft(2, '0');
      final min = date.minute.toString().padLeft(2, '0');
      return '$y/$m/$d $h:$min';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: BrandScaffold(
        appBar: widget.embedded
            ? null
            : BrandAppBar(
                title: 'طلبات تنظيم الحفلات',
                actions: [
                  IconButton(
                    tooltip: 'طلب جديد',
                    icon: const Icon(Icons.add_rounded),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PartyRequestScreen(),
                        ),
                      ).then((_) => _load());
                    },
                  ),
                  IconButton(
                    tooltip: 'تحديث',
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: _isLoading ? null : _load,
                  ),
                ],
              ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null) {
      return _buildError();
    }

    if (_requests.isEmpty) {
      return _buildEmpty();
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _requests.length,
        itemBuilder: (context, i) => _buildCard(_requests[i]),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> req) {
    final partyType = req['party_type']?.toString() ?? '';
    final governorate = req['governorate']?.toString() ?? '';
    final status = req['status']?.toString() ?? 'new';
    final createdAt = req['created_at'];
    final budgetMin = req['budget_min'];
    final budgetMax = req['budget_max'];
    final essential = req['essential_categories'] as List?;
    final adminNote = req['admin_note']?.toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BrandCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.celebration_outlined,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getPartyTypeLabel(partyType),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _formatDate(createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),
            const SizedBox(height: 10),
            _infoRow(Icons.location_on_outlined, 'المحافظة', governorate),
            if (budgetMin != null || budgetMax != null)
              _infoRow(
                Icons.attach_money_rounded,
                'الميزانية',
                '${budgetMin ?? "?"} - ${budgetMax ?? "?"} \$',
              ),
            if (essential != null && essential.isNotEmpty)
              _infoRow(
                Icons.category_outlined,
                'الفئات الأساسية',
                '${essential.length} فئة',
              ),
            if (adminNote != null && adminNote.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.infoLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: AppColors.info,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'ملاحظة الإدارة: $adminNote',
                        style: const TextStyle(
                          fontSize: 11.5,
                          height: 1.4,
                          color: AppColors.info,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = _getStatusColor(status);
    final label = _getStatusLabel(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.mutedText),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: BrandCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 38,
                color: AppColors.error,
              ),
              const SizedBox(height: 12),
              const Text(
                'فشل تحميل الطلبات',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              BrandButton(
                label: 'إعادة المحاولة',
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _load,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: AppColors.goldSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.celebration_outlined,
                size: 48,
                color: AppColors.goldDark,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'لا توجد طلبات',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'اطلب تنظيم حفلتك الآن',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PartyRequestScreen(),
                  ),
                ).then((_) => _load());
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('طلب جديد'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}