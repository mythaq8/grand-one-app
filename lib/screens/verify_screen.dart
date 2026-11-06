// lib/screens/verify_screen.dart
// ============================================================
// VerifyScreen — التحقق من OTP (هاتف / بريد)
// ============================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/brand_decorations.dart';
import '../app_colors.dart';
import '../services/device_gate.dart';
import 'services_user_profile_setup_screen.dart';

class VerifyScreen extends StatefulWidget {
  final String email;
  final String identifier;
  final bool isPhoneVerification;

  /// نوع الحساب
  final String accountType;


  const VerifyScreen({
    Key? key,
    required this.email,
    required this.identifier,
    this.isPhoneVerification = false,
    required this.accountType,
  }) : super(key: key);

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  final _otpController = TextEditingController();
  final _client = Supabase.instance.client;

  bool _isLoading = false;
  bool _isResending = false;

  int _remainingTime = 60;
  Timer? _timer;

  String? _error;

  // ============================================================
  // Lifecycle
  // ============================================================

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  // ============================================================
  // العداد
  // ============================================================

  void _startCountdown() {
    _timer?.cancel();

    if (!mounted) return;

    setState(() {
      _remainingTime = 60;
    });

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (_remainingTime > 0) {
          setState(() {
            _remainingTime--;
          });
        } else {
          timer.cancel();
        }
      },
    );
  }

  // ============================================================
  // إنشاء Profile
  // ============================================================

  Future<void> _createProfile({
    required String userId,
    required String role,
    String? phone,
  }) async {
    try {
      final existing = await _client
          .from('profiles')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      if (existing != null) {
        debugPrint('✅ Profile already exists for: $userId');
        return;
      }

      await _client.from('profiles').insert({
        'id': userId,
        'role': role,
        'is_active': true,
        'phone': phone,
      });

      debugPrint('✅ Profile created for: $userId (role: $role)');
    } catch (e) {
      debugPrint('🔴 Profile creation failed: $e');
      rethrow;
    }
  }

  // ============================================================
  // التحقق من نوع الحساب
  // ============================================================

  Future<void> _continueAfterVerification(User user) async {
    final phone = user.phone ??
        (widget.isPhoneVerification ? widget.identifier : null);

    // تطبيق الخدمات يقبل حسابات الخدمات فقط.
    if (widget.accountType != 'services') {
      throw Exception('هذا التطبيق لحسابات الخدمات فقط.');
    }

    await _createProfile(
      userId: user.id,
      role: 'services_only',
      phone: phone,
    );

    final gate = await DeviceGate.ensureRegistered();
    if (!gate.isAllowed) {
      try {
        await _client.auth.signOut();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = gate.message;
      });
      return;
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const ServicesUserProfileSetupScreen(),
      ),
    );
  }

  // ============================================================
  // التحقق من OTP
  // ============================================================

  Future<void> _verifyOtp() async {
    if (!mounted) return;
    if (_isLoading) return;

    final otp = _otpController.text.trim();

    if (otp.length != 6) {
      setState(() {
        _error = 'يرجى إدخال رمز التحقق المكون من 6 أرقام';
      });
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      AuthResponse response;

      // ═══ الهاتف ═══
      if (widget.isPhoneVerification) {
        response = await _client.auth.verifyOTP(
          phone: widget.identifier,
          token: otp,
          type: OtpType.sms,
        );
      }
      // ═══ البريد ═══
      else {
        response = await _client.auth.verifyOTP(
          email: widget.email,
          token: otp,
          type: OtpType.signup,
        );
      }

      final user = response.user;
      final session = response.session;

      if (user == null || session == null) {
        throw const AuthException(
          'لم يتم إنشاء جلسة تسجيل الدخول بعد التحقق',
        );
      }

      if (!mounted) return;

      await _continueAfterVerification(user);
    }
    // ═══ خطأ Auth ═══
    on AuthException catch (e) {
      debugPrint('🔴 Verify OTP auth error: ${e.message}');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = _translateAuthError(e.message);
      });
    }
    // ═══ خطأ عام ═══
    catch (e, stackTrace) {
      debugPrint('🔴 Verify OTP error: $e');
      debugPrint('$stackTrace');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = 'حدث خطأ أثناء التحقق. يرجى المحاولة لاحقاً.';
      });
    }
  }

  // ============================================================
  // إعادة إرسال OTP
  // ============================================================

  Future<void> _resendOtp() async {
    if (!mounted) return;
    if (_remainingTime > 0 || _isResending) {
      return;
    }

    setState(() {
      _isResending = true;
      _error = null;
    });

    try {
      // ═══ الهاتف ═══
      if (widget.isPhoneVerification) {
        await _client.auth.resend(
          phone: widget.identifier,
          type: OtpType.sms,
        );
      }
      // ═══ البريد ═══
      else {
        await _client.auth.resend(
          email: widget.email,
          type: OtpType.signup,
        );
      }

      if (!mounted) return;

      _startCountdown();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: const Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: Colors.white,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'تم إرسال رمز تحقق جديد',
                ),
              ),
            ],
          ),
        ),
      );
    }
    // ═══ خطأ Auth ═══
    on AuthException catch (e) {
      debugPrint('🔴 Resend OTP auth error: ${e.message}');

      if (!mounted) return;

      setState(() {
        _error = _translateAuthError(e.message);
      });
    }
    // ═══ خطأ عام ═══
    catch (e, stackTrace) {
      debugPrint('🔴 Resend OTP error: $e');
      debugPrint('$stackTrace');

      if (!mounted) return;

      setState(() {
        _error = 'تعذر إعادة إرسال الرمز. حاول مرة أخرى.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  // ============================================================
  // ترجمة أخطاء Auth
  // ============================================================

  String _translateAuthError(String message) {
    final lower = message.toLowerCase();

    if (lower.contains('expired')) {
      return 'انتهت صلاحية رمز التحقق. اطلب رمزاً جديداً.';
    }

    if (lower.contains('invalid') ||
        lower.contains('incorrect') ||
        lower.contains('wrong')) {
      return 'رمز التحقق غير صحيح.';
    }

    if (lower.contains('too many') ||
        lower.contains('rate limit') ||
        lower.contains('for security purposes')) {
      return 'تم تجاوز عدد المحاولات. يرجى الانتظار قليلاً.';
    }

    if (lower.contains('phone') && lower.contains('invalid')) {
      return 'رقم الهاتف غير صحيح.';
    }

    if (lower.contains('email') && lower.contains('invalid')) {
      return 'صيغة البريد غير صحيحة.';
    }

    if (lower.contains('network') ||
        lower.contains('timeout') ||
        lower.contains('connection') ||
        lower.contains('failed host lookup')) {
      return 'تعذر الاتصال بالإنترنت. تحقق من اتصالك.';
    }

    if (lower.contains('token') && lower.contains('invalid')) {
      return 'الرمز غير صالح. اطلب رمزاً جديداً.';
    }

    // ═══ رسالة عامة عربية ═══
    return 'حدث خطأ أثناء التحقق. حاول مرة أخرى.';
  }

  // ============================================================
  // عناوين الشاشة
  // ============================================================

  String _getTitle() {
    if (widget.accountType == 'services') {
      return 'تحقق من الحساب';
    }

    return 'تحقق من الحساب';
  }

  String _getAccountLabel() {
    if (widget.accountType == 'services') {
      return 'حساب الخدمات';
    }

    return 'حساب GRAND ONE';
  }

  String _getVerificationMethod() {
    return widget.isPhoneVerification
        ? 'رقم الهاتف'
        : 'البريد الإلكتروني';
  }

  // ============================================================
  // بطاقة معلومات الإرسال
  // ============================================================

  Widget _buildDestinationCard(bool isPhone) {
    final destination = isPhone ? widget.identifier : widget.email;

    return BrandCard(
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primarySoft,
              border: Border.all(
                color: AppColors.goldLight,
                width: 1.5,
              ),
            ),
            child: Icon(
              isPhone
                  ? Icons.phone_android_rounded
                  : Icons.mark_email_read_rounded,
              size: 30,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'تم إرسال رمز التحقق',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'أرسلنا رمزاً مكوناً من 6 أرقام إلى ${_getVerificationMethod()}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceGreen,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.borderLight,
              ),
            ),
            child: Text(
              destination,
              textAlign: TextAlign.center,
              textDirection: isPhone
                  ? TextDirection.ltr
                  : TextDirection.rtl,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // حقل OTP
  // ============================================================

  Widget _buildOtpField() {
    return BrandCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.goldSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  size: 20,
                  color: AppColors.goldDark,
                ),
              ),

              const SizedBox(width: 10),

              const Text(
                'أدخل رمز التحقق',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            textInputAction: TextInputAction.done,
            autofocus: true,
            onSubmitted: (_) {
              if (!_isLoading) _verifyOtp();
            },
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.bold,
              letterSpacing: 12,
              color: AppColors.primary,
            ),
            decoration: InputDecoration(
              hintText: '••••••',
              hintStyle: TextStyle(
                color: AppColors.mutedText.withValues(alpha: 0.65),
                letterSpacing: 10,
              ),
              errorText: _error,
              counterText: '',
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 18,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.border,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.border,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.error,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.error,
                  width: 2,
                ),
              ),
            ),
            onChanged: (_) {
              if (_error != null) {
                setState(() {
                  _error = null;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // العداد وإعادة الإرسال
  // ============================================================

  Widget _buildResendSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          if (_remainingTime > 0) ...[
            const Icon(
              Icons.schedule_rounded,
              size: 21,
              color: AppColors.mutedText,
            ),

            const SizedBox(height: 8),

            Text(
              'يمكنك طلب رمز جديد بعد',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              '$_remainingTime ثانية',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ] else ...[
            const Icon(
              Icons.refresh_rounded,
              size: 22,
              color: AppColors.primary,
            ),

            const SizedBox(height: 6),

            TextButton(
              onPressed: _isResending ? null : _resendOtp,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
              ),
              child: _isResending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'إعادة إرسال رمز التحقق',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final isPhone = widget.isPhoneVerification;

    return BrandScaffold(
      appBar: BrandAppBar(
        title: _getTitle(),
      ),
      body: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth > 700
                ? 620.0
                : constraints.maxWidth;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                20,
                24,
                20,
                32,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    children: [
                      Container(
                        width: 82,
                        height: 82,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.primaryGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary
                                  .withValues(alpha: 0.18),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.verified_user_outlined,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 18),

                      Text(
                        _getAccountLabel(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.goldDark,
                        ),
                      ),

                      const SizedBox(height: 6),

                      const Text(
                        'تأكيد الهوية',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'خطوة بسيطة لإتمام إنشاء حسابك في GRAND ONE',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: AppColors.textSecondary,
                        ),
                      ),

                      const SizedBox(height: 24),

                      _buildDestinationCard(isPhone),

                      const SizedBox(height: 16),

                      _buildOtpField(),

                      const SizedBox(height: 16),

                      BrandButton(
                        label: 'تأكيد الرمز',
                        onPressed: _isLoading ? null : _verifyOtp,
                        isLoading: _isLoading,
                      ),

                      const SizedBox(height: 16),

                      _buildResendSection(),

                      const SizedBox(height: 22),

                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.borderLight,
                          ),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.shield_outlined,
                              size: 21,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'رمز التحقق خاص بك، ولا تشاركه مع أي شخص. '
                                'نحرص في GRAND ONE على حماية بياناتك وخصوصيتك.',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.6,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'GRAND ONE • كل ما تحتاجه، في وجهة واحدة',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      
    );
  }
}
