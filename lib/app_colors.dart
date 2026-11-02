// lib/app_colors.dart
// ============================================================
// واجهة توافق (Compatibility Facade)
// ------------------------------------------------------------
// هذا الملف لم يعد مصدر الألوان. المصدر الآن:
// lib/design/tokens.dart
//
// سبب إبقائه: أكثر من 1400 موضع في الشاشات تستخدم AppColors.
// إعادة تسميتها كلها في خطوة واحدة خطر بلا فائدة. فبدل ذلك
// صار كل اسم هنا يقرأ من الرموز الجديدة مباشرة، فيبقى سلوك
// الشاشات كما هو، ويصبح تغيير الهوية لاحقاً من مكان واحد.
//
// القاعدة الجديدة: الكود الجديد يستعمل AppPalette / AppGradients
// / Space / Radii / AppShadows من lib/design/tokens.dart.
// ============================================================

import 'package:flutter/material.dart';

import 'design/tokens.dart';

abstract final class AppColors {
  // ── الأخضر ──
  static const Color primary = AppPalette.green;
  static const Color primaryLight = AppPalette.greenLight;
  static const Color primaryLighter = AppPalette.greenLighter;
  static const Color primaryDark = AppPalette.greenDark;
  static const Color primaryDeep = AppPalette.greenDeep;
  static const Color primarySoft = AppPalette.greenSoft;
  static const Color primaryMuted = AppPalette.greenMuted;

  // ── الذهبي ──
  static const Color gold = AppPalette.gold;
  static const Color goldLight = AppPalette.goldLight;
  static const Color goldLighter = AppPalette.goldLighter;
  static const Color goldDark = AppPalette.goldDark;
  static const Color goldDeep = AppPalette.goldDeep;
  static const Color goldSoft = AppPalette.goldSoft;

  // ── ألوان الأدوار ──
  static const Color groomAccent = primary;
  static const Color groomAccentLight = primaryLight;
  static const Color groomAccentSoft = primarySoft;

  static const Color brideAccent = Color(0xFF3D6B5C);
  static const Color brideAccentLight = Color(0xFF55877A);
  static const Color brideAccentSoft = Color(0xFFE5EFEA);

  static const Color adminAccent = Color(0xFF8B5A5A);
  static const Color adminAccentLight = Color(0xFFA87878);
  static const Color adminAccentSoft = Color(0xFFF5EBEB);

  // ── الخلفيات والأسطح ──
  static const Color background = AppPalette.background;
  static const Color backgroundAlt = AppPalette.backgroundAlt;
  static const Color surface = AppPalette.surface;
  static const Color surfaceTint = AppPalette.surfaceTint;
  static const Color surfaceElevated = AppPalette.surface;
  static const Color surfaceGreen = AppPalette.surfaceGreen;
  static const Color surfaceGold = AppPalette.surfaceGold;

  // ── النصوص ──
  static const Color textPrimary = AppPalette.textPrimary;
  static const Color textSecondary = AppPalette.textSecondary;
  static const Color textTertiary = AppPalette.textTertiary;
  static const Color mutedText = AppPalette.textMuted;
  static const Color textOnPrimary = AppPalette.onPrimary;
  static const Color textOnGold = AppPalette.onGold;
  static const Color textOnDark = Color(0xFFF5F5F5);

  // ── الحدود ──
  static const Color border = AppPalette.border;
  static const Color borderStrong = AppPalette.borderStrong;
  static const Color borderLight = AppPalette.borderLight;
  static const Color borderSubtle = AppPalette.borderSubtle;
  static const Color divider = AppPalette.divider;

  // ── الحالات ──
  static const Color success = AppPalette.success;
  static const Color successLight = AppPalette.successLight;
  static const Color successDark = AppPalette.successDark;

  static const Color warning = AppPalette.warning;
  static const Color warningLight = AppPalette.warningLight;
  static const Color warningDark = AppPalette.warningDark;

  static const Color error = AppPalette.error;
  static const Color errorLight = AppPalette.errorLight;
  static const Color errorDark = AppPalette.errorDark;

  static const Color info = AppPalette.info;
  static const Color infoLight = AppPalette.infoLight;
  static const Color infoDark = AppPalette.infoDark;

  // ── الزخارف ──
  static const Color patternGold = AppPalette.patternGold;
  static const Color patternGoldStrong = AppPalette.patternGoldStrong;
  static const Color patternGreen = AppPalette.patternGreen;
  static const Color patternGreenStrong = AppPalette.patternGreenStrong;
  static const Color patternBackground = AppPalette.patternBackground;

  // ── التدرجات ──
  static const LinearGradient primaryGradient = AppGradients.primary;
  static const LinearGradient primaryGradientDeep = AppGradients.primaryDeep;
  static const LinearGradient goldGradient = AppGradients.gold;
  static const LinearGradient goldGradientSoft = AppGradients.goldSoft;
  static const LinearGradient primarySoftGradient = AppGradients.primarySoft;
  static const LinearGradient splashGradient = AppGradients.splash;
  static const LinearGradient headerGradient = AppGradients.header;

  static const LinearGradient brideGradient = LinearGradient(
    colors: [brideAccent, brideAccentLight],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );

  // ── الظلال ──
  static List<BoxShadow> get shadowSubtle => AppShadows.subtle;
  static List<BoxShadow> get shadowSoft => AppShadows.soft;
  static List<BoxShadow> get shadowMedium => AppShadows.medium;
  static List<BoxShadow> get shadowStrong => AppShadows.strong;
  static List<BoxShadow> get goldGlow => AppShadows.goldGlow;

  // ── أنصاف الأقطار ──
  static const double radiusXs = Radii.xs;
  static const double radiusSm = Radii.sm;
  static const double radiusMd = Radii.md;
  static const double radiusLg = Radii.lg;
  static const double radiusXl = Radii.xl;
  static const double radiusRound = Radii.pill;

  // ── المسافات ──
  static const double spaceXs = Space.xs;
  static const double spaceSm = Space.sm;
  static const double spaceMd = Space.md;
  static const double spaceLg = Space.lg;
  static const double spaceXl = Space.xl;
  static const double space2xl = Space.xxl;
  static const double space3xl = Space.xxxl;
}
