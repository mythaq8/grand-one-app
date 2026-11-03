// lib/widgets/brand_mark.dart
// ============================================================
// BrandMark — رمز G1 المعتمد لـ GRAND ONE
// ============================================================

import 'package:flutter/material.dart';

import '../design/tokens.dart';

enum BrandMarkVariant {
  /// رمز G1 وحده على خلفية Navy.
  monogram,

  /// الشعار الكامل مع الاسم والعبارة العربية.
  lockup,
}

class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.size = 48,
    this.onDark = false,
    this.framed = false,
    this.variant = BrandMarkVariant.monogram,
  });

  /// للرمز: طول الضلع. للشعار الكامل: العرض.
  final double size;

  /// يُبقى للتوافق. الأصل نفسه بخلفية Navy.
  final bool onDark;

  /// حلقة ذهبية رفيعة حول الرمز فقط.
  final bool framed;

  final BrandMarkVariant variant;

  String get _asset => switch (variant) {
        BrandMarkVariant.monogram => AppAssets.monogram,
        BrandMarkVariant.lockup => AppAssets.lockup,
      };

  @override
  Widget build(BuildContext context) {
    final isLockup = variant == BrandMarkVariant.lockup;
    final width = size;
    final height = isLockup ? size * 9 / 16 : size;
    final radius = isLockup ? 18.0 : size * 0.18;

    final logo = Image.asset(
      _asset,
      width: width,
      height: height,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
      excludeFromSemantics: true,
      errorBuilder: (_, _, _) => Icon(
        Icons.diamond_outlined,
        color: AppPalette.gold,
        size: height * 0.45,
      ),
    );

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: framed && !isLockup
            ? Border.all(
                color: AppPalette.gold.withValues(alpha: onDark ? 0.85 : 0.65),
                width: 1.2,
              )
            : null,
        boxShadow: isLockup ? AppShadows.soft : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: logo,
      ),
    );
  }
}

/// عنوان العلامة النصي — يُستخدم فقط حين لا نعرض الشعار الكامل.
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
            letterSpacing: 1.2,
            height: 1.15,
            color: color,
          ),
        ),
        if (showTagline) ...[
          const SizedBox(height: 8),
          Text(
            'ALL IN ONE',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: (fontSize * 0.38).clamp(11, 14),
              fontWeight: FontWeight.w500,
              letterSpacing: 2.2,
              color: taglineColor ?? AppPalette.goldLight,
            ),
          ),
        ],
      ],
    );
  }
}
