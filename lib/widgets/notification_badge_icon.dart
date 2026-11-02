// lib/widgets/notification_badge_icon.dart
// ============================================================
// NotificationBadgeIcon — أيقونة الإشعارات مع Badge
// ============================================================

import 'dart:async';

import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../screens/notifications_screen.dart';
import '../services/api_service.dart';

class NotificationBadgeIcon extends StatefulWidget {
  const NotificationBadgeIcon({Key? key}) : super(key: key);

  @override
  State<NotificationBadgeIcon> createState() =>
      _NotificationBadgeIconState();
}

class _NotificationBadgeIconState extends State<NotificationBadgeIcon> {
  int _unreadCount = 0;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadCount();

    // Polling كل 60 ثانية
    _pollTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _loadCount(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCount() async {
    try {
      final count = await ApiService.getUnreadNotificationsCount();
      if (mounted) {
        setState(() => _unreadCount = count);
      }
    } catch (_) {
      // نتجاهل
    }
  }

  Future<void> _openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NotificationsScreen(),
      ),
    );

    // تحديث العداد بعد العودة
    if (mounted) _loadCount();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openNotifications,
        borderRadius: BorderRadius.circular(19),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Center(
                child: Icon(
                  Icons.notifications_outlined,
                  size: 19,
                  color: AppColors.primary,
                ),
              ),
              if (_unreadCount > 0)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.surface,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _unreadCount > 9 ? '9+' : '$_unreadCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}