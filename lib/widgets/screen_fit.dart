import 'dart:math' as math;

import 'package:flutter/material.dart';

/// يحسب عرض نافذة لا يتجاوز الشاشة حتى مع الهوامش.
double dialogWidth(BuildContext context, double preferred) {
  final width = MediaQuery.sizeOf(context).width;
  return math.min(preferred, math.max(160, width - 48));
}

/// يحسب ارتفاع نافذة يبقى فوق لوحة المفاتيح وحافة الجهاز.
double dialogHeight(BuildContext context, double preferred) {
  final media = MediaQuery.of(context);
  final available =
      media.size.height - media.viewInsets.bottom - media.padding.vertical - 96;
  return math.min(preferred, math.max(140, available));
}

/// يضع محتوى الشاشة في عرض موحّد: كامل العرض على الهاتف، ومتمركز على الشاشة العريضة.
/// الارتفاع يبقى محدوداً حتى تعمل القوائم التي تملأ الشاشة.
class ScreenFrame extends StatelessWidget {
  const ScreenFrame({
    super.key,
    required this.child,
    this.maxWidth = 960,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;
        final width = !maxW.isFinite ? maxWidth : math.min(maxW, maxWidth);
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: width,
            height: maxH.isFinite ? maxH : null,
            child: child,
          ),
        );
      },
    );
  }
}

/// أيقونة مع نص تبقى داخل عرضها: صف عريض، أو عمود عند الضيق وتكبير الخط.
class ShrinkIconLabel extends StatelessWidget {
  const ShrinkIconLabel({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.iconSize = 19,
    this.fontSize = 13,
    this.fontWeight = FontWeight.bold,
  });

  final IconData icon;
  final String label;
  final Color color;
  final double iconSize;
  final double fontSize;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(1);
        final narrow = !constraints.maxWidth.isFinite ||
            constraints.maxWidth < 112 ||
            scale >= 1.25;
        final text = Text(
          label,
          maxLines: narrow ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
          ),
        );
        if (narrow) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: iconSize, color: color),
              const SizedBox(height: 2),
              text,
            ],
          );
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: iconSize, color: color),
            const SizedBox(width: 4),
            Flexible(child: text),
          ],
        );
      },
    );
  }
}
