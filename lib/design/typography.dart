// lib/design/typography.dart
// ============================================================
// الطباعة الموحّدة — GRAND ONE
// ============================================================
// أوزان حقيقية فقط من ملفات Tajawal: 300/400/500/700/800/900
// لا تستخدم w600 — يُصطنع ويبدو سيئاً.
// ============================================================

import 'package:flutter/material.dart';

import 'tokens.dart';

/// عائلة الخط الواحدة في التطبيق.
const String kFontFamily = 'Tajawal';

/// أوزان الخط المتاحة فعلياً كملفات في assets/fonts.
abstract final class FontWeights {
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;
  static const FontWeight black = FontWeight.w900;
}

/// الأنماط الدلالية الجاهزة — مقاسات صحيحة وتباين واضح.
abstract final class AppText {
  static const TextStyle display = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    height: 1.3,
    letterSpacing: 0,
    color: AppPalette.textPrimary,
  );

  static const TextStyle section = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.35,
    color: AppPalette.textPrimary,
  );

  static const TextStyle title = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.4,
    color: AppPalette.textPrimary,
  );

  static const TextStyle subtitle = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.45,
    color: AppPalette.textSecondary,
  );

  static const TextStyle body = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: AppPalette.textPrimary,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.55,
    color: AppPalette.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppPalette.textTertiary,
  );

  static const TextStyle micro = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.35,
    color: AppPalette.textTertiary,
  );

  static const TextStyle button = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );

  static const TextStyle number = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1.3,
    fontFeatures: [FontFeature.tabularFigures()],
    color: AppPalette.textPrimary,
  );

  static const TextStyle ayah = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.8,
    color: AppPalette.textPrimary,
  );
}

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
