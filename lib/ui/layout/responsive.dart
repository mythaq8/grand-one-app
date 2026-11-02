// lib/ui/layout/responsive.dart
// ============================================================
// طبقة الاستجابة (Responsive)
// ------------------------------------------------------------
// المشكلة التي تحلّها:
//   الشاشات كانت تعتمد على عرض ثابت، و ScreenFrame مستخدم في
//   3 مواضع فقط. فالنص يطول، والبطاقات تتمدّد على التابلت،
//   والأيقونات تنضغط عند تكبير الخط.
//
// المبدأ:
//   1. صنّف عرض الشاشة (compact / medium / expanded).
//   2. حدّد أقصى عرض للمحتوى حتى لا يتمدّد النص على الشاشات العريضة.
//   3. عدد أعمدة الشبكة يُحسب من العرض المتاح، لا من عدد ثابت.
//   4. كل شيء يجب أن يصمد مع تكبير الخط 1.5x (إتاحة).
// ============================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../design/tokens.dart';

/// تصنيف حجم الشاشة.
enum ScreenSize {
  /// هاتف — عمود واحد.
  compact,

  /// تابلت رأسي / نافذة متوسطة — عمودان.
  medium,

  /// سطح مكتب / تابلت أفقي — ثلاثة أعمدة.
  expanded;

  bool get isCompact => this == ScreenSize.compact;
  bool get isNotCompact => this != ScreenSize.compact;
  bool get isExpanded => this == ScreenSize.expanded;

  /// هل نعرض شريط تنقّل جانبي بدل السفلي؟
  bool get useRail => this != ScreenSize.compact;
}

/// أدوات قراءة حجم الشاشة.
abstract final class Responsive {
  /// يصنّف العرض. يعتمد على أقصر بُعد عند تدوير الشاشة
  /// حتى لا يتغيّر التخطيط جذرياً بمجرد القلب.
  static ScreenSize of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return fromWidth(width);
  }

  static ScreenSize fromWidth(double width) {
    if (width >= Breakpoints.medium) return ScreenSize.expanded;
    if (width >= Breakpoints.compact) return ScreenSize.medium;
    return ScreenSize.compact;
  }

  /// عدد أعمدة شبكة مناسبة لعرض معيّن، مع حد أدنى لعرض البطاقة.
  ///
  /// [minItemWidth] يمنع الأعمدة من النزول إلى حجم غير قابل للقراءة
  /// (مثلاً ثلاث بطاقات في 360px).
  static int gridColumns(
    double availableWidth, {
    double minItemWidth = 160,
    int max = 3,
  }) {
    if (!availableWidth.isFinite || availableWidth <= 0) return 1;
    final fit = (availableWidth / minItemWidth).floor();
    return fit.clamp(1, max);
  }

  /// هل الخط مكبّر بشكل يستوجب تخطيطاً أكثر تسامحاً؟
  static bool hasLargeText(BuildContext context) {
    return MediaQuery.textScalerOf(context).scale(1) >= 1.3;
  }

  /// حافة أفقية تتكيّف مع الحجم: أضيق على الهاتف، أوسع على التابلت.
  static double horizontalPadding(BuildContext context) {
    switch (of(context)) {
      case ScreenSize.compact:
        return Space.screenH;
      case ScreenSize.medium:
        return Space.xxl;
      case ScreenSize.expanded:
        return Space.xxl + Space.sm;
    }
  }
}

/// يحدّ عرض المحتوى ويوسّطه على الشاشات العريضة.
///
/// يختلف عن ScreenFrame القديم بأنه:
///  • لا يفرض ارتفاعاً (فلا يكسر القوائم التي تملأ الشاشة)،
///  • يحسب الحشو الأفقي تلقائياً،
///  • آمن مع العرض غير المحدود.
class ContentMaxWidth extends StatelessWidget {
  const ContentMaxWidth({
    super.key,
    required this.child,
    this.maxWidth = Sizes.contentMax,
    this.applyHorizontalPadding = false,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double maxWidth;
  final bool applyHorizontalPadding;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        final padding = applyHorizontalPadding
            ? Responsive.horizontalPadding(context)
            : 0.0;

        final contentWidth = !available.isFinite
            ? maxWidth
            : math.min(available - padding * 2, maxWidth);

        return Align(
          alignment: alignment,
          child: SizedBox(
            width: contentWidth.isFinite && contentWidth > 0
                ? contentWidth
                : null,
            child: child,
          ),
        );
      },
    );
  }
}

/// شبكة متجاوبة تتكيّف مع العرض وعدد العناصر.
///
/// استعملها بدل `GridView` بعدد أعمدة ثابت أو بدل `Wrap` يدوي.
class AdaptiveGrid extends StatelessWidget {
  const AdaptiveGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.minItemWidth = 160,
    this.maxColumns = 3,
    this.spacing = Space.md,
    this.runSpacing = Space.md,
    this.padding = EdgeInsets.zero,
    this.childAspectRatio = 1,
    this.shrinkWrap = true,
    this.physics,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double minItemWidth;
  final int maxColumns;
  final double spacing;
  final double runSpacing;
  final EdgeInsetsGeometry padding;
  final double childAspectRatio;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final columns = Responsive.gridColumns(
          width,
          minItemWidth: minItemWidth,
          max: maxColumns,
        );

        return GridView.builder(
          padding: padding,
          shrinkWrap: shrinkWrap,
          physics: physics ?? const NeverScrollableScrollPhysics(),
          itemCount: itemCount,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: runSpacing,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: itemBuilder,
        );
      },
    );
  }
}

/// يوزّع محتوى أفقياً على الشاشات العريضة، وعمودياً على الهاتف.
///
/// مفيد لشاشات التفاصيل: صورة على جانب وتفاصيل على الجانب الآخر
/// على التابلت، وفوق بعضها على الهاتف.
class AdaptiveTwoPane extends StatelessWidget {
  const AdaptiveTwoPane({
    super.key,
    required this.first,
    required this.second,
    this.breakpoint = Breakpoints.medium,
    this.gap = Space.lg,
    this.firstFlex = 5,
    this.secondFlex = 6,
    this.alignment = CrossAxisAlignment.start,
  });

  final Widget first;
  final Widget second;
  final double breakpoint;
  final double gap;
  final int firstFlex;
  final int secondFlex;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= breakpoint;

        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              first,
              SizedBox(height: gap),
              second,
            ],
          );
        }

        return Row(
          crossAxisAlignment: alignment,
          children: [
            Expanded(flex: firstFlex, child: first),
            SizedBox(width: gap),
            Expanded(flex: secondFlex, child: second),
          ],
        );
      },
    );
  }
}

/// حشو موحّد لمحتوى الشاشة، متكيّف مع الحجم ومع لوحة المفاتيح.
EdgeInsets screenContentPadding(
  BuildContext context, {
  bool bottomExtra = false,
}) {
  return EdgeInsets.fromLTRB(
    Responsive.horizontalPadding(context),
    Space.sm,
    Responsive.horizontalPadding(context),
    Space.xxl + (bottomExtra ? Space.xxxl : 0),
  );
}
