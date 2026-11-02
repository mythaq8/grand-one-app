// lib/design/tokens.dart
// ============================================================
// رموز التصميم الموحّدة لميثاق (Design Tokens)
// ------------------------------------------------------------
// هذا الملف هو المصدر الوحيد لأي قيمة بصرية في التطبيق:
// ألوان، مسافات، زوايا، ظلال، مدد حركة، وأحجام أيقونات.
//
// القاعدة: لا تكتب قيمة لون أو مسافة أو زاوية مباشرة داخل شاشة.
// استعمل الرمز من هنا، أو استعمل TextStyle الثيم.
//
// ملاحظة توافق: AppColors (lib/app_colors.dart) يبقى موجوداً
// ويعيد التوجيه إلى هذه الرموز، حتى لا تنكسر الشاشات القديمة.
// ============================================================

import 'package:flutter/material.dart';

// ============================================================
// 1. الألوان
// ============================================================

/// لوحة الهوية: أخضر غامق + ذهبي + كريمي.
/// الأخضر = الحياة والنمو. الذهبي = القيمة والتراث. الكريمي = السكينة.
abstract final class AppPalette {
  // ── الأخضر (اللون الأساسي) ──
  static const Color green = Color(0xFF064E43);
  static const Color greenLight = Color(0xFF0A6B5C);
  static const Color greenLighter = Color(0xFF128A75);
  static const Color greenDark = Color(0xFF03352E);
  static const Color greenDeep = Color(0xFF022620);
  static const Color greenSoft = Color(0xFFE8F1EE);
  static const Color greenMuted = Color(0xFFB8D4CC);

  // ── الذهبي (لون التمييز) ──
  static const Color gold = Color(0xFFC6A15B);
  static const Color goldLight = Color(0xFFE3CC9A);
  static const Color goldLighter = Color(0xFFEFDFC0);
  static const Color goldDark = Color(0xFF9A7838);
  static const Color goldDeep = Color(0xFF6B5222);
  static const Color goldSoft = Color(0xFFF5EEDC);

  // ── الخلفيات والأسطح ──
  static const Color background = Color(0xFFFAF7F2);
  static const Color backgroundAlt = Color(0xFFF7F2EA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceTint = Color(0xFFF3EDE4);
  static const Color surfaceGreen = Color(0xFFF0F5F2);
  static const Color surfaceGold = Color(0xFFFBF6EC);

  // ── النصوص ──
  static const Color textPrimary = Color(0xFF1B332D);
  static const Color textSecondary = Color(0xFF4A5C56);
  static const Color textTertiary = Color(0xFF7A8A84);
  static const Color textMuted = Color(0xFF8A847C);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onGold = Color(0xFF332713);

  // ── الحدود والفواصل ──
  static const Color border = Color(0xFFE2D9CC);
  static const Color borderStrong = Color(0xFFD4C8B5);
  static const Color borderLight = Color(0xFFEDE7DE);
  static const Color borderSubtle = Color(0xFFF5F0E8);
  static const Color divider = Color(0xFFE8E1D8);

  // ── الحالات ──
  static const Color success = Color(0xFF2E7D5B);
  static const Color successLight = Color(0xFFE8F4ED);
  static const Color successDark = Color(0xFF1F5A40);

  static const Color warning = Color(0xFFD99A24);
  static const Color warningLight = Color(0xFFFFF5DE);
  static const Color warningDark = Color(0xFF9A6E18);

  static const Color error = Color(0xFFB3261E);
  static const Color errorLight = Color(0xFFFDECEA);
  static const Color errorDark = Color(0xFF7A1A14);

  static const Color info = Color(0xFF35758A);
  static const Color infoLight = Color(0xFFEAF4F7);
  static const Color infoDark = Color(0xFF234F5C);

  // ── الزخارف ──
  static const Color patternGold = Color(0x14C6A15B);
  static const Color patternGoldStrong = Color(0x28C6A15B);
  static const Color patternGreen = Color(0x0D064E43);
  static const Color patternGreenStrong = Color(0x1F064E43);
  static const Color patternBackground = Color(0xFFF7F1E8);
}

// ============================================================
// 2. التدرجات
// ============================================================

abstract final class AppGradients {
  static const LinearGradient primary = LinearGradient(
    colors: [AppPalette.green, AppPalette.greenLight],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );

  static const LinearGradient primaryDeep = LinearGradient(
    colors: [AppPalette.greenDark, AppPalette.green],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );

  static const LinearGradient header = LinearGradient(
    colors: [AppPalette.greenDark, AppPalette.green, AppPalette.greenLight],
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
    colors: [AppPalette.greenSoft, AppPalette.background],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient splash = LinearGradient(
    colors: [Color(0xFFFAF7F2), Color(0xFFF0E8DC), Color(0xFFFAF7F2)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

// ============================================================
// 3. المسافات — سلّم واحد بأسماء دلالية
// ============================================================
// استعمل هذا السلّم فقط. لا تكتب EdgeInsets.all(13) مثلاً؛
// اختر أقرب درجة من السلّم حتى تتنفّس الشاشات بإيقاع واحد.

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

  /// الحافة الأفقية القياسية لمحتوى الشاشة.
  static const double screenH = 16;

  /// حافة أعلى/أسفل المحتوى القابل للتمرير.
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

  /// ورقة سفلية (BottomSheet) — الزوايا العليا فقط.
  static const BorderRadius sheet = BorderRadius.vertical(
    top: Radius.circular(xl),
  );
}

// ============================================================
// 5. الظلال — كلها مشتقة من الأخضر لتبقى الهوية واحدة
// ============================================================

abstract final class AppShadows {
  static const List<BoxShadow> subtle = [
    BoxShadow(
      color: Color(0x0A064E43),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> soft = [
    BoxShadow(
      color: Color(0x0F064E43),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> medium = [
    BoxShadow(
      color: Color(0x14064E43),
      blurRadius: 18,
      offset: Offset(0, 6),
    ),
  ];

  static const List<BoxShadow> strong = [
    BoxShadow(
      color: Color(0x1F064E43),
      blurRadius: 24,
      offset: Offset(0, 10),
    ),
  ];

  static const List<BoxShadow> goldGlow = [
    BoxShadow(
      color: Color(0x40C6A15B),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];
}

// ============================================================
// 6. الحركة — مدة واحدة موحّدة حتى لا تتناقض الشاشات
// ============================================================

abstract final class Motion {
  /// تغيير حالة صغير (لون زر، ظهور شارة).
  static const Duration fast = Duration(milliseconds: 160);

  /// حركة قياسية (توسّع عنصر، تبديل تبويب).
  static const Duration normal = Duration(milliseconds: 240);

  /// انتقال كبير (صفحة، ورقة سفلية).
  static const Duration slow = Duration(milliseconds: 320);

  static const Curve curve = Curves.easeOutCubic;
  static const Curve curveInOut = Curves.easeInOutCubic;
}

// ============================================================
// 7. المقاسات الثابتة
// ============================================================

abstract final class Sizes {
  /// أقل ارتفاع لهدَف لمس مريح (معيار إتاحة).
  static const double touchTarget = 48;

  /// ارتفاع الزر الأساسي.
  static const double buttonHeight = 52;

  /// ارتفاع حقل الإدخال.
  static const double fieldHeight = 56;

  /// ارتفاع شريط التنقّل السفلي.
  static const double navBarHeight = 68;

  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double iconLg = 24;
  static const double iconXl = 32;

  /// أقصى عرض للمحتوى على الشاشات العريضة (لقراءة مريحة).
  static const double contentMax = 960;

  /// أقصى عرض لنموذج/نص طويل — أضيق من المحتوى العام.
  static const double formMax = 560;

  static const double avatarSm = 32;
  static const double avatarMd = 44;
  static const double avatarLg = 64;
  static const double avatarXl = 88;
}

// ============================================================
// 9. الأصول
// ============================================================

abstract final class AppAssets {
  /// شعار الخواتم والقبة (ذهبي بخلفية شفافة). لا تعرضه مباشرة
  /// بـ BoxFit.cover؛ استعمل BrandMark في lib/widgets/brand_mark.dart.
  /// الملف القديم assets/images/logo.png ما زال موجوداً ولم يُحذف.
  static const String logo = 'assets/images/brand/logo.png';

  static const String introCovenant =
      'assets/images/brand/intro-covenant.jpg';
  static const String introPath = 'assets/images/brand/intro-path.jpg';
  static const String introHall = 'assets/images/brand/intro-hall.jpg';

  /// خطوة 1 في الانترو: مشهد دمشق / زواج جاد (صورة عمودية بلا نص مدمج).
  static const String introDamascus = 'assets/images/brand/intro-damascus.jpg';

  /// بطاقات «لماذا ميثاق» على الشاشة الرئيسية (10 صور).
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
// 8. نقاط الكسر
// ============================================================

abstract final class Breakpoints {
  /// أقل من هذا العرض = هاتف.
  static const double compact = 600;

  /// بين compact و expanded = جهاز لوحي / نافذة متوسطة.
  static const double medium = 900;

  static const double expanded = 1200;
}
