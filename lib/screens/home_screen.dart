// lib/screens/home_screen.dart
// ============================================================
// HomeScreen — الشاشة الرئيسية الجديدة
// تصميم: Hero قابل للتقليب + Drawer جانبي + Bottom Nav
// ============================================================

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_colors.dart';
import '../config.dart';
import '../design/tokens.dart';
import '../services/api_service.dart';
import '../services/notifications_service.dart';
import '../services/session_service.dart';
import '../ui_copy.dart';
import '../widgets/brand_mark.dart';
import '../widgets/brand_decorations.dart';
import '../widgets/screen_fit.dart';
import '../widgets/notification_badge_icon.dart';
import 'my_bookings_screen.dart';
import 'my_occasion_requests_screen.dart';
import 'services_user_profile_setup_screen.dart';
import '../services/search_date.dart';

class HomeScreen extends StatefulWidget {

  /// عند العرض داخل تبويب الهيكل: بلا Drawer وبلا تكرار للعنوان.
  final bool embedded;

  /// عند وجودها، تتنقّل بطاقات الرئيسية بين التبويبات بدل فتح
  /// شاشة جديدة فوق الشاشة الحالية (يمنع تكرار الشاشة نفسها).
  final VoidCallback? onOpenServicesTab;
  final VoidCallback? onOpenRequestsTab;

  const HomeScreen({
    Key? key,
    this.embedded = false,
    this.onOpenServicesTab,
    this.onOpenRequestsTab,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver {
  final _client = Supabase.instance.client;

  String _userName = '';
  String? _avatarUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) {
          setState(() {
            _userName = 'مستخدم ${AppConfig.appName}';
            _isLoading = false;
          });
        }
        return;
      }

      final profile = await _client
          .from('services_profiles')
          .select('full_name')
          .eq('user_id', userId)
          .maybeSingle();
      final name = profile?['full_name']?.toString().trim();

      if (!mounted) return;

      setState(() {
        _userName = (name != null && name.isNotEmpty)
            ? name
            : 'مستخدم ${AppConfig.appName}';
        _avatarUrl = null;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Home load error: $e');
      if (mounted) {
        setState(() {
          _userName = 'مستخدم ${AppConfig.appName}';
          _avatarUrl = null;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        // عند العرض داخل تبويب الهيكل لا نضيف Drawer؛
        // القائمة صارت تبويب «المزيد» ولا داعي لتكرارها.
        drawer: widget.embedded ? null : _buildDrawer(),
        body: ScreenFrame(child: _buildHomeTab()),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // التبويب الأول: الرئيسية
  // ═══════════════════════════════════════════════════════════

  Widget _buildHomeTab() {
    return BrandBackground(
      showPattern: true,
      child: SafeArea(
        child: Column(
          children: [
            // الشريط العلوي يظهر دائماً (حتى داخل التبويبات): فيه الشعار
            // وجرس الإشعارات الذي لا مدخل غيره في الهيكل.
            _buildTopBar(),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _loadUserData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── 1. من أنت الآن ──
                      _buildWelcomeCard(),

                      // ── 2. بطاقات التعريف بالخدمات ──
                      const SizedBox(height: 24),
                      _buildHeroPages(),

                      const SizedBox(height: 24),
                      _buildBrandPromiseCard(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // الشريط العلوي (ثابت)
  // ═══════════════════════════════════════════════════════════

  Widget _buildTopBar() {
    final standalone = !widget.embedded;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Row(
        children: [
          // القائمة الجانبية والإعدادات فقط خارج الهيكل؛ داخله لهما
          // تبويب «المزيد».
          if (standalone) ...[
            Builder(
              builder: (context) => _buildCircleButton(
                icon: Icons.menu_rounded,
                onTap: () => Scaffold.of(context).openDrawer(),
                tooltip: 'القائمة',
              ),
            ),
            const SizedBox(width: 10),
          ],
          const BrandMark(size: 56),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppConfig.appName,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 20,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: 0.4,
                  ),
                ),
                const Text(
                  'ALL IN ONE',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 11.5,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.4,
                    color: AppColors.goldDark,
                  ),
                ),
              ],
            ),
          ),
          const NotificationBadgeIcon(),
          if (standalone) ...[
            const SizedBox(width: 6),
            _buildCircleButton(
              icon: Icons.settings_outlined,
              onTap: () => Navigator.pushNamed(context, '/settings'),
              tooltip: 'الإعدادات',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
          child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.borderLight),
            boxShadow: AppColors.shadowSubtle,
          ),
          child: Icon(icon, size: 19, color: AppColors.primary),
        ),
      ),
    );

    return tooltip != null
        ? Tooltip(message: tooltip, child: button)
        : button;
  }

  // ═══════════════════════════════════════════════════════════
  // التحية المخصصة
  // ═══════════════════════════════════════════════════════════

  Widget _buildWelcomeCard() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'صباح الخير'
        : hour < 17
            ? 'طاب يومك'
            : 'مساء الخير';

    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.shadowMedium,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // زخرفة هندسية خفيفة + الشعار كعلامة مائية على الطرف.
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: GeometricPatternPainter(
                    color: AppColors.gold.withValues(alpha: 0.09),
                    spacing: 44,
                  ),
                ),
              ),
            ),
            Positioned(
              left: -22,
              bottom: -26,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.20,
                  child: const BrandMark(size: 128, framed: false),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
              child: Row(
                children: [
                  _buildPersonAvatar(size: 58),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeting,
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.82),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isLoading ? '...' : _userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.goldLight.withValues(alpha: 0.45),
                            ),
                          ),
                          child: const Text(
                            'حساب خدمات',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 11.5,
                              color: AppColors.goldLight,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildBrandPromiseCard() {
    return Container(
      padding: const EdgeInsets.all(Space.xl),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: Radii.brLg,
        border: Border.all(color: AppPalette.borderLight),
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            UiCopy.homeHeroTitle,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: Space.sm),
          Text(
            UiCopy.homeHeroBody,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 13.5,
              height: 1.55,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: Space.lg),
          OutlinedButton.icon(
            onPressed: _pickEventDate,
            icon: const Icon(Icons.event),
            label: ValueListenableBuilder<DateTime?>(
              valueListenable: SearchDate.date,
              builder: (_, d, __) => Text(
                d == null ? 'متى مناسبتك؟ اختر التاريخ' : 'مناسبتك: ' + (SearchDate.iso ?? ''),
              ),
            ),
          ),
          const SizedBox(height: Space.sm),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.onOpenServicesTab,
                  child: const Text(UiCopy.homePrimaryCta),
                ),
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onOpenRequestsTab ??
                      widget.onOpenServicesTab,
                  child: const Text(UiCopy.homeSecondaryCta),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickEventDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: SearchDate.date.value ?? now.add(const Duration(days: 2)),
      firstDate: now,
      lastDate: DateTime(now.year + 1, now.month, now.day),
      helpText: 'تاريخ مناسبتك',
    );
    if (picked == null) return;
    SearchDate.date.value = picked;
    widget.onOpenServicesTab?.call();
  }

  Widget _buildPersonAvatar({required double size}) {
    final fallback = Center(
      child: Text(
        _userName.isNotEmpty ? _userName.characters.first : '؟',
        style: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: size * 0.42,
          fontWeight: FontWeight.w800,
          color: AppColors.goldLight,
        ),
      ),
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.12),
        border: Border.all(color: AppColors.gold, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: _avatarUrl != null && _avatarUrl!.isNotEmpty
          ? Image.network(
              _avatarUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => fallback,
            )
          : fallback,
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Hero Pages (قابل للتقليب)
  // ═══════════════════════════════════════════════════════════

  Widget _buildHeroPages() {
    return const HomePromoCarousel();
  }

  // ═══════════════════════════════════════════════════════════
  // Drawer الجانبي
  // ═══════════════════════════════════════════════════════════

  Widget _buildDrawer() {
  return Drawer(
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.horizontal(
        left: Radius.circular(AppColors.radiusXl),
      ),
    ),
    child: SafeArea(
      child: Column(
        children: [
          _buildDrawerHeader(),

          const SizedBox(height: 8),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  // ═══════════════════════════════════════════
                  // القسم 1: حسابي
                  // ═══════════════════════════════════════════
                  _buildDrawerSection(
                    title: 'حسابي',
                    items: [
                      _DrawerItem(
                        icon: Icons.person_outline_rounded,
                        title: 'بيانات حسابي',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const ServicesUserProfileSetupScreen(),
                            ),
                          );
                        },
                      ),
                      _DrawerItem(
                        icon: Icons.calendar_month_outlined,
                        title: 'حجوزاتي',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MyBookingsScreen(),
                            ),
                          );
                        },
                      ),
                      _DrawerItem(
                        icon: Icons.celebration_outlined,
                        title: 'طلبات تنظيم المناسبة',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const MyOccasionRequestsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ═══════════════════════════════════════════
                  // القسم 2: الدعم والمساعدة
                  // ═══════════════════════════════════════════
                  _buildDrawerSection(
                    title: 'الدعم والمساعدة',
                    items: [
                      _DrawerItem(
                        icon: Icons.support_agent_rounded,
                        title: 'التواصل مع الإدارة',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/contact-admin');
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ═══════════════════════════════════════════
                  // القسم 3: الإعدادات
                  // ═══════════════════════════════════════════
                  _buildDrawerSection(
                    title: 'الإعدادات',
                    items: [
                      _DrawerItem(
                        icon: Icons.settings_outlined,
                        title: 'الإعدادات العامة',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/settings');
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // ═══════════════════════════════════════════════
          // تسجيل الخروج (ثابت في الأسفل)
          // ═══════════════════════════════════════════════
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Material(
              color: AppColors.errorLight,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: _logout,
                borderRadius: BorderRadius.circular(14),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        color: AppColors.error,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'تسجيل الخروج',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // التذييل
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              '${AppConfig.appName} • v1.0.0',
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 10,
                color: AppColors.mutedText,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildDrawerHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.shadowSoft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildPersonAvatar(size: 56),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isLoading ? '...' : _userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'حساب خدمات',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.goldLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const OrnamentDivider(
            width: 160,
            color: AppColors.goldLight,
          ),
          const SizedBox(height: 8),
          Text(
            UiCopy.brandTaglineAr,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.82),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerSection({
    required String title,
    required List<_DrawerItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.goldDark,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                _buildDrawerItem(items[i]),
                if (i != items.length - 1)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    indent: 62,
                    endIndent: 14,
                    color: AppColors.borderLight,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDrawerItem(_DrawerItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(item.icon, size: 19, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_left_rounded,
                size: 18,
                color: AppColors.mutedText,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // تسجيل الخروج
  // ═══════════════════════════════════════════════════════════

  Future<void> _logout() async {
    Navigator.pop(context); // إغلاق الـ Drawer

    // تأكيد
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusLg),
          ),
          title: const Text('تسجيل الخروج'),
          content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'خروج',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    try {
      // افصل FCM قبل مسح الجلسة (يحتاج مستخدماً حالياً)
      try {
        await NotificationsService.logout();
      } catch (_) {}

      await SessionService.clearSession();
    } catch (e) {
      debugPrint('⚠️ Home logout error: $e');
    }

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/intro',
      (route) => false,
    );
  }

}

// ═══════════════════════════════════════════════════════════════
// فئات مساعدة
// ═══════════════════════════════════════════════════════════════

class _DrawerItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}

// ═══════════════════════════════════════════════════════════════
// Hero Pages Carousel
// ═══════════════════════════════════════════════════════════════

/// بطاقات تسويقية: صورة + جملة قصيرة، تتقلب وحدها كل بضع ثوانٍ.
class HomePromoCarousel extends StatefulWidget {
  const HomePromoCarousel({super.key});

  @override
  State<HomePromoCarousel> createState() => _HomePromoCarouselState();
}

class _HomePromoCarouselState extends State<HomePromoCarousel> {
  final _controller = PageController();
  Timer? _timer;
  int _currentPage = 0;
  List<_HeroSlide> _slides = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _slides = _fallbackSlides();
    _loadRemote();
    _schedule();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadRemote() async {
    List<Map<String, dynamic>> rows;
    try {
      rows = await ApiService.getHomePromoCards();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }
    if (!mounted) return;
    if (rows.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    final slides = <_HeroSlide>[];
    for (var i = 0; i < rows.length; i++) {
      final r = rows[i];
      final signed = r['signed_url']?.toString().trim();
      final assetFallback = i < AppAssets.homePromo.length
          ? AppAssets.homePromo[i]
          : null;
      slides.add(
        _HeroSlide(
          imageUrl: (signed != null && signed.isNotEmpty) ? signed : null,
          assetImage: assetFallback,
          tag: r['tag']?.toString() ?? '',
          title: r['title']?.toString() ?? '',
          description: r['description']?.toString() ?? '',
        ),
      );
    }
    setState(() {
      _slides = slides;
      _currentPage = 0;
      _loading = false;
    });
    _schedule();
  }

  /// بعد كل تقليب — سواء تلقائياً أو بالسحب — نعيد العدّ من جديد
  /// حتى لا تقفز البطاقة والمستخدم ما زال يقرأها.
  void _schedule() {
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 5), () {
      if (!mounted || !_controller.hasClients || _slides.isEmpty) return;
      final next = (_currentPage + 1) % _slides.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
      );
    });
  }

  List<_HeroSlide> _fallbackSlides() {
    return [
      _HeroSlide(
        assetImage: AppAssets.homePromo[0],
        tag: 'الهدف',
        title: 'عالم متكامل من الخدمات',
        description:
            'خيارات متنوعة في مكان واحد، من الفكرة إلى التنفيذ.',
      ),
      _HeroSlide(
        assetImage: AppAssets.homePromo[1],
        tag: 'كيف يعمل',
        title: 'اختر خدماتك بكل سهولة',
        description:
            'اختر الخدمة، أرسل الطلب، وتابع الخطوات من تبويب طلباتي.',
      ),
      _HeroSlide(
        assetImage: AppAssets.homePromo[2],
        tag: 'الثقة',
        title: 'خيارات واضحة وتواصل مباشر',
        description:
            'الإدارة تراجع الطلبات قبل التأكيد حتى تبقى التفاصيل واضحة.',
      ),
      _HeroSlide(
        assetImage: AppAssets.homePromo[7],
        tag: 'التنسيق',
        title: 'نجمع لك التفاصيل لتستمتع بالتجربة',
        description:
            'أرسل طلبك وسنتابع معك الخطوات بهدوء ووضوح.',
      ),
      _HeroSlide(
        assetImage: AppAssets.homePromo[8],
        tag: 'الخدمات',
        title: 'اكتشف ما يناسب احتياجاتك',
        description:
            'تصفّح المزودين والباقات واطلب ما يناسبك.',
      ),
      _HeroSlide(
        assetImage: AppAssets.homePromo[9],
        tag: 'البداية',
        title: 'ابدأ من تبويب الخدمات',
        description:
            'أكمل بياناتك، ثم افتح الخدمات واطلب ما تحتاجه.',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_slides.isEmpty && !_loading) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 22,
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'لماذا GRAND ONE',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (_slides.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.goldSoft,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  '${_currentPage + 1} / ${_slides.length}',
                  textDirection: ui.TextDirection.ltr,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.goldDeep,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        const Padding(
          padding: EdgeInsets.only(right: 14),
          child: Text(
            'بطاقات عن آلية الحجز والتحقق والدفع',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 12.5,
              height: 1.35,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 300,
          child: PageView.builder(
            controller: _controller,
            itemCount: _slides.length,
            onPageChanged: (i) {
              setState(() => _currentPage = i);
              _schedule();
            },
            itemBuilder: (context, index) => _buildSlide(_slides[index], index),
          ),
        ),
        const SizedBox(height: 16),
        _buildIndicator(),
      ],
    );
  }

  Widget _buildSlideImage(_HeroSlide slide) {
    if (slide.imageUrl != null && slide.imageUrl!.isNotEmpty) {
      return Image.network(
        slide.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => slide.assetImage != null
            ? Image.asset(
                slide.assetImage!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const ColoredBox(
                  color: AppColors.primary,
                ),
              )
            : const ColoredBox(color: AppColors.primary),
      );
    }
    if (slide.assetImage != null) {
      return Image.asset(
        slide.assetImage!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const ColoredBox(
          color: AppColors.primary,
        ),
      );
    }
    return const ColoredBox(color: AppColors.primary);
  }

  Widget _buildSlide(_HeroSlide slide, int index) {
    final radius = BorderRadius.circular(22);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildSlideImage(slide),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x6603352E),
                    Color(0x1403352E),
                    Color(0xF003352E),
                  ],
                  stops: [0.0, 0.42, 1.0],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.goldLight.withValues(alpha: 0.55),
                          ),
                        ),
                        child: Text(
                          slide.tag,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.goldLight,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${index + 1}'.padLeft(2, '0'),
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    slide.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    slide.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14,
                      height: 1.45,
                      color: Colors.white.withValues(alpha: 0.94),
                      fontWeight: FontWeight.w500,
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

  Widget _buildIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_slides.length, (i) {
        final isActive = i == _currentPage;
        return GestureDetector(
          onTap: () {
            _controller.animateToPage(
              i,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 28 : 9,
            height: 9,
            decoration: BoxDecoration(
              gradient: isActive
                  ? LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                    )
                  : null,
              color: isActive ? null : AppColors.borderStrong,
              borderRadius: BorderRadius.circular(6),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.28),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
          ),
        );
      }),
    );
  }
}

class _HeroSlide {
  final String? imageUrl;
  final String? assetImage;
  final String tag;
  final String title;
  final String description;

  const _HeroSlide({
    this.imageUrl,
    this.assetImage,
    required this.tag,
    required this.title,
    required this.description,
  });
}
