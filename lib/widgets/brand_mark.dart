// lib/widgets/brand_mark.dart
// ============================================================
// BrandMark — رمز G1 المعتمد لـ GRAND ONE
// ============================================================
// لا تشوّه الشعار ولا تعيد تلوينه. استخدم النسخ الرسمية فقط.
// ============================================================

import 'package:flutter/material.dart';

import '../design/tokens.dart';

enum BrandMarkVariant {
  /// رمز G1 وحده (خلفية Navy داخل الأصل).
  monogram,

  /// الشعار الكامل مع الاسم والشعار العربي.
  lockup,
}

class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.size = 40,
    this.onDark = false,
    this.framed = true,
    this.variant = BrandMarkVariant.monogram,
  });

  /// الضلع الخارجي للرمز (مربع). للـ lockup يُستخدم كارتفاع تقريبي.
  final double size;

  /// true فوق خلفية Navy (إطار ذهبي أوضح).
  final bool onDark;

  /// false = الشعار وحده بلا إطار.
  final bool framed;

  final BrandMarkVariant variant;

  String get _asset => switch (variant) {
        BrandMarkVariant.monogram => AppAssets.monogram,
        BrandMarkVariant.lockup => AppAssets.lockup,
      };

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final isLockup = variant == BrandMarkVariant.lockup;
    final width = isLockup ? size * 2.4 : size;
    final height = size;
    final innerW = framed && !isLockup ? size * 0.82 : width;
    final innerH = framed && !isLockup ? size * 0.82 : height;
    final cache = (innerW * dpr).ceil();

    final logo = Image.asset(
      _asset,
      width: innerW,
      height: innerH,
      fit: BoxFit.contain,
      cacheWidth: cache,
      filterQuality: FilterQuality.high,
      excludeFromSemantics: true,
      errorBuilder: (_, _, _) => Icon(
        Icons.diamond_outlined,
        color: AppPalette.gold,
        size: innerH * 0.55,
      ),
    );

    if (!framed || isLockup) {
      return SizedBox(width: width, height: height, child: logo);
    }

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: onDark ? AppPalette.navyDark : AppPalette.navy,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(
          color: AppPalette.gold.withValues(alpha: onDark ? 0.7 : 0.45),
          width: 1.1,
        ),
        boxShadow: AppShadows.subtle,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.22),
        child: logo,
      ),
    );
  }
}

/// عنوان العلامة النصي — دائماً بالإنجليزية كما هي.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({
    super.key,
    this.color = AppPalette.onNavy,
    this.fontSize = 22,
    this.showTagline = false,
    this.taglineColor,
  });

  final Color color;
  final double fontSize;
  final bool showTagline;
  final Color? taglineColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'GRAND ONE',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.4,
            height: 1.1,
            color: color,
          ),
        ),
        if (showTagline) ...[
          const SizedBox(height: 6),
          Text(
            'ALL IN ONE',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: fontSize * 0.42,
              fontWeight: FontWeight.w600,
              letterSpacing: 3.2,
              color: taglineColor ?? AppPalette.gold,
            ),
          ),
        ],
      ],
    );
  }
}
