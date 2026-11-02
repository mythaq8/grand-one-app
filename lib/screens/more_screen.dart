// lib/screens/more_screen.dart
// ============================================================
// تبويب «المزيد» — Golden Party (خدمات فقط)
// ============================================================

import 'package:flutter/material.dart';

import '../config.dart';
import '../design/tokens.dart';
import '../design/typography.dart';
import '../ui/kit/kit.dart';
import '../ui/layout/responsive.dart';
import '../ui/shared/logout_action.dart';
import '../widgets/brand_mark.dart';
import 'my_bookings_screen.dart';
import 'my_occasion_requests_screen.dart';
import 'my_party_requests_screen.dart';
import 'services_user_profile_setup_screen.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key, required this.isGroomRole});

  /// بقي للتوافق مع الاستدعاءات القديمة؛ لا يُستخدم في مسار الخدمات.
  final bool isGroomRole;

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  void _push(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: EdgeInsets.fromLTRB(
              Responsive.horizontalPadding(context),
              Space.md,
              Responsive.horizontalPadding(context),
              Space.giant,
            ),
            children: [
              ContentMaxWidth(
                maxWidth: Sizes.formMax,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _ProfileHeader(),
                    const SectionHeader(title: 'حسابي', icon: Icons.person_outline_rounded),
                    _Group(
                      children: [
                        ActionTile(
                          icon: Icons.badge_outlined,
                          title: 'بيانات حسابي',
                          subtitle: 'الاسم والمحافظة وواتساب',
                          onTap: () => _push(
                            const ServicesUserProfileSetupScreen(),
                          ),
                        ),
                      ],
                    ),

                    const SectionHeader(title: 'طلباتي', icon: Icons.receipt_long_outlined),
                    _Group(
                      children: [
                        ActionTile(
                          icon: Icons.calendar_month_outlined,
                          title: 'الحجوزات',
                          onTap: () => _push(const MyBookingsScreen()),
                        ),
                        ActionTile(
                          icon: Icons.celebration_outlined,
                          title: 'طلبات تنظيم المناسبة',
                          onTap: () => _push(const MyOccasionRequestsScreen()),
                        ),
                        ActionTile(
                          icon: Icons.history_outlined,
                          title: 'طلبات الحفلات',
                          subtitle: 'المسار السابق',
                          onTap: () => _push(const MyPartyRequestsScreen()),
                        ),
                      ],
                    ),

                    const SectionHeader(title: 'الدعم', icon: Icons.support_agent_rounded),
                    _Group(
                      children: [
                        ActionTile(
                          icon: Icons.support_agent_rounded,
                          title: 'التواصل مع الإدارة',
                          subtitle: 'سؤال أو مشكلة في حسابك',
                          onTap: () =>
                              Navigator.pushNamed(context, '/contact-admin'),
                        ),
                      ],
                    ),

                    const SectionHeader(title: 'الإعدادات', icon: Icons.settings_outlined),
                    _Group(
                      children: [
                        ActionTile(
                          icon: Icons.settings_outlined,
                          title: 'الإعدادات العامة',
                          subtitle: 'كلمة المرور وحذف الحساب',
                          onTap: () => Navigator.pushNamed(context, '/settings'),
                        ),
                      ],
                    ),

                    const SizedBox(height: Space.xxl),

                    OutlinedButton.icon(
                      onPressed: () => confirmAndLogout(context),
                      icon: const Icon(
                        Icons.logout_rounded,
                        size: Sizes.iconMd,
                        color: AppPalette.error,
                      ),
                      label: const Text(
                        'تسجيل الخروج',
                        style: TextStyle(color: AppPalette.error),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppPalette.error.withValues(alpha: 0.35),
                        ),
                      ),
                    ),

                    const SizedBox(height: Space.xl),
                    Center(
                      child: Text(
                        '${AppConfig.appName} • v1.0.0',
                        style: AppText.micro.copyWith(
                          color: AppPalette.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        gradient: AppGradients.header,
        borderRadius: Radii.brLg,
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          const BrandMark(size: 50, onDark: true),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppConfig.appName,
                  style: AppText.section.copyWith(
                    color: AppPalette.onPrimary,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'خدمات الأعراس',
                  style: AppText.caption.copyWith(
                    color: AppPalette.goldLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: Radii.brLg,
        border: Border.all(color: AppPalette.borderLight),
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                thickness: 1,
                indent: Space.lg,
                endIndent: Space.lg,
                color: AppPalette.borderSubtle,
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}
