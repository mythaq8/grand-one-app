// lib/widgets/brand_mark.dart
// ============================================================
// BrandMark — شعار ميثاق (الخواتم والقبة) داخل إطار صغير
// ------------------------------------------------------------
// الشعار ذهبي بخلفية شفافة، وشكله عريض مع قبة ومئذنة. لذلك:
//   • يُعرض بـ BoxFit.contain مع هامش داخلي، لا cover،
//     وإلا قُصّت المئذنة والهلال.
//   • خلفية الشعار دائماً أبيض كريمي (#FAF7F2) حتى فوق
//     الهيدر الأخضر، فيبقى الشعار واضحاً ومتناسقاً مع الأيقونة.
//
// هذا هو المكان الوحيد الذي يعرف كيف يُرسم الشعار الصغير.
// الشاشات تستدعيه ولا ترسم Image.asset(logo) بنفسها.
// ============================================================

import 'package:flutter/material.dart';

import '../design/tokens.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.size = 40,
    this.onDark = false,
    this.framed = true,
  });

  /// الضلع الخارجي (مربع).
  final double size;

  /// true عند وضعه فوق خلفية خضراء غامقة (الحد الذهبي أقوى قليلاً).
  final bool onDark;

  /// false = الشعار وحده بلا إطار (للأحجام الكبيرة أو العلامات المائية).
  final bool framed;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final inner = framed ? size * 0.8 : size;
    final cache = (inner * dpr).ceil();

    final logo = Image.asset(
      AppAssets.logo,
      width: inner,
      height: inner,
      fit: BoxFit.contain,
      cacheWidth: cache,
      filterQuality: FilterQuality.medium,
      excludeFromSemantics: true,
      errorBuilder: (_, _, _) => Icon(
        Icons.favorite_rounded,
        color: AppPalette.gold,
        size: inner * 0.6,
      ),
    );

    if (!framed) return SizedBox(width: size, height: size, child: logo);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppPalette.background,
        borderRadius: BorderRadius.circular(size * 0.3),
        border: Border.all(
          color: AppPalette.gold.withValues(alpha: onDark ? 0.65 : 0.5),
          width: 1.2,
        ),
        boxShadow: onDark ? AppShadows.subtle : AppShadows.subtle,
      ),
      child: logo,
    );
  }
}
