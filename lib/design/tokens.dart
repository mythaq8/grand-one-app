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

/// Navy مهيمن + ذهب خفيف للتمييز + خلفية باردة نظيفة.
abstract final class AppPalette {
  // ── Navy (اللون الأساسي) ──
  static const Color navy = Color(0xFF0B1E44);
  static const Color navyLight = Color(0xFF1A335F);
  static const Color navyLighter = Color(0xFF2A4570);
  static const Color navyDark = Color(0xFF08162F);
  static const Color navyDeep = Color(0xFF060F20);
  static const Color navySoft = Color(0xFFEEF2F7);
  static const Color navyMuted = Color(0xFF8B9BB3);

  // توافق أسماء قديمة (كانت green) → navy
  static const Color green = navy;
  static const Color greenLight = navyLight;
  static const Color greenLighter = navyLighter;
  static const Color greenDark = navyDark;
  static const Color greenDeep = navyDeep;
  static const Color greenSoft = navySoft;
  static const Color greenMuted = navyMuted;

  // ── الذهبي (لمسات رفيعة فقط — ليس لوناً كبيراً) ──
  static const Color gold = Color(0xFFC6A35A);
  static const Color goldLight = Color(0xFFD8BC7E);
  static const Color goldLighter = Color(0xFFE8D7AE);
  static const Color goldDark = Color(0xFF86672A);
  static const Color goldDeep = Color(0xFF7D6430);
  static const Color goldSoft = Color(0xFFF7F2E8);

  // ── الخلفيات والأسطح (باردة ونظيفة، بلا اصفرار) ──
  static const Color cream = Color(0xFFF7F2E8);
  static const Color background = Color(0xFFF5F7FA);
  static const Color backgroundAlt = Color(0xFFEEF1F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceTint = Color(0xFFF0F3F7);
  static const Color surfaceNavy = Color(0xFFE9EEF5);
  static const Color surfaceGreen = surfaceNavy;
  static const Color surfaceGold = Color(0xFFF8F4EC);

  // ── رمادي فاخر ──
  static const Color luxuryGray = Color(0xFF8B929C);
  static const Color luxuryGrayDark = Color(0xFF5C6470);
  static const Color luxuryGrayLight = Color(0xFFD0D5DC);

  // ── النصوص ──
  static const Color textPrimary = Color(0xFF121A2A);
  static const Color textSecondary = Color(0xFF5A6575);
  static const Color textTertiary = Color(0xFF667082);
  static const Color textMuted = Color(0xFF6B7686);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onGold = Color(0xFF1A1508);
  static const Color onNavy = Color(0xFFF5F7FA);

  // ── الحدود والفواصل ──
  static const Color border = Color(0xFFD8DEE6);
  static const Color borderStrong = Color(0xFFC2CAD6);
  static const Color borderLight = Color(0xFFE6EBF1);
  static const Color borderSubtle = Color(0xFFF0F3F7);
  static const Color divider = Color(0xFFE2E7EE);

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
  static const Color patternGold = Color(0x0FC6A35A);
  static const Color patternGoldStrong = Color(0x1AC6A35A);
  static const Color patternNavy = Color(0x080B1E44);
  static const Color patternNavyStrong = Color(0x120B1E44);
  static const Color patternGreen = patternNavy;
  static const Color patternGreenStrong = patternNavyStrong;
  static const Color patternBackground = Color(0xFFF5F7FA);
}

// ============================================================
// 2. التدرجات
// ============================================================

abstract final class AppGradients {
  /// لمعان معدني على الأسطح الداكنة.
  static const LinearGradient sheen = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2A5694),
      Color(0xFF0B1E44),
      Color(0xFF1A3A6E),
      Color(0xFF071428),
    ],
    stops: [0.0, 0.38, 0.72, 1.0],
  );

  static const LinearGradient primary = sheen;

  static const LinearGradient primaryDeep = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF16325F), AppPalette.navyDeep, Color(0xFF0B1E44)],
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient header = sheen;

  /// ذهب مصقول: ظل، لمعة، ثم ظل.
  static const LinearGradient gold = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF8A682C),
      Color(0xFFE8D5A3),
      Color(0xFFC6A35A),
      Color(0xFFFFF1CC),
      Color(0xFFA8863F),
    ],
    stops: [0.0, 0.22, 0.48, 0.68, 1.0],
  );

  static const LinearGradient goldSoft = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFBF2), Color(0xFFF4E6C4), Color(0xFFFFF8EA)],
  );

  /// صفحة فاتحة مع دفء ذهبي في الأعلى.
  static const LinearGradient primarySoft = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFF6E4),
      Color(0xFFF8F4EC),
      Color(0xFFF4F7FB),
    ],
    stops: [0.0, 0.32, 1.0],
  );

  static const RadialGradient glowGold = RadialGradient(
    colors: [Color(0x66E8D5A3), Color(0x00E8D5A3)],
  );

  static const RadialGradient glowNavy = RadialGradient(
    colors: [Color(0x261A335F), Color(0x001A335F)],
  );

  static const LinearGradient splash = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A3A6E), AppPalette.navyDeep, Color(0xFF0B1E44)],
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
      color: Color(0x40C6A35A),
      blurRadius: 18,
      offset: Offset(0, 6),
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

  /// بطاقات ترويجية للرئيسية (fallback عند غياب الـ API).
  static const List<String> homePromo = [
    'assets/images/brand/promo/promo-01.jpg',
    'assets/images/brand/promo/promo-02.jpg',
    'assets/images/brand/promo/promo-03.jpg',
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
