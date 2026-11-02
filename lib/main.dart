// lib/main.dart
// ============================================================
// GRAND ONE — نقطة البداية
// ============================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';

import 'config.dart';
import 'app_colors.dart';
import 'app_theme.dart';

import 'screens/source_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/waiting_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/intro_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/contact_admin_screen.dart';
import 'ui/shell/app_shell.dart';

import 'services/notifications_service.dart';
import 'services/remote_config_service.dart';
import 'services/device_gate.dart';

import 'widgets/islamic_decorations.dart';
import 'design/tokens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RemoteConfigService.applyCached();
  AppConfig.validate();
  await EasyLocalization.ensureInitialized();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  unawaited(RemoteConfigService.refresh());

  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase not initialized: $e');
  }

  try {
    await NotificationsService.init();
  } catch (e) {
    debugPrint('Notifications init failed: $e');
  }

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('ar'),
      child: const GrandOneApp(),
    ),
  );
}

class GrandOneApp extends StatefulWidget {
  const GrandOneApp({super.key});

  @override
  State<GrandOneApp> createState() => _GrandOneAppState();
}

class _GrandOneAppState extends State<GrandOneApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appFullName,
      debugShowCheckedModeBanner: false,
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      theme: AppTheme.grandOneTheme,
      themeMode: ThemeMode.light,
      scrollBehavior: const GrandOneScrollBehavior(),
      home: const SplashScreen(),
      routes: {
        '/verify': (context) => const AuthScreen(),
        '/waiting': (context) => const WaitingScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
        '/change-password': (context) => const ChangePasswordScreen(),
        '/intro': (context) => const IntroScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/home-groom': (context) => const AppShell(),
        '/home-bride': (context) => const AppShell(),
        '/shell': (context) => const AppShell(),
        '/shell-bride': (context) => const AppShell(),
        '/source': (context) {
          final user = Supabase.instance.client.auth.currentUser;
          if (user == null) {
            return const IntroScreen();
          }
          return const SourceScreen();
        },
        '/contact-admin': (context) => const ContactAdminScreen(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  bool _hasError = false;
  bool _errorIsDeviceBlock = false;
  String _errorMessage =
      'تعذر الاتصال بالخادم، يرجى التحقق من الاتصال بالإنترنت';

  late final AnimationController _fade =
      AnimationController(vsync: this, duration: Motion.splash)..forward();

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  Future<void> _checkSession() async {
    if (_hasError) {
      setState(() {
        _hasError = false;
        _errorIsDeviceBlock = false;
        _errorMessage =
            'تعذر الاتصال بالخادم، يرجى التحقق من الاتصال بالإنترنت';
      });
    }

    final client = Supabase.instance.client;

    try {
      await client.auth.onAuthStateChange.first.timeout(
        const Duration(seconds: 3),
        onTimeout: () => const AuthState(AuthChangeEvent.initialSession, null),
      );
    } catch (_) {}

    if (!mounted) return;

    final user = client.auth.currentUser;

    if (user == null) {
      _goTo(const IntroScreen());
      return;
    }

    try {
      final profile = await client
          .from('profiles')
          .select('id, role, is_banned, is_active')
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null ||
          profile['is_banned'] == true ||
          profile['is_active'] == false) {
        await client.auth.signOut();
        _goTo(const IntroScreen());
        return;
      }

      final gate = await DeviceGate.ensureRegistered();
      if (!gate.isAllowed) {
        await client.auth.signOut();
        if (!mounted) return;
        setState(() {
          _hasError = true;
          _errorMessage = gate.message;
          _errorIsDeviceBlock = gate.status == DeviceGateStatus.blocked;
        });
        return;
      }

      final role = profile['role']?.toString().trim();

      if (role == 'services_only') {
        _goTo(const AppShell());
        return;
      }

      if (role == 'groom' || role == 'bride') {
        await client.auth.signOut();
        if (!mounted) return;
        setState(() {
          _hasError = true;
          _errorMessage = 'هذا التطبيق لحسابات الخدمات فقط.';
        });
        return;
      }

      await client.auth.signOut();
      _goTo(const IntroScreen());
    } on PostgrestException catch (e) {
      debugPrint('SPLASH DB ERROR: ${e.message}');
      if (!mounted) return;
      setState(() {
        _hasError = true;
      });
    } catch (e) {
      debugPrint('SPLASH ERROR: $e');
      try {
        await client.auth.signOut();
      } catch (_) {}
      _goTo(const IntroScreen());
    }
  }

  void _goTo(Widget screen) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppGradients.splash),
        child: FadeTransition(
          opacity: _fade,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const IslamicLogoFrame(
                    size: 120,
                    showTitle: true,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'ALL IN ONE',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 13,
                      letterSpacing: 3.2,
                      fontWeight: FontWeight.w700,
                      color: AppPalette.gold.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 36),
                  if (_hasError) ...[
                    Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        color: AppColors.error,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_errorIsDeviceBlock)
                      ElevatedButton(
                        onPressed: () => _goTo(const IntroScreen()),
                        child: const Text('حسناً'),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: _checkSession,
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة المحاولة'),
                      ),
                  ] else
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: AppPalette.gold,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
