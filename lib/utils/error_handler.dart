// lib/utils/error_handler.dart
// ============================================================
// ErrorHandler — SnackBars موحّدة وترجمة أخطاء شاملة
// ============================================================

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_colors.dart';
import '../services/api_exceptions.dart';

class ErrorHandler {
  // ============================================================
  // Public API — عرض الرسائل
  // ============================================================

  /// عرض رسالة خطأ (مع ترجمة تلقائية)
  static void showError(
    BuildContext context,
    dynamic error, {
    String? customMessage,
  }) {
    if (!context.mounted) return;

    final message = customMessage ?? getErrorMessage(error);

    _showSnackBar(
      context,
      message: message,
      backgroundColor: AppColors.error,
      duration: const Duration(seconds: 4),
    );
  }

  /// عرض رسالة نجاح
  static void showSuccess(
    BuildContext context,
    String message,
  ) {
    if (!context.mounted) return;

    _showSnackBar(
      context,
      message: '✅ $message',
      backgroundColor: AppColors.success,
      duration: const Duration(seconds: 3),
    );
  }

  /// عرض رسالة تحذير
  static void showWarning(
    BuildContext context,
    String message,
  ) {
    if (!context.mounted) return;

    _showSnackBar(
      context,
      message: '⚠️ $message',
      backgroundColor: AppColors.warning,
      duration: const Duration(seconds: 3),
    );
  }

  /// عرض رسالة معلومات
  static void showInfo(
    BuildContext context,
    String message,
  ) {
    if (!context.mounted) return;

    _showSnackBar(
      context,
      message: 'ℹ️ $message',
      backgroundColor: AppColors.info,
      duration: const Duration(seconds: 3),
    );
  }

  // ============================================================
  // SnackBar موحّد
  // ============================================================

  static void _showSnackBar(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required Duration duration,
    SnackBarAction? action,
  }) {
    // ═══ ابحث عن ScaffoldMessenger بأمان ═══
    final messenger = ScaffoldMessenger.maybeOf(context);

    if (messenger == null) {
      debugPrint('⚠️ ErrorHandler: no ScaffoldMessenger found');
      return;
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: backgroundColor,
          duration: duration,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          action: action,
        ),
      );
  }

  // ============================================================
  // استخراج رسالة من الخطأ (Dispatcher)
  // ============================================================

  static String getErrorMessage(dynamic error) {
    // ═══ 0. نص جاهز للعرض (عربي أو رسالة واضحة من الشاشة) ═══
    if (error is String) {
      final text = error.trim();
      if (text.isNotEmpty) return text;
    }

    // ═══ 1. ApiException (Deno) ═══
    if (error is ApiException) {
      return error.userMessage;
    }

    // ═══ 2. Supabase AuthException ═══
    if (error is AuthException) {
      return _translateAuthError(error.message);
    }

    // ═══ 3. Supabase PostgrestException ═══
    if (error is PostgrestException) {
      return _translatePostgrestError(error);
    }

    // ═══ 4. رسائل معروفة (fallback) ═══
    return _translateGenericError(error);
  }

  // ============================================================
  // ترجمة AuthException
  // ============================================================

  static String _translateAuthError(String message) {
    final lower = message.toLowerCase();

    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid email or password')) {
      return 'البريد أو كلمة المرور غير صحيحة.';
    }

    if (lower.contains('email not confirmed') ||
        lower.contains('email_not_confirmed')) {
      return 'يرجى تأكيد بريدك الإلكتروني أولاً.';
    }

    if (lower.contains('phone not confirmed') ||
        lower.contains('phone_not_confirmed')) {
      return 'يرجى تأكيد رقم هاتفك أولاً.';
    }

    if (lower.contains('session') ||
        lower.contains('jwt') ||
        lower.contains('expired')) {
      return 'انتهت جلسة الدخول. يرجى تسجيل الدخول مجدداً.';
    }

    if (lower.contains('rate limit') ||
        lower.contains('too many') ||
        lower.contains('for security purposes')) {
      return 'محاولات كثيرة. يرجى الانتظار قليلاً.';
    }

    if (lower.contains('user already') ||
        lower.contains('already registered') ||
        lower.contains('already exists')) {
      return 'هذا الحساب موجود مسبقاً.';
    }

    if (lower.contains('signups not allowed')) {
      return 'التسجيل معطل حالياً. يرجى التواصل مع الإدارة.';
    }

    if (lower.contains('invalid email') ||
        lower.contains('unable to validate email')) {
      return 'صيغة البريد الإلكتروني غير صحيحة.';
    }

    if (lower.contains('invalid phone')) {
      return 'رقم الهاتف غير صحيح.';
    }

    if (lower.contains('network') ||
        lower.contains('timeout') ||
        lower.contains('connection')) {
      return 'تعذر الاتصال بالإنترنت.';
    }

    return 'خطأ في المصادقة.';
  }

  // ============================================================
  // ترجمة PostgrestException
  // ============================================================

  static String _translatePostgrestError(PostgrestException e) {
    final code = e.code ?? '';
    final msg = e.message.toLowerCase();

    // ═══ RLS / Permissions ═══
    if (code == '42501' || msg.contains('permission denied')) {
      return 'ليس لديك صلاحية لهذا الإجراء.';
    }

    // ═══ Unique violation ═══
    if (code == '23505' ||
        msg.contains('duplicate') ||
        msg.contains('unique constraint')) {
      return 'هذا العنصر موجود مسبقاً.';
    }

    // ═══ Foreign key violation ═══
    if (code == '23503' || msg.contains('foreign key')) {
      return 'البيانات المرتبطة غير موجودة.';
    }

    // ═══ Not null violation ═══
    if (code == '23502' ||
        msg.contains('not-null') ||
        msg.contains('null value')) {
      return 'يوجد حقل مطلوب فارغ.';
    }

    // ═══ Check violation ═══
    if (code == '23514' || msg.contains('check constraint')) {
      return 'البيانات لا تطابق الشروط المطلوبة.';
    }

    // ═══ RAISE EXCEPTION من RPC (P0001) ═══
    if (code == 'P0001') {
      // رسائل مخصصة من RPC — نرجعها كما هي
      // (لأنها مكتوبة بالعربية في الغالب)
      final original = e.message.trim();
      return original.isNotEmpty ? original : 'فشلت العملية.';
    }

    // ═══ Network ═══
    if (msg.contains('network') || msg.contains('timeout')) {
      return 'تعذر الاتصال بالخادم.';
    }

    // ═══ رسالة عامة ═══
    return 'خطأ في قاعدة البيانات.';
  }

  // ============================================================
  // ترجمة الأخطاء العامة (fallback)
  // ============================================================

  static String _translateGenericError(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('network') ||
        errorStr.contains('socket') ||
        errorStr.contains('failed host lookup') ||
        errorStr.contains('failed to fetch') ||
        errorStr.contains('clientexception') ||
        errorStr.contains('xmlhttprequest')) {
      return 'تعذر الاتصال بالإنترنت.';
    }

    if (errorStr.contains('timeout')) {
      return 'انتهت مهلة الاتصال.';
    }

    // ═══ دقيق: unauthorized / unauthenticated فقط ═══
    if (errorStr.contains('unauthorized') ||
        errorStr.contains('unauthenticated') ||
        errorStr.contains('authentication required')) {
      return 'خطأ في المصادقة.';
    }

    if (errorStr.contains('duplicate') ||
        errorStr.contains('already exists')) {
      return 'هذا العنصر موجود مسبقاً.';
    }

    if (errorStr.contains('permission denied') ||
        errorStr.contains('forbidden')) {
      return 'ليس لديك صلاحية.';
    }

    return 'حدث خطأ غير متوقع.';
  }
}