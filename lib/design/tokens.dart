// lib/design/tokens.dart
// ============================================================
// رموز التصميم الموحّدة — GRAND ONE
// ============================================================
// المصدر الوحيد للقيم البصرية: ألوان، مسافات، زوايا، ظلال، حركة.
// الكود الجديد يستعمل AppPalette / Space / Radii / AppShadows.
// AppColors يعيد التوجيه إلى هنا للتوافق.
// ============================================================

import 'package:flutter/material.dart';

// ============================================================
// 1. الألوان — GRAND ONE
// ============================================================

/// Navy مهيمن + ذهب للتمييز + كريمي للتنفّس + رمادي فاخر.
abstract final class AppPalette {
  // ── Navy (اللون الأساسي) ──
  static const Color navy = Color(0xFF0B1E44);
  static const Color navyLight = Color(0xFF16325F);
  static const Color navyLighter = Color(0xFF234575);
  static const Color navyDark = Color(0xFF132033);
  static const Color navyDeep = Color(0xFF0A1528);
  static const Color navySoft = Color(0xFFE8ECF3);
  static const Color navyMuted = Color(0xFF9AA8C0);

  // توافق أسماء قديمة (كانت green) → navy
  static const Color green = navy;
  static const Color greenLight = navyLight;
  static const Color greenLighter = navyLighter;
  static const Color greenDark = navyDark;
  static const Color greenDeep = navyDeep;
  static const Color greenSoft = navySoft;
  static const Color greenMuted = navyMuted;

  // ── الذهبي الملكي (تمييز فقط) ──
  static const Color gold = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFE5C96A);
  static const Color goldLighter = Color(0xFFF0DF9A);
  static const Color goldDark = Color(0xFFB8942D);
  static const Color goldDeep = Color(0xFF8A6F1F);
  static const Color goldSoft = Color(0xFFF8F1DC);

  // ── الخلفيات والأسطح ──
  static const Color cream = Color(0xFFF8F5ED);
  static const Color background = cream;
  static const Color backgroundAlt = Color(0xFFF3EFE6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceTint = Color(0xFFF1EEE6);
  static const Color surfaceNavy = Color(0xFFF0F3F8);
  static const Color surfaceGreen = surfaceNavy;
  static const Color surfaceGold = Color(0xFFFBF7EC);

  // ── رمادي فاخر ──
  static const Color luxuryGray = Color(0xFF9FA3A8);
  static const Color luxuryGrayDark = Color(0xFF6E737A);
  static const Color luxuryGrayLight = Color(0xFFD5D8DC);

  // ── النصوص ──
  static const Color textPrimary = Color(0xFF132033);
  static const Color textSecondary = Color(0xFF4A5563);
  static const Color textTertiary = Color(0xFF7A8490);
  static const Color textMuted = luxuryGray;
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onGold = Color(0xFF1A1508);
  static const Color onNavy = Color(0xFFF8F5ED);

  // ── الحدود والفواصل ──
  static const Color border = Color(0xFFE0DCD3);
  static const Color borderStrong = Color(0xFFCFCABF);
  static const Color borderLight = Color(0xFFEBE7DE);
  static const Color borderSubtle = Color(0xFFF3F0E9);
  static const Color divider = Color(0xFFE6E2D9);

  // ── الحالات ──
  static const Color success = Color(0xFF2F6B4F);
  static const Color successLight = Color(0xFFE8F4ED);
  static const Color successDark = Color(0xFF1F4A36);

  static const Color warning = Color(0xFFC4922A);
  static const Color warningLight = Color(0xFFFFF6E0);
  static const Color warningDark = Color(0xFF8A6718);

  static const Color error = Color(0xFFB3261E);
  static const Color errorLight = Color(0xFFFDECEA);
  static const Color errorDark = Color(0xFF7A1A14);

  static const Color info = Color(0xFF3A6280);
  static const Color infoLight = Color(0xFFEAF2F7);
  static const Color infoDark = Color(0xFF274358);

  // ── الزخارف ──
  static const Color patternGold = Color(0x14D4AF37);
  static const Color patternGoldStrong = Color(0x28D4AF37);
  static const Color patternNavy = Color(0x0D0B1E44);
  static const Color patternNavyStrong = Color(0x1F0B1E44);
  static const Color patternGreen = patternNavy;
  static const Color patternGreenStrong = patternNavyStrong;
  static const Color patternBackground = Color(0xFFF5F1E8);
}

// ============================================================
// 2. التدرجات
// ============================================================

abstract final class AppGradients {
  static const LinearGradient primary = LinearGradient(
    colors: [AppPalette.navy, AppPalette.navyLight],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );

  static const LinearGradient primaryDeep = LinearGradient(
    colors: [AppPalette.navyDeep, AppPalette.navy],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );

  static const LinearGradient header = LinearGradient(
    colors: [AppPalette.navyDark, AppPalette.navy, AppPalette.navyLight],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );

  static const LinearGradient gold = LinearGradient(
    colors: [AppPalette.goldDark, AppPalette.gold, AppPalette.goldLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldSoft = LinearGradient(
    colors: [AppPalette.goldSoft, AppPalette.goldLighter],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primarySoft = LinearGradient(
    colors: [AppPalette.navySoft, AppPalette.background],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient splash = LinearGradient(
    colors: [AppPalette.navyDeep, AppPalette.navy, AppPalette.navyDark],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

// ============================================================
// 3. المسافات
// ============================================================

abstract final class Space {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;
  static const double giant = 48;

  static const double screenH = 16;
  static const double screenV = 16;
}

// ============================================================
// 4. الزوايا
// ============================================================

abstract final class Radii {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 28;
  static const double pill = 100;

  static const BorderRadius brXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius brSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius brMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius brLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius brXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius brPill = BorderRadius.all(Radius.circular(pill));

  static const BorderRadius sheet = BorderRadius.vertical(
    top: Radius.circular(xl),
  );
}

// ============================================================
// 5. الظلال — مشتقة من Navy
// ============================================================

abstract final class AppShadows {
  static const List<BoxShadow> subtle = [
    BoxShadow(
      color: Color(0x0A0B1E44),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> soft = [
    BoxShadow(
      color: Color(0x0F0B1E44),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> medium = [
    BoxShadow(
      color: Color(0x140B1E44),
      blurRadius: 18,
      offset: Offset(0, 6),
    ),
  ];

  static const List<BoxShadow> strong = [
    BoxShadow(
      color: Color(0x1F0B1E44),
      blurRadius: 24,
      offset: Offset(0, 10),
    ),
  ];

  static const List<BoxShadow> goldGlow = [
    BoxShadow(
      color: Color(0x33D4AF37),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];
}

// ============================================================
// 6. الحركة
// ============================================================

abstract final class Motion {
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration normal = Duration(milliseconds: 240);
  static const Duration slow = Duration(milliseconds: 320);
  static const Duration splash = Duration(milliseconds: 900);

  static const Curve curve = Curves.easeOutCubic;
  static const Curve curveInOut = Curves.easeInOutCubic;
}

// ============================================================
// 7. المقاسات
// ============================================================

abstract final class Sizes {
  static const double touchTarget = 48;
  static const double buttonHeight = 52;
  static const double fieldHeight = 56;
  static const double navBarHeight = 68;

  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double iconLg = 24;
  static const double iconXl = 32;

  static const double contentMax = 960;
  static const double formMax = 560;

  static const double avatarSm = 32;
  static const double avatarMd = 44;
  static const double avatarLg = 64;
  static const double avatarXl = 88;
}

// ============================================================
// 8. الأصول
// ============================================================

abstract final class AppAssets {
  /// رمز G1 وحده — أيقونة، سبلاش مضغوط، مواضع صغيرة.
  static const String monogram = 'assets/images/brand/g1-monogram.png';

  /// الشعار الكامل مع الاسم والشعار التسويقي (خلفيات Navy).
  static const String lockup = 'assets/images/brand/grand-one-lockup.png';

  /// المسار الافتراضي للشعار في الواجهة.
  static const String logo = monogram;

  /// شعار ميثاق القديم — لا تستخدمه في واجهة GRAND ONE.
  static const String legacyMithaqLogo = 'assets/images/brand/logo.png';

  static const String introCovenant =
      'assets/images/brand/intro-covenant.jpg';
  static const String introPath = 'assets/images/brand/intro-path.jpg';
  static const String introHall = 'assets/images/brand/intro-hall.jpg';
  static const String introDamascus = 'assets/images/brand/intro-damascus.jpg';

  static const List<String> homePromo = [
    'assets/images/brand/promo/promo-01.jpg',
    'assets/images/brand/promo/promo-02.jpg',
    'assets/images/brand/promo/promo-03.jpg',
    'assets/images/brand/promo/promo-04.jpg',
    'assets/images/brand/promo/promo-05.jpg',
    'assets/images/brand/promo/promo-06.jpg',
    'assets/images/brand/promo/promo-07.jpg',
    'assets/images/brand/promo/promo-08.jpg',
    'assets/images/brand/promo/promo-09.jpg',
    'assets/images/brand/promo/promo-10.jpg',
  ];
}

// ============================================================
// 9. نقاط الكسر
// ============================================================

abstract final class Breakpoints {
  static const double compact = 600;
  static const double medium = 900;
  static const double expanded = 1200;
}
