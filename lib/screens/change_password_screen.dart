// lib/screens/change_password_screen.dart
// ============================================================
// ChangePasswordScreen — تغيير كلمة المرور
// ============================================================

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/api_service.dart';

import '../app_colors.dart';
import '../utils/error_handler.dart';
import '../widgets/islamic_decorations.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  State<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState
    extends State<ChangePasswordScreen> {
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _isLoading = false;

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  // ============================================================
  // Lifecycle
  // ============================================================

  @override
  void dispose() {
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  // ============================================================
  // ترجمة أخطاء Supabase Auth
  // ============================================================

  String _translateAuthError(String message) {
    final lower = message.toLowerCase();

    if (lower.contains('new password should be different') ||
        lower.contains('same as') ||
        lower.contains('different from')) {
      return 'كلمة المرور الجديدة يجب أن تختلف عن الحالية.';
    }

    if (lower.contains('password should be at least') ||
        lower.contains('password is too short')) {
      return 'كلمة المرور قصيرة جداً.';
    }

    if (lower.contains('session') ||
        lower.contains('unauthorized') ||
        lower.contains('not authenticated') ||
        lower.contains('jwt')) {
      return 'انتهت جلسة الدخول. يرجى تسجيل الدخول مجدداً.';
    }

    if (lower.contains('rate limit') ||
        lower.contains('too many requests')) {
      return 'محاولات كثيرة. يرجى الانتظار قليلاً.';
    }

    if (lower.contains('network') ||
        lower.contains('timeout') ||
        lower.contains('connection') ||
        lower.contains('failed host lookup')) {
      return 'تعذر الاتصال بالإنترنت. تحقق من اتصالك.';
    }

    if (lower.contains('weak password') ||
        lower.contains('password is too weak')) {
      return 'كلمة المرور ضعيفة. اختر كلمة أقوى.';
    }

    return 'تعذر تغيير كلمة المرور. حاول مرة أخرى.';
  }

  // ============================================================
  // سجل التدقيق
  // ============================================================

  Future<void> _logAudit({
    required String action,
    required bool success,
    required String details,
  }) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    await ApiService.logAuthEvent(
      kind: 'audit',
      identifier: userId ?? 'unknown',
      success: success,
      action: action,
      details: details,
    );
  }

  // ============================================================
  // تغيير كلمة المرور
  // ============================================================

  Future<void> _changePassword() async {
    final newPassword = _newPassword.text.trim();
    final confirmPassword = _confirmPassword.text.trim();

    // ═══ فحص الحقول الفارغة ═══
    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      ErrorHandler.showWarning(
        context,
        'الرجاء إدخال كلمة المرور وتأكيدها',
      );
      return;
    }

    // ═══ فحص الطول ═══
    if (newPassword.length < 6) {
      ErrorHandler.showWarning(
        context,
        'يجب أن تتكون كلمة المرور من 6 أحرف على الأقل',
      );
      return;
    }

    // ═══ فحص التطابق ═══
    if (newPassword != confirmPassword) {
      ErrorHandler.showWarning(
        context,
        'كلمتا المرور غير متطابقتين',
      );
      return;
    }

    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      // ═══ تسجيل النجاح ═══
      await _logAudit(
        action: 'change_password',
        success: true,
        details: 'Password changed successfully',
      );

      if (!mounted) return;

      ErrorHandler.showSuccess(
        context,
        'تم تغيير كلمة المرور بنجاح',
      );

      // ═══ تأخير قبل الرجوع (يسمح للمستخدم برؤية الرسالة) ═══
      await Future.delayed(
        const Duration(milliseconds: 800),
      );

      if (!mounted) return;

      Navigator.pop(context);
    } on AuthException catch (e) {
      // ═══ تسجيل الفشل ═══
      await _logAudit(
        action: 'change_password',
        success: false,
        details: 'Auth error: ${e.message}',
      );

      debugPrint('🔴 Change password auth error: ${e.message}');

      if (!mounted) return;

      ErrorHandler.showError(
        context,
        null,
        customMessage: _translateAuthError(e.message),
      );
    } catch (e) {
      // ═══ تسجيل الفشل ═══
      await _logAudit(
        action: 'change_password',
        success: false,
        details: 'Generic error: $e',
      );

      debugPrint('🔴 Change password error: $e');

      if (!mounted) return;

      ErrorHandler.showError(
        context,
        e,
        customMessage: 'تعذر تغيير كلمة المرور. حاول مرة أخرى.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // الواجهة
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return IslamicScaffold(
      appBar: const IslamicAppBar(
        title: 'تغيير كلمة المرور',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
        child: Column(
          children: [
            // --------------------------------------------------
            // العنوان
            // --------------------------------------------------
            IslamicCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.gold
                            .withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      size: 36,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'تغيير كلمة المرور',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'اختر كلمة مرور جديدة لحماية حسابك',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // --------------------------------------------------
            // نموذج كلمة المرور
            // --------------------------------------------------
            IslamicCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionTitle(),

                  const SizedBox(height: 16),

                  // ─── كلمة المرور الجديدة ───
                  TextField(
                    controller: _newPassword,
                    obscureText: _obscureNewPassword,
                    textDirection: TextDirection.ltr,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [
                      AutofillHints.newPassword,
                    ],
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور الجديدة',
                      hintText: 'أدخل كلمة المرور الجديدة',
                      prefixIcon: const Icon(
                        Icons.lock_outline_rounded,
                        color: AppColors.primary,
                      ),
                      suffixIcon: IconButton(
                        tooltip: _obscureNewPassword
                            ? 'إظهار كلمة المرور'
                            : 'إخفاء كلمة المرور',
                        icon: Icon(
                          _obscureNewPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.mutedText,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureNewPassword =
                                !_obscureNewPassword;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      border: _inputBorder(),
                      enabledBorder: _inputBorder(),
                      focusedBorder: _focusedBorder(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ─── تأكيد كلمة المرور ───
                  TextField(
                    controller: _confirmPassword,
                    obscureText: _obscureConfirmPassword,
                    textDirection: TextDirection.ltr,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [
                      AutofillHints.newPassword,
                    ],
                    enableSuggestions: false,
                    autocorrect: false,
                    onSubmitted: (_) {
                      if (!_isLoading) _changePassword();
                    },
                    decoration: InputDecoration(
                      labelText: 'تأكيد كلمة المرور',
                      hintText: 'أعد إدخال كلمة المرور',
                      prefixIcon: const Icon(
                        Icons.lock_rounded,
                        color: AppColors.primary,
                      ),
                      suffixIcon: IconButton(
                        tooltip: _obscureConfirmPassword
                            ? 'إظهار كلمة المرور'
                            : 'إخفاء كلمة المرور',
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.mutedText,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword =
                                !_obscureConfirmPassword;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      border: _inputBorder(),
                      enabledBorder: _inputBorder(),
                      focusedBorder: _focusedBorder(),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ─── ملاحظة ───
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: AppColors.infoLight,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                        color: AppColors.info
                            .withValues(alpha: 0.18),
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: AppColors.info,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'يجب أن تتكون كلمة المرور من 6 أحرف أو أرقام على الأقل.',
                            style: TextStyle(
                              fontSize: 10,
                              height: 1.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ─── زر التغيير ───
                  IslamicButton(
                    label: 'تغيير كلمة المرور',
                    onPressed: _isLoading
                        ? null
                        : _changePassword,
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // عنوان القسم
  // ============================================================

  Widget _buildSectionTitle() {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.goldSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.password_rounded,
            size: 22,
            color: AppColors.goldDark,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'بيانات كلمة المرور',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'أدخل كلمة المرور الجديدة',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // تنسيق الحدود
  // ============================================================

  OutlineInputBorder _inputBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: const BorderSide(
        color: AppColors.border,
      ),
    );
  }

  OutlineInputBorder _focusedBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: const BorderSide(
        color: AppColors.primary,
        width: 1.5,
      ),
    );
  }
}