// lib/screens/auth_screen.dart
// ============================================================
// AuthScreen — شاشة تسجيل الدخول / إنشاء حساب
// ============================================================

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';

import '../widgets/islamic_decorations.dart';
import '../widgets/ux_helpers.dart';
import '../app_colors.dart';
import '../ui_copy.dart';
import '../services/notifications_service.dart';
import '../services/api_service.dart';
import '../services/device_gate.dart';

import 'verify_screen.dart';
import 'services_user_profile_setup_screen.dart';
import '../ui/shell/app_shell.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _supabase = Supabase.instance.client;

  bool _isLoading = false;
  bool _isLogin = true;
  bool _obscurePassword = true;

  final String _accountType = 'services'; // خدمات فقط — لا زواج

  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

 

  static final RegExp _internalSpacesRegex = RegExp(r'\s+');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  

  

  bool _isValidEmail(String email) {
    return _emailRegex.hasMatch(email);
  }

  String _translateAuthError(String message) {
    final lower = message.toLowerCase();

    if (lower.contains('already registered') ||
        lower.contains('already been registered') ||
        lower.contains('user already exists')) {
      return 'هذا البريد أو الرقم مسجل مسبقاً. الرجاء تسجيل الدخول.';
    }

    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid email or password')) {
      return 'البريد أو كلمة المرور غير صحيحة.';
    }

    if (lower.contains('email_not_confirmed')) {
      return 'الرجاء تأكيد بريدك الإلكتروني أولاً.';
    }

    if (lower.contains('unable to validate email') ||
        lower.contains('invalid email') ||
        lower.contains('invalid format')) {
      return 'صيغة البريد الإلكتروني غير صحيحة.';
    }

    if (lower.contains('phone_not_confirmed')) {
      return 'الرجاء تأكيد رقم هاتفك أولاً.';
    }

    if (lower.contains('invalid phone')) {
      return 'رقم الهاتف غير صحيح.';
    }

    if (lower.contains('password should be at least') ||
        lower.contains('password is too short')) {
      return 'كلمة المرور قصيرة جداً.';
    }

    if (lower.contains('rate limit') ||
        lower.contains('too many requests')) {
      return 'تم تجاوز عدد المحاولات. يرجى الانتظار قليلاً.';
    }

    if (lower.contains('for security purposes')) {
      return 'لأسباب أمنية، يرجى الانتظار قبل إعادة المحاولة.';
    }

    if (lower.contains('signups not allowed')) {
      return 'التسجيل معطل حالياً. يرجى التواصل مع الإدارة.';
    }

    if (lower.contains('database error saving new user')) {
      return 'تعذر إنشاء الحساب. يرجى التواصل مع الإدارة.';
    }

    if (lower.contains('network') ||
        lower.contains('socket') ||
        lower.contains('timeout')) {
      return 'تعذر الاتصال بالإنترنت. تحقق من اتصالك.';
    }

    return 'حدث خطأ أثناء المصادقة. حاول مرة أخرى.';
  }

  Future<void> _logAudit({
    required String identifier,
    required String action,
    required bool success,
    required String details,
  }) async {
    await ApiService.logAuthEvent(
      kind: 'audit',
      identifier: identifier,
      success: success,
      action: action,
      details: details,
    );
  }

  Future<void> _logAttempt(
    String identifier,
    bool success,
  ) async {
    await ApiService.logAuthEvent(
      kind: 'login_attempt',
      identifier: identifier,
      success: success,
    );
  }

  Future<void> _createProfile({
  required String userId,
  required String role,
  String? phone,
}) async {
  try {
    final existing = await _supabase
        .from('profiles')
        .select('id')
        .eq('id', userId)
        .maybeSingle();

    if (existing != null) {
      debugPrint('✅ Profile already exists for: $userId');
      return;
    }

    // ═══ جهّز البيانات — phone فقط إن وُجد ═══
    final Map<String, dynamic> payload = {
      'id': userId,
      'role': role,
      'is_active': true,
    };

    // ═══ لا نُرسل phone إن كان null أو فارغًا ═══
    final phoneClean = phone?.trim() ?? '';
    if (phoneClean.isNotEmpty) {
      payload['phone'] = phoneClean;
    }

    await _supabase.from('profiles').insert(payload);

    debugPrint('✅ Profile created for: $userId (role: $role)');
  } catch (e) {
    debugPrint('❌ Profile creation failed: $e');
    rethrow;
  }
}
bool _validateSignupType() => true;

  void _showMessage(
    String message,
    Color color,
  ) {
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
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          elevation: 4,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  Future<void> _signOutWithMessage(String message) async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint('⚠️ Sign out error: $e');
    }

    if (!mounted) return;
    _showMessage(message, AppColors.error);
  }

  Future<void> _handleLogin({
  required String email,
  required String password,
}) async {
  final response = await _supabase.auth.signInWithPassword(
    email: email,
    password: password,
  );

  final userId = response.user?.id;

  if (userId == null) {
    throw Exception('تعذر الحصول على معرف المستخدم');
  }

  final profile = await _supabase
      .from('profiles')
      .select('id, role, is_banned, is_active, ban_until')
      .eq('id', userId)
      .maybeSingle();

  if (!mounted) return;

  if (profile == null) {
    await _signOutWithMessage(
      'لم يتم العثور على بيانات الحساب. يرجى التواصل مع الإدارة.',
    );
    return;
  }

  if (profile['is_banned'] == true) {
    await _signOutWithMessage(tr('banned'));
    return;
  }

  final banUntilRaw = profile['ban_until'];
  if (banUntilRaw != null && banUntilRaw.toString().isNotEmpty) {
    try {
      final banUntil = DateTime.parse(banUntilRaw.toString());
      if (banUntil.isAfter(DateTime.now())) {
        await _signOutWithMessage(
          'تم إيقاف حسابك مؤقتاً حتى '
          '${banUntil.year}-${banUntil.month.toString().padLeft(2, '0')}-'
          '${banUntil.day.toString().padLeft(2, '0')}. '
          'يرجى التواصل مع الإدارة.',
        );
        return;
      }
    } catch (e) {
      debugPrint('⚠️ ban_until parse error: $e');
    }
  }

  if (profile['is_active'] == false) {
    await _signOutWithMessage('هذا الحساب غير مفعل حالياً.');
    return;
  }

  final role = profile['role']?.toString();

  await _logAudit(
    identifier: email,
    action: 'login',
    success: true,
    details: 'Login success - role: $role',
  );

  await _logAttempt(email, true);

  final gate = await DeviceGate.ensureRegistered();
  if (!gate.isAllowed) {
    await _signOutWithMessage(gate.message);
    return;
  }

  await NotificationsService.registerCurrentUser();

  if (!mounted) return;

  if (role == 'groom' || role == 'bride') {
    await _signOutWithMessage('هذا التطبيق لحسابات الخدمات فقط.');
    return;
  }

  if (role == 'services_only') {
    try {
      final servicesProfile = await _supabase
          .from('services_profiles')
          .select('user_id')
          .eq('user_id', userId)
          .maybeSingle();

      if (!mounted) return;

      if (servicesProfile == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const ServicesUserProfileSetupScreen(),
          ),
        );
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const AppShell(),
        ),
      );
    } catch (e) {
      debugPrint('⚠️ خطأ في فحص ملف الخدمات: $e');
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const ServicesUserProfileSetupScreen(),
        ),
      );
    }
    return;
  }

  await _signOutWithMessage(
    'نوع الحساب غير معروف. يرجى التواصل مع الإدارة.',
  );
}

 Future<void> _submit() async {
  final password = _passwordController.text.trim();

  if (password.length < 6) {
    _showMessage(
      tr('password_short'),
      AppColors.warning,
    );
    return;
  }

  // ═══ البريد إجباري ═══
  final email = _emailController.text
      .trim()
      .toLowerCase()
      .replaceAll(_internalSpacesRegex, '');

  if (email.isEmpty) {
    _showMessage(
      'يرجى إدخال البريد الإلكتروني',
      AppColors.warning,
    );
    return;
  }

  if (!_isValidEmail(email)) {
    _showMessage(
      'يرجى إدخال بريد إلكتروني صحيح (example@domain.com)',
      AppColors.warning,
    );
    return;
  }

  if (!_isLogin && !_validateSignupType()) return;

  setState(() {
    _isLoading = true;
  });

  try {
    if (_isLogin) {
      await _handleLogin(
        email: email,
        password: password,
      );
      return;
    }

    // ═══ التسجيل بالبريد فقط ═══
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    final user = response.user;

    if (user == null) {
      throw Exception('لم يتم إنشاء المستخدم');
    }

    await _logAudit(
      identifier: email,
      action: 'signup',
      success: true,
      details: 'Signup success - accountType: services',
    );

    if (response.session == null) {
      if (!mounted) return;

      _showMessage(
        'تم إرسال رسالة التحقق إلى بريدك الإلكتروني',
        AppColors.success,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyScreen(
            email: email,
            identifier: email,
            isPhoneVerification: false,
            accountType: 'services',
            marriageRole: null,
          ),
        ),
      );
      return;
    }

    await _createProfile(
      userId: user.id,
      role: 'services_only',
      phone: null,
    );

    final gate = await DeviceGate.ensureRegistered();
    if (!gate.isAllowed) {
      await _signOutWithMessage(gate.message);
      return;
    }

    await NotificationsService.registerCurrentUser();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const ServicesUserProfileSetupScreen(),
      ),
    );
  } on AuthException catch (e) {
    await _logAttempt(email, false);
    debugPrint('🔴 Auth error: ${e.message}');

    if (mounted) {
      _showMessage(
        _translateAuthError(e.message),
        AppColors.error,
      );
    }
  } catch (e, stackTrace) {
    await _logAttempt(email, false);
    debugPrint('🔴 Unexpected error: $e');
    debugPrint('Stack: $stackTrace');

    if (mounted) {
      _showMessage(
        'حدث خطأ غير متوقع. يرجى المحاولة لاحقاً.',
        AppColors.error,
      );
    }
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

    

  Widget _buildAccountTypeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
  }) {
    final selected = _accountType == value;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: null,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primarySoft
                : AppColors.surfaceGreen,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.borderLight,
              width: selected ? 1.4 : 0.9,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 23,
                  color: selected
                      ? AppColors.goldLight
                      : AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildCheckCircle(selected),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckCircle(bool selected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 23,
      height: 23,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected
            ? AppColors.primary
            : Colors.transparent,
        border: Border.all(
          color: selected
              ? AppColors.primary
              : AppColors.border,
          width: selected ? 1.5 : 1.2,
        ),
      ),
      child: selected
          ? const Icon(
              Icons.check_rounded,
              size: 15,
              color: Colors.white,
            )
          : null,
    );
  }

  

Widget _buildInputFields() {
  return Column(
    children: [
      // ═══ البريد الإلكتروني (إلزامي) ═══
      TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.email],
        autocorrect: false,
        enableSuggestions: false,
        style: const TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 14,
          color: AppColors.textPrimary,
        ),
        decoration: const InputDecoration(
          labelText: 'البريد الإلكتروني',
          hintText: 'example@email.com',
          prefixIcon: Icon(Icons.email_outlined),
        ),
      ),
      const SizedBox(height: 14),

      // ═══ كلمة المرور ═══
      TextField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        textInputAction: TextInputAction.done,
        autofillHints: _isLogin
            ? const [AutofillHints.password]
            : const [AutofillHints.newPassword],
        onSubmitted: (_) {
          if (!_isLoading) _submit();
        },
        style: const TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 14,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          labelText: 'كلمة المرور',
          hintText: 'أدخل كلمة المرور',
          prefixIcon: const Icon(Icons.lock_outline_rounded),
          suffixIcon: IconButton(
            tooltip: _obscurePassword
                ? 'إظهار كلمة المرور'
                : 'إخفاء كلمة المرور',
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
          ),
        ),
      ),
    ],
  );
}

  Widget _buildSignupSection() {
    return Column(
      children: [
        const SizedBox(height: 24),
        Container(
          height: 1,
          color: AppColors.divider,
        ),
        const SizedBox(height: 20),
        const Align(
          alignment: Alignment.centerRight,
          child: Text(
            'اختر نوع الحساب',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const InfoBanner(
          message: UiCopy.authServicesHint,
          tone: InfoBannerTone.tip,
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: 10),
        _buildAccountTypeCard(
          title: 'حساب خدمات',
          subtitle: 'لتصفّح الخدمات وإرسال الطلبات',
          icon: Icons.business_center_outlined,
          value: 'services',
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const IslamicLogoFrame(
          size: 94,
          showTitle: true,
        ),
        const SizedBox(height: 20),
        Text(
          _isLogin ? UiCopy.authLoginTitle : UiCopy.authSignupTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 23,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 25,
              height: 1,
              color: AppColors.gold.withValues(alpha: 0.45),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.auto_awesome,
              size: 14,
              color: AppColors.gold,
            ),
            const SizedBox(width: 8),
            Container(
              width: 25,
              height: 1,
              color: AppColors.gold.withValues(alpha: 0.45),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          _isLogin ? UiCopy.authLoginSubtitle : UiCopy.authSignupSubtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 12.5,
            height: 1.8,
            color: AppColors.textSecondary,
          ),
        ),
        if (!_isLogin) ...[
          const SizedBox(height: 14),
          const InfoBanner(
            message: UiCopy.brandTaglineAr,
            tone: InfoBannerTone.tip,
            padding: EdgeInsets.zero,
          ),
        ],
      ],
    );
  }

  Widget _buildFooterInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.goldSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.25),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.verified_user_outlined,
            size: 20,
            color: AppColors.goldDark,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'نحرص على وضوح الخيارات وسهولة التنسيق لحماية تجربتك.',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 11,
                height: 1.6,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IslamicScaffold(
      showPattern: true,
      body: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 700;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWide ? 620 : 600,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      IslamicCard(
                        padding: const EdgeInsets.fromLTRB(
                          18,
                          20,
                          18,
                          18,
                        ),
                        child: Column(
                          children: [
                          
                            _buildInputFields(),
                            if (!_isLogin) ...[
                              _buildSignupSection(),
                              const SizedBox(height: 12),
                              const InfoBanner(
                                message: UiCopy.authAfterSignupHint,
                                tone: InfoBannerTone.info,
                                padding: EdgeInsets.zero,
                              ),
                            ],
                            const SizedBox(height: 22),
                            IslamicButton(
                              label: _isLogin
                                  ? UiCopy.authLoginButton
                                  : UiCopy.authSignupButton,
                              icon: Icon(
                                _isLogin
                                    ? Icons.login_rounded
                                    : Icons.person_add_alt_1_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: _isLoading ? null : _submit,
                              isLoading: _isLoading,
                            ),
                            const SizedBox(height: 6),
                            TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      setState(() {
                                        _isLogin = !_isLogin;
                                      });
                                    },
                              child: Text(
                                _isLogin
                                    ? 'ليس لديك حساب؟ إنشاء حساب جديد'
                                    : 'لديك حساب بالفعل؟ تسجيل الدخول',
                              ),
                            ),
                            if (_isLogin)
                              TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                        Navigator.pushNamed(
                                          context,
                                          '/reset-password',
                                        );
                                      },
                                child: const Text(
                                  'هل نسيت كلمة المرور؟',
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildFooterInfo(),
                      const SizedBox(height: 12),
                      const Text(
                        'GRAND ONE • ALL IN ONE',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
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