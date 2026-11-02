// lib/screens/settings_screen.dart
// ============================================================
// SettingsScreen — إعدادات المستخدم
// ============================================================

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';

import '../config.dart';
import '../services/session_service.dart';
import '../services/notifications_service.dart';
import '../widgets/islamic_decorations.dart';
import '../app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoggingOut = false;
  bool _isDeleting = false;

  // ═══ Base URL من AppConfig ═══
  static String get _baseUrl => AppConfig.denoApiBaseUrl;

  // ============================================================
  // تسجيل الخروج
  // ============================================================

  Future<void> _logout() async {
    if (_isLoggingOut) return;
    if (!mounted) return;

    setState(() => _isLoggingOut = true);

    try {
      // ═══ فصل FCM ═══
      try {
        await NotificationsService.logout();
      } catch (_) {}

      await SessionService.clearSession();
    } catch (e) {
      debugPrint('⚠️ Logout error: $e');
    }

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/intro',
      (route) => false,
    );
  }

  // ============================================================
  // ترجمة أخطاء حذف الحساب
  // ============================================================

  String _translateDeleteError(dynamic e) {
    final msg = e.toString().toLowerCase();

    if (msg.contains('session') ||
        msg.contains('expired') ||
        msg.contains('jwt')) {
      return 'انتهت جلسة الدخول. يرجى تسجيل الدخول مجدداً.';
    }

    if (msg.contains('network') ||
        msg.contains('timeout') ||
        msg.contains('connection') ||
        msg.contains('failed host lookup')) {
      return 'تعذر الاتصال بالخادم. تحقق من الإنترنت.';
    }

    if (msg.contains('already deleted')) {
      return 'تم حذف الحساب مسبقاً.';
    }

    if (msg.contains('unauthorized') ||
        msg.contains('forbidden')) {
      return 'لا تملك صلاحية حذف هذا الحساب.';
    }

    return 'تعذر حذف الحساب. حاول مرة أخرى.';
  }

  // ============================================================
  // حذف الحساب
  // ============================================================

  Future<void> _deleteAccount() async {
    if (_isDeleting) return;
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 8),
          contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 10),
          actionsPadding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.error,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'حذف الحساب نهائيًا',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'هل أنت متأكد من حذف حسابك؟\n\n'
            'سيتم حذف جميع بياناتك نهائيًا: ملفك الشخصي، الطلبات، المحادثات، والصور. '
            'لا يمكن التراجع عن هذا الإجراء.',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              height: 1.7,
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                'إلغاء',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 11,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(
                Icons.delete_forever_rounded,
                size: 18,
              ),
              label: const Text(
                'حذف نهائي',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);

    try {
      // ============================================================
      // 1. قراءة الجلسة الحالية
      // ============================================================
      var session = Supabase.instance.client.auth.currentSession;

      if (session == null) {
        throw Exception('انتهت جلسة الدخول');
      }

      // ============================================================
      // 2. تجديد التوكن إن كان على وشك الانتهاء
      // ============================================================
      final expiresAt = session.expiresAt;

      if (expiresAt != null) {
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

        if (expiresAt <= now + 60) {
          try {
            final refreshResponse =
                await Supabase.instance.client.auth.refreshSession();

            session = refreshResponse.session;

            if (session == null) {
              throw Exception('انتهت جلسة الدخول');
            }
          } catch (e) {
            debugPrint('⚠️ Token refresh failed: $e');
            throw Exception('انتهت جلسة الدخول. يرجى تسجيل الدخول مجدداً.');
          }
        }
      }

      // ============================================================
      // 3. استدعاء Deno endpoint مع timeout
      // ============================================================
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/account/delete'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${session.accessToken}',
            },
          )
          .timeout(
            AppConfig.httpTimeout,
            onTimeout: () {
              throw Exception('انتهت مهلة الاتصال');
            },
          );

      if (!mounted) return;

      if (response.statusCode != 200 &&
          response.statusCode != 201) {
        String errorMsg = 'فشل حذف الحساب';

        try {
          final data = jsonDecode(response.body);
          if (data is Map && data['error'] is String) {
            errorMsg = data['error'] as String;
          }
        } catch (_) {}

        debugPrint(
          '🔴 Delete account response: ${response.statusCode} - $errorMsg',
        );

        throw Exception(errorMsg);
      }

      // ============================================================
      // 4. نجح الحذف — تنظيف محلي + خروج
      // ============================================================
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (_) {}

      try {
        await SessionService.clearSession();
      } catch (_) {}

      if (!mounted) return;

      // ═══ رسالة نجاح ═══
      _showSuccessMessage('✅ تم حذف حسابك بنجاح');

      // ═══ تأخير بسيط ثم الانتقال ═══
      await Future.delayed(
        const Duration(milliseconds: 800),
      );

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/intro',
        (route) => false,
      );
    } catch (e, stackTrace) {
      debugPrint('🔴 Delete account error: $e');
      debugPrint('$stackTrace');

      if (!mounted) return;

      setState(() => _isDeleting = false);

      _showErrorMessage(_translateDeleteError(e));
    }
  }

  // ============================================================
  // رسائل SnackBar
  // ============================================================

  void _showSuccessMessage(String message) {
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
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  void _showErrorMessage(String message) {
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
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  // ============================================================
  // عنصر إعداد
  // ============================================================

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required VoidCallback? onTap,
    Color? iconColor,
    Color? titleColor,
    Widget? trailing,
  }) {
    final color = iconColor ?? AppColors.primary;
    final isEnabled = onTap != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Opacity(
          opacity: isEnabled ? 1.0 : 0.6,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: titleColor ?? AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                trailing ??
                    const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 15,
                      color: AppColors.mutedText,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return IslamicScaffold(
      appBar: IslamicAppBar(
        title: tr('settings'),
      ),
      body: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth > 700
                ? 620.0
                : constraints.maxWidth;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 22),

                      // ═══ قسم الحساب ═══
                      _buildSectionHeader(
                        'الحساب',
                        Icons.person_outline_rounded,
                      ),
                      const SizedBox(height: 8),
                      _buildSettingsCard(
                        children: [
                          _buildSettingItem(
                            icon: Icons.lock_reset_rounded,
                            title: tr('change_password'),
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/change-password',
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ═══ الأمان ═══
                      _buildSectionHeader(
                        'الأمان والخصوصية',
                        Icons.security_outlined,
                      ),
                      const SizedBox(height: 8),
                      _buildSettingsCard(
                        children: [
                          _buildSettingItem(
                            icon: Icons.delete_forever_rounded,
                            title: tr('delete_account'),
                            titleColor: AppColors.error,
                            iconColor: AppColors.error,
                            trailing: _isDeleting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.error,
                                    ),
                                  )
                                : null,
                            onTap: _isDeleting
                                ? null
                                : _deleteAccount,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ═══ تسجيل الخروج ═══
                      _buildSettingsCard(
                        children: [
                          _buildSettingItem(
                            icon: Icons.logout_rounded,
                            title: tr('logout'),
                            titleColor: AppColors.error,
                            iconColor: AppColors.error,
                            trailing: _isLoggingOut
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.error,
                                    ),
                                  )
                                : null,
                            onTap: _isLoggingOut ? null : _logout,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ═══ رسالة الخصوصية ═══
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.shield_outlined,
                              size: 21,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'نحرص في GRAND ONE على حماية خصوصيتك وبياناتك، '
                                'ولا يتم عرض معلوماتك إلا ضمن الصلاحيات المسموح بها.',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 12,
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
                        'GRAND ONE • ALL IN ONE',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 11.5,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w600,
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

  // ============================================================
  // رأس الصفحة
  // ============================================================

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.12),
              border: Border.all(
                color: AppColors.goldLight,
                width: 1.2,
              ),
            ),
            child: const Icon(
              Icons.settings_outlined,
              color: AppColors.goldLight,
              size: 29,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('settings'),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'إدارة حسابك بخصوصية ووضوح',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12.5,
                    height: 1.5,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // عنوان القسم
  // ============================================================

  Widget _buildSectionHeader(
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.goldSoft,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.goldLight),
          ),
          child: Icon(
            icon,
            size: 18,
            color: AppColors.goldDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // بطاقة الإعدادات
  // ============================================================

  Widget _buildSettingsCard({
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Column(children: children),
      ),
    );
  }

}