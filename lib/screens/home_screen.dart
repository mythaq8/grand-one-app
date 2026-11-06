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
import '../design/typography.dart';
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
import 'services_screen.dart';
import 'service_detail_screen.dart';
import 'provider_details_screen.dart';
import 'services_user_profile_setup_screen.dart';
import '../services/search_date.dart';
import 'event/event_screen.dart';

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

  /// الفئات العامة التي تُتصفّح مباشرة (فئات التنظيم تظهر في مسار التخطيط)
  List<Map<String, dynamic>> _categories = [];
  bool _categoriesLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserData();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final all = await ApiService.getServiceCategories();
      if (!mounted) return;
      setState(() {
        _categories = all.where((c) => c['requires_organizer'] != true).toList();
        _categoriesLoading = false;
      });
    } catch (e) {
      debugPrint('Home categories error: $e');
      if (mounted) setState(() => _categoriesLoading = false);
    }
  }

  Future<void> _refreshHome() async {
    await Future.wait([_loadUserData(), _loadCategories()]);
  }

  void _openServices({String? categoryId}) {
    ServicesBrowse.categoryId.value = categoryId;
    if (widget.onOpenServicesTab != null) {
      widget.onOpenServicesTab!.call();
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ServicesScreen()),
      );
    }
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
                onRefresh: _refreshHome,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildWelcomeCard(),
                      const SizedBox(height: Space.xxl),
                      _buildCategoriesSection(),
                      const SizedBox(height: Space.xxl),
                      _buildPlanCard(),
                      const SizedBox(height: Space.xxl),
                      _buildHeroPages(),
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
          const BrandMark(size: 42),
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
                    fontSize: 17,
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
                    fontSize: 10.5,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
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
        borderRadius: BorderRadius.circular(24),
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
        borderRadius: Radii.brXl,
        boxShadow: AppColors.shadowMedium,
      ),
      child: ClipRRect(
        borderRadius: Radii.brXl,
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: GeometricPatternPainter(
                    color: AppColors.gold.withValues(alpha: 0.07),
                    spacing: 44,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Space.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      _buildPersonAvatar(size: 44),
                      const SizedBox(width: Space.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              greeting,
                              style: AppText.caption.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            Text(
                              _isLoading ? '...' : _userName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.section.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 19,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Space.md),
                  Text(
                    UiCopy.homeHeroTitle,
                    style: AppText.bodySecondary.copyWith(
                      color: Colors.white.withValues(alpha: 0.86),
                    ),
                  ),
                  const SizedBox(height: Space.md),
                  _buildSearchPill(),
                  const SizedBox(height: Space.sm),
                  _buildDatePill(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// يبدو حقل بحث ويفتح تبويب الخدمات حيث البحث الفعلي
  Widget _buildSearchPill() {
    return Material(
      color: AppPalette.surface,
      borderRadius: Radii.brMd,
      child: InkWell(
        borderRadius: Radii.brMd,
        onTap: () => _openServices(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: 13),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: AppPalette.navy, size: 21),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Text(
                  'ابحث عن قاعة، مصوّر، خدمة...',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.subtitle.copyWith(color: AppPalette.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePill() {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: Radii.brMd,
      child: InkWell(
        borderRadius: Radii.brMd,
        onTap: _pickEventDate,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: 11),
          child: Row(
            children: [
              const Icon(Icons.event_outlined, color: AppPalette.goldLight, size: 20),
              const SizedBox(width: Space.sm),
              Expanded(
                child: ValueListenableBuilder<DateTime?>(
                  valueListenable: SearchDate.date,
                  builder: (_, d, _) => Text(
                    d == null ? 'متى مناسبتك؟ اختر التاريخ' : 'مناسبتك: ${SearchDate.iso ?? ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.subtitle.copyWith(color: Colors.white),
                  ),
                ),
              ),
              Icon(Icons.chevron_left_rounded, color: Colors.white.withValues(alpha: 0.7), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  IconData _categoryIcon(String name) {
    if (name.contains('قاع')) return Icons.account_balance_outlined;
    if (name.contains('تصوير') && !name.contains('منع')) return Icons.photo_camera_outlined;
    if (name.contains('عراض')) return Icons.music_note_outlined;
    if (name.contains('تخديم') || name.contains('حماية')) return Icons.groups_outlined;
    return Icons.storefront_outlined;
  }

  Widget _buildCategoriesSection() {
    if (!_categoriesLoading && _categories.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text('تصفّح الخدمات', style: AppText.section.copyWith(fontSize: 18))),
            TextButton(
              onPressed: () => _openServices(),
              child: const Text('عرض الكل'),
            ),
          ],
        ),
        const SizedBox(height: Space.xs),
        LayoutBuilder(
          builder: (context, c) {
            final columns = c.maxWidth >= 700 ? 4 : 2;
            final itemWidth = (c.maxWidth - Space.sm * (columns - 1)) / columns;
            final items = _categoriesLoading
                ? List<Map<String, dynamic>?>.filled(4, null)
                : _categories.cast<Map<String, dynamic>?>();
            return Wrap(
              spacing: Space.sm,
              runSpacing: Space.sm,
              children: [
                for (final cat in items)
                  SizedBox(width: itemWidth, child: _buildCategoryTile(cat)),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryTile(Map<String, dynamic>? cat) {
    final name = cat?['name']?.toString() ?? '';
    return SizedBox(
      height: 96,
      child: Material(
        color: AppPalette.surface,
        borderRadius: Radii.brMd,
        child: InkWell(
          borderRadius: Radii.brMd,
          onTap: cat == null ? null : () => _openServices(categoryId: cat['id']?.toString()),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: Radii.brMd,
              border: Border.all(color: AppPalette.borderLight),
              boxShadow: AppShadows.subtle,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.sm),
              child: cat == null
                  ? const SizedBox.expand()
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: AppPalette.navySoft,
                            borderRadius: Radii.brSm,
                          ),
                          child: Icon(_categoryIcon(name), size: 21, color: AppPalette.navy),
                        ),
                        const SizedBox(height: Space.xs + 2),
                        Text(
                          name,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.title.copyWith(fontSize: 13, height: 1.25),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  /// مدخل التخطيط الكامل: طلب واحد لكل خدمات المناسبة عبر منظّم
  Widget _buildPlanCard() {
    return Material(
      color: AppPalette.surface,
      borderRadius: Radii.brLg,
      child: InkWell(
        borderRadius: Radii.brLg,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const EventScreen()),
        ),
        child: Ink(
          padding: const EdgeInsets.all(Space.lg),
          decoration: BoxDecoration(
            borderRadius: Radii.brLg,
            border: Border.all(color: AppPalette.gold.withValues(alpha: 0.5)),
            gradient: const LinearGradient(
              colors: [AppPalette.goldSoft, AppPalette.surface],
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppPalette.navy,
                  borderRadius: Radii.brSm,
                ),
                child: const Icon(Icons.celebration_outlined, color: AppPalette.goldLight),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('نظّم مناسبتك كاملة', style: AppText.title),
                    const SizedBox(height: 2),
                    Text(
                      'قاعة وتصوير وديكور وضيافة في طلب واحد، مع منظّم يتابع كل التفاصيل.',
                      style: AppText.bodySecondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Space.sm),
              const Icon(Icons.chevron_left_rounded, color: AppPalette.navy),
            ],
          ),
        ),
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
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: _logout,
                borderRadius: BorderRadius.circular(16),
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
                fontSize: 11,
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
                        fontSize: 16,
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
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'حساب عميل',
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
              fontWeight: FontWeight.w700,
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
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, size: 19, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
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
    var rows = <Map<String, dynamic>>[];
    var ads = <Map<String, dynamic>>[];
    // كل مصدر مستقل: فشل أحدهما لا يُسقط الآخر
    await Future.wait([
      ApiService.getHomePromoCards().then((v) => rows = v).catchError(
            (_) => rows = <Map<String, dynamic>>[],
          ),
      ApiService.getAdvertisements().then((v) => ads = v).catchError(
            (_) => ads = <Map<String, dynamic>>[],
          ),
    ]);
    if (!mounted) return;

    // الإعلانات النشطة أولاً في مربع الصور
    final adSlides = <_HeroSlide>[];
    for (final ad in ads) {
      final signed = (ad['signed_url'] ?? ad['image_url'])?.toString().trim();
      final title = ad['title']?.toString().trim() ?? '';
      final description = ad['description']?.toString().trim() ?? '';
      adSlides.add(
        _HeroSlide(
          imageUrl: (signed != null && signed.isNotEmpty) ? signed : null,
          tag: 'إعلان',
          title: title.isNotEmpty ? title : 'عرض مميّز',
          description: description,
          targetType: ad['target_type']?.toString() ?? 'ad',
          serviceId: ad['service_id']?.toString(),
          providerId: ad['provider_id']?.toString(),
        ),
      );
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
    final promo = slides.isEmpty ? _fallbackSlides() : slides;
    setState(() {
      _slides = [...adSlides, ...promo];
      _currentPage = 0;
      _loading = false;
    });
    if (_controller.hasClients) _controller.jumpToPage(0);
    _schedule();
  }

  void _openAd(_HeroSlide slide) {
    final serviceId = slide.serviceId;
    final providerId = slide.providerId;
    if (slide.targetType == 'service' &&
        serviceId != null &&
        serviceId.isNotEmpty &&
        serviceId != 'null') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ServiceDetailScreen(serviceId: serviceId)),
      );
    } else if (slide.targetType == 'provider' &&
        providerId != null &&
        providerId.isNotEmpty &&
        providerId != 'null') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProviderDetailsScreen(providerId: providerId)),
      );
    }
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
            'اختر الخدمة وتاريخ مناسبتك، ويردّ المزوّد خلال 24 ساعة.',
      ),
      _HeroSlide(
        assetImage: AppAssets.homePromo[2],
        tag: 'الثقة',
        title: 'عربون واضح وتواصل بعد التأكيد',
        description:
            'تدفع العربون بعد قبول المزوّد، وتصلك أرقام التواصل بعد تأكيده.',
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
        Text('لماذا GRAND ONE', style: AppText.section.copyWith(fontSize: 18)),
        const SizedBox(height: Space.sm),
        SizedBox(
          height: 196,
          child: PageView.builder(
            controller: _controller,
            itemCount: _slides.length,
            onPageChanged: (i) {
              setState(() => _currentPage = i);
              _schedule();
            },
            itemBuilder: (context, index) {
              final slide = _slides[index];
              final card = _buildSlide(slide, index);
              if (!slide.isAd) return card;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _openAd(slide),
                child: card,
              );
            },
          ),
        ),
        const SizedBox(height: Space.sm),
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
    final radius = Radii.brLg;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: AppShadows.soft,
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
                    Color(0x33060F20),
                    Color(0x14060F20),
                    Color(0xE6060F20),
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
                          // خلفية داكنة لتبقى الشارة مقروءة فوق الصور الفاتحة
                          color: AppPalette.navyDeep.withValues(alpha: 0.62),
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
                    ],
                  ),
                  const Spacer(),
                  Text(
                    slide.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 18,
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
                      fontSize: 13,
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
            width: isActive ? 22 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : AppColors.borderStrong,
              borderRadius: BorderRadius.circular(6),
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

  /// للإعلانات فقط: عند النقر تُفتح الخدمة أو المزوّد
  final String? targetType;
  final String? serviceId;
  final String? providerId;

  const _HeroSlide({
    this.imageUrl,
    this.assetImage,
    required this.tag,
    required this.title,
    required this.description,
    this.targetType,
    this.serviceId,
    this.providerId,
  });

  bool get isAd => targetType != null;
}
