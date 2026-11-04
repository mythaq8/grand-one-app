// lib/screens/reset_password_screen.dart
// ============================================================
// ResetPasswordScreen — استعادة كلمة المرور عبر البريد
// ============================================================

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_colors.dart';
import '../widgets/brand_decorations.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _sent = false;

  static final RegExp _emailRegex = RegExp(
    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
  );

  // ============================================================
  // Lifecycle
  // ============================================================

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // ============================================================
  // ترجمة أخطاء Supabase Auth
  // ============================================================

  String _translateAuthError(String message) {
    final lower = message.toLowerCase();

    if (lower.contains('user not found') ||
        lower.contains('email not found')) {
      // ⚠️ لا نكشف وجود البريد أمنياً — نفس رسالة النجاح
      return 'إذا كان البريد مسجلاً، ستصلك رسالة الاستعادة قريباً.';
    }

    if (lower.contains('rate limit') ||
        lower.contains('too many') ||
        lower.contains('for security purposes')) {
      return 'تم تجاوز عدد المحاولات. يرجى الانتظار قليلاً.';
    }

    if (lower.contains('network') ||
        lower.contains('timeout') ||
        lower.contains('connection') ||
        lower.contains('failed host lookup')) {
      return 'تعذر الاتصال بالإنترنت. تحقق من اتصالك.';
    }

    if (lower.contains('invalid email') ||
        lower.contains('unable to validate email')) {
      return 'صيغة البريد الإلكتروني غير صحيحة.';
    }

    if (lower.contains('signups not allowed')) {
      return 'استعادة كلمة المرور معطلة حالياً. يرجى التواصل مع الإدارة.';
    }

    return 'تعذر إرسال رابط الاستعادة. حاول مرة أخرى.';
  }

  // ============================================================
  // إرسال رابط الاستعادة
  // ============================================================

  Future<void> _sendResetLink() async {
    if (!mounted) return;
    if (_isLoading) return;

    final email = _emailController.text.trim().toLowerCase();

    if (email.isEmpty) {
      _showError('الرجاء إدخال البريد الإلكتروني');
      return;
    }

    if (!_emailRegex.hasMatch(email)) {
      _showError('صيغة البريد الإلكتروني غير صحيحة');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.auth
          .resetPasswordForEmail(email);

      if (!mounted) return;

      setState(() {
        _sent = true;
        _isLoading = false;
      });
    } on AuthException catch (e) {
      debugPrint('🔴 Reset password auth error: ${e.message}');

      if (!mounted) return;

      setState(() => _isLoading = false);

      _showError(_translateAuthError(e.message));
    } catch (e, stackTrace) {
      debugPrint('🔴 Reset password error: $e');
      debugPrint('$stackTrace');

      if (!mounted) return;

      setState(() => _isLoading = false);

      _showError('تعذر إرسال رابط الاستعادة. حاول مرة أخرى.');
    }
  }

  // ============================================================
  // رسالة خطأ موحّدة
  // ============================================================

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
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
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return BrandScaffold(
      appBar: const BrandAppBar(
        title: 'استعادة كلمة المرور',
      ),
      body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: _sent
                  ? _buildSuccessCard()
                  : _buildResetCard(),
            ),
          ),
        ),
      
    );
  }

  // ============================================================
  // نموذج الاستعادة
  // ============================================================

  Widget _buildResetCard() {
    return BrandCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeaderIcon(),
          const SizedBox(height: 22),

          const Text(
            'نسيت كلمة المرور؟',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            'أدخل بريدك الإلكتروني وسنرسل لك رابطًا لإعادة تعيين كلمة المرور.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.7,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 28),

          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            enableSuggestions: false,
            onSubmitted: (_) {
              if (!_isLoading) _sendResetLink();
            },
            decoration: InputDecoration(
              labelText: 'البريد الإلكتروني',
              hintText: 'أدخل بريدك الإلكتروني',
              prefixIcon: const Icon(
                Icons.email_outlined,
                color: AppColors.primary,
              ),
              filled: true,
              fillColor: AppColors.surfaceGreen,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          const SizedBox(height: 24),

          BrandButton(
            label: 'إرسال رابط الاستعادة',
            icon: const Icon(Icons.send_rounded),
            onPressed: _sendResetLink,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // بطاقة النجاح
  // ============================================================

  Widget _buildSuccessCard() {
    return BrandCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 82,
              height: 82,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.successLight,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.mark_email_read_outlined,
                size: 42,
                color: AppColors.success,
              ),
            ),
          ),

          const SizedBox(height: 22),

          const Text(
            'تم إرسال رابط الاستعادة',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            'تحقق من بريدك الإلكتروني واتبع التعليمات الموجودة في الرسالة لإعادة تعيين كلمة المرور.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.8,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 22),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.goldSoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.goldLight,
              ),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.goldDark,
                  size: 22,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'إذا لم تجد الرسالة، تحقق من مجلد الرسائل غير المرغوب فيها.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: AppColors.textOnGold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ═══ زر العودة ═══
          BrandButton(
            label: 'العودة لتسجيل الدخول',
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textOnPrimary,
              size: 20,
            ),
            color: AppColors.goldDark,
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // أيقونة الرأس
  // ============================================================

  Widget _buildHeaderIcon() {
    return Center(
      child: Container(
        width: 82,
        height: 82,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.16),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: const Icon(
          Icons.lock_reset_rounded,
          size: 42,
          color: AppColors.textOnPrimary,
        ),
      ),
    );
  }
}