// lib/screens/waiting_screen.dart
// ============================================================
// WaitingScreen — مراقبة تفعيل الحساب
// ============================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';

import '../widgets/brand_decorations.dart';
import '../widgets/ux_helpers.dart';
import '../app_colors.dart';
import '../ui_copy.dart';
import '../ui/shell/app_shell.dart';
import 'provider_shell_screen.dart';
import 'organizer_shell_screen.dart';

class WaitingScreen extends StatefulWidget {
  const WaitingScreen({super.key});

  @override
  State<WaitingScreen> createState() => _WaitingScreenState();
}

class _WaitingScreenState extends State<WaitingScreen>
    with WidgetsBindingObserver {
  final _client = Supabase.instance.client;

  bool _checking = false;
  bool _isLoggingOut = false;
  Timer? _timer;

  // ============================================================
  // Lifecycle
  // ============================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    // ═══ فحص أولي ═══
    _checkVerification();

    // ═══ بدء المؤقّت ═══
    _startTimer();
  }

  @override
  void dispose() {
    _stopTimer();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      // ═══ عاد التطبيق → افحص فورًا + شغّل المؤقّت ═══
      _checkVerification();
      _startTimer();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      // ═══ التطبيق في الخلفية → أوقف المؤقّت ═══
      _stopTimer();
    }
  }

  // ============================================================
  // المؤقّت
  // ============================================================

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(
      const Duration(seconds: 10),
      (_) {
        if (mounted && !_checking) {
          _checkVerification();
        }
      },
    );
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  // ============================================================
  // تسجيل الخروج
  // ============================================================

  Future<void> _logout() async {
    if (_isLoggingOut) return;
    if (!mounted) return;

    setState(() => _isLoggingOut = true);

    _stopTimer();

    try {
      await _client.auth.signOut();
    } catch (e) {
      debugPrint('⚠️ Logout error: $e');
    }

    if (!mounted) return;

    Navigator.pushReplacementNamed(context, '/intro');
  }

  // ============================================================
  // التنقلات الموحّدة
  // ============================================================

  void _navigateToServices() {
    _stopTimer();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const AppShell(),
      ),
    );
  }

  void _navigateToIntro() {
    _stopTimer();

    if (!mounted) return;

    Navigator.pushReplacementNamed(context, '/intro');
  }

  // ============================================================
  // التحقق من حالة الحساب
  // ============================================================

  Future<void> _checkVerification() async {
    if (_checking) return;
    if (!mounted) return;

    setState(() {
      _checking = true;
    });

    try {
      // ═══ 1. اقرأ المستخدم الحالي ═══
      final userId = _client.auth.currentUser?.id;

      if (userId == null) {
        debugPrint('⏳ WaitingScreen: no user → intro');
        _navigateToIntro();
        return;
      }

      // ═══ 2. اقرأ الدور من profiles ═══
      final profile = await _client
          .from('profiles')
          .select('role, is_banned, is_active')
          .eq('id', userId)
          .maybeSingle();

      if (!mounted) return;

      if (profile == null) {
        debugPrint('⚠️ WaitingScreen: profile is null');
        return;
      }

      // ═══ 3. فحص الحظر ═══
      final isBanned = profile['is_banned'] == true;
      final isActive = profile['is_active'] != false;

      if (isBanned || !isActive) {
        debugPrint('🔴 WaitingScreen: account banned/inactive');
        try {
          await _client.auth.signOut();
        } catch (_) {}
        _navigateToIntro();
        return;
      }

      final role = profile['role'] as String?;

      if (role == 'groom' || role == 'bride') {
        debugPrint('⚠️ WaitingScreen: marriage role not supported');
        try {
          await _client.auth.signOut();
        } catch (_) {}
        _navigateToIntro();
        return;
      }

      if (role == 'services_only') {
        debugPrint('✅ WaitingScreen: services account → services');
        _navigateToServices();
        return;
      }

      if (role == 'provider') {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProviderShellScreen()),
        );
        return;
      }

      if (role == 'organizer') {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OrganizerShellScreen()),
        );
        return;
      }

      debugPrint('⚠️ WaitingScreen: unknown role: $role');
    } catch (e, stackTrace) {
      debugPrint('🔴 WaitingScreen error: $e');
      debugPrint('$stackTrace');
    } finally {
      if (mounted) {
        setState(() {
          _checking = false;
        });
      }
    }
  }

  // ============================================================
  // أيقونة الانتظار
  // ============================================================

  Widget _buildWaitingIcon() {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.goldLight,
                width: 1.5,
              ),
            ),
          ),
          const Icon(
            Icons.hourglass_top_rounded,
            size: 48,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // بطاقة حالة المراجعة
  // ============================================================

  Widget _buildStatusCard() {
    return BrandCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.goldSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.verified_outlined,
                  color: AppColors.goldDark,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  tr('waiting_title'),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            tr('waiting_body'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.7,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // مؤشر حالة الفحص
  // ============================================================

  Widget _buildCheckingStatus() {
    return AnimatedOpacity(
      opacity: _checking ? 1 : 0.75,
      duration: const Duration(milliseconds: 250),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceGreen,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.borderLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_checking)
              const SizedBox(
                width: 17,
                height: 17,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                ),
              )
            else
              const Icon(
                Icons.check_circle_outline,
                size: 18,
                color: AppColors.success,
              ),
            const SizedBox(width: 9),
            Text(
              _checking ? tr('checking') : tr('refresh'),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // البناء
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return BrandScaffold(
      appBar: BrandAppBar(
        title: 'حالة الحساب',
        actions: [
          // ═══ زر تسجيل الخروج ═══
          IconButton(
            tooltip: 'تسجيل الخروج',
            icon: _isLoggingOut
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.logout_rounded),
            onPressed: _isLoggingOut ? null : _logout,
          ),
        ],
      ),
      body: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth > 700
                ? 620.0
                : constraints.maxWidth;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                20,
                28,
                20,
                32,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: maxWidth,
                  ),
                  child: Column(
                    children: [
                      // ═══ رمز الانتظار ═══
                      _buildWaitingIcon(),

                      const SizedBox(height: 22),

                      const Text(
                        UiCopy.waitingTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 16),

                      const InfoBanner(
                        message: UiCopy.brandTaglineAr,
                        tone: InfoBannerTone.tip,
                      ),

                      const SizedBox(height: 16),

                      const InfoBanner(
                        message: UiCopy.waitingBody,
                        tone: InfoBannerTone.info,
                        padding: EdgeInsets.zero,
                      ),

                      const SizedBox(height: 10),

                      const InfoBanner(
                        message: UiCopy.waitingWhatChecked,
                        tone: InfoBannerTone.tip,
                        icon: Icons.fact_check_outlined,
                        padding: EdgeInsets.zero,
                      ),

                      const SizedBox(height: 26),

                      // ═══ بطاقة الحالة ═══
                      _buildStatusCard(),

                      const SizedBox(height: 16),

                      // ═══ مؤشر الفحص ═══
                      _buildCheckingStatus(),

                      const SizedBox(height: 20),

                      // ═══ زر التحديث ═══
                      BrandButton(
                        label: _checking
                            ? tr('checking')
                            : tr('refresh'),
                        onPressed: _checking
                            ? null
                            : _checkVerification,
                        isLoading: _checking,
                      ),

                      const SizedBox(height: 22),

                      // ═══ ملاحظة ═══
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: AppColors.goldSoft,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.goldLight,
                          ),
                        ),
                        child: const Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 21,
                              color: AppColors.goldDark,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'سيتم تحديث حالة حسابك تلقائيًا. '
                                'لا حاجة لإغلاق التطبيق أو إعادة تسجيل الدخول.',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.7,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        'GRAND ONE • خيارات أوضح وتجربة أفضل',
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