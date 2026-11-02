// lib/ui/shared/logout_action.dart
// ============================================================
// تسجيل الخروج — إجراء واحد مشترك
// ------------------------------------------------------------
// ملاحظة مهمة: توجد الآن خمس نسخ من تسجيل الخروج داخل
// home_screen و services_screen و settings_screen و
// exploration_screen و waiting_screen، كلها تفعل الشيء نفسه
// (NotificationsService.logout ثم SessionService.clearSession
// ثم الانتقال إلى /intro).
//
// لم أُعدّل تلك النسخ في هذه المرحلة (تغيير غير مطلوب بلا
// موافقة)، لكن الشاشات الجديدة تستعمل هذا الملف بدل إضافة
// نسخة سادسة. توحيد النسخ القديمة خطوة لاحقة منفصلة.
// ============================================================

import 'package:flutter/material.dart';

import '../../services/notifications_service.dart';
import '../../services/session_service.dart';

/// يطلب تأكيداً ثم يسجّل الخروج ويعود إلى شاشة البداية.
///
/// يعيد true إن تم الخروج فعلاً.
Future<bool> confirmAndLogout(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('تسجيل الخروج'),
      content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('إلغاء'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('خروج'),
        ),
      ],
    ),
  );

  if (confirmed != true) return false;
  if (!context.mounted) return false;

  try {
    // افصل إشعارات الجهاز قبل مسح الجلسة (تحتاج مستخدماً حالياً)
    try {
      await NotificationsService.logout();
    } catch (_) {
      // نكمل حتى لو فشل فصل الإشعارات
    }
    await SessionService.clearSession();
  } catch (e) {
    debugPrint('LOGOUT ERROR: $e');
  }

  if (!context.mounted) return true;

  Navigator.pushNamedAndRemoveUntil(
    context,
    '/intro',
    (route) => false,
  );
  return true;
}
