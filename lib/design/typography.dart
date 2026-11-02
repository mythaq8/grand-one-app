// lib/design/typography.dart
// ============================================================
// الطباعة الموحّدة — GRAND ONE
// ------------------------------------------------------------
// سبب وجود الملف:
//   الثيم السابق يستخدم w600 و w700 بكثافة، لكن pubspec كان
//   يعرّف 200/300/500/800/900 فقط، فيُصطنع الخط (synthetic bold)
//   ويبدو غير متناسق. أضفنا Tajawal-Regular (400) و
//   Tajawal-Bold (700) فصار لكل وزن ملف حقيقي.
//
//   وأيضاً: كان هناك 509 TextStyle مكتوباً داخل الشاشات.
//   هنا الأنماط الدلالية: استعمل AppText.title بدل
//   TextStyle(fontSize: 18, fontWeight: ...).
// ============================================================

import 'package:flutter/material.dart';

import 'tokens.dart';

/// عائلة الخط الواحدة في التطبيق.
const String kFontFamily = 'Tajawal';

/// أوزان الخط المتاحة فعلياً كملفات في assets/fonts.
/// لا تستعمل وزناً خارج هذه القائمة، وإلا عاد الاصطناع.
abstract final class FontWeights {
  static const FontWeight light = FontWeight.w300;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;
  static const FontWeight black = FontWeight.w900;
}

/// الأنماط الدلالية الجاهزة.
///
/// كلها بلا لون افتراضي حتى ترث لون النص من السياق
/// (وهذا أفضل من تثبيت لون يجعل النص غير مقروء على خلفية غامقة).
abstract final class AppText {
  // ── العناوين ──

  /// عنوان الشاشة الرئيسي (نادراً ما يُستخدم داخل الصفحة).
  static const TextStyle display = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 30,
    fontWeight: FontWeight.w800,
    height: 1.25,
    letterSpacing: -0.2,
  );

  /// عنوان قسم كبير داخل صفحة.
  static const TextStyle section = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 21,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  /// عنوان بطاقة.
  static const TextStyle title = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 16.5,
    fontWeight: FontWeight.w700,
    height: 1.35,
  );

  /// عنوان فرعي صغير.
  static const TextStyle subtitle = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 14.5,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  // ── النصوص ──

  /// نص أساسي للقراءة.
  static const TextStyle body = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 14.5,
    fontWeight: FontWeight.w400,
    height: 1.55,
  );

  /// نص ثانوي: شرح، وصف بطاقة.
  static const TextStyle bodySecondary = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 13.5,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppPalette.textSecondary,
  );

  /// تسمية صغيرة: تحت أيقونة، فوق حقل.
  static const TextStyle caption = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppPalette.textTertiary,
  );

  /// أصغر نص: طوابع الحالة، العدّادات.
  static const TextStyle micro = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  // ── الأزرار ──

  static const TextStyle button = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 15.5,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 13.5,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  /// نمط الأرقام (أسعار، عدّادات) — بلا حشوة اختلاف.
  static const TextStyle number = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1.3,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  // ── نص الآيات ──

  static const TextStyle ayah = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 16.5,
    fontWeight: FontWeight.w500,
    height: 2.1,
  );
}

/// يحوّل أنماط AppText إلى TextTheme لتُزرع في ThemeData،
/// وتعمل تلقائياً لأي Text لم نضبط نمطه.
abstract final class AppTextTheme {
  static const TextTheme textTheme = TextTheme(
    displayLarge: AppText.display,
    displayMedium: AppText.display,
    displaySmall: AppText.section,

    headlineLarge: AppText.section,
    headlineMedium: AppText.section,
    headlineSmall: AppText.title,

    titleLarge: AppText.title,
    titleMedium: AppText.subtitle,
    titleSmall: AppText.subtitle,

    bodyLarge: AppText.body,
    bodyMedium: AppText.body,
    bodySmall: AppText.bodySecondary,

    labelLarge: AppText.button,
    labelMedium: AppText.caption,
    labelSmall: AppText.micro,
  );
}
