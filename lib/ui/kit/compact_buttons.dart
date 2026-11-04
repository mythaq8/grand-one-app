// lib/ui/kit/compact_buttons.dart
// ============================================================
// أزرار المظهر العام تملأ العرض كاملاً (minimumSize.width = ∞).
// داخل Row أو trailing أو Wrap يسبّب ذلك عرضاً غير محدود فلا يظهر الزر.
// غلّف الأزرار بـ CompactButtons لتصبح بعرض محتواها وارتفاع 44.
// ============================================================

import 'package:flutter/material.dart';

import '../../design/tokens.dart';

class CompactButtons extends StatelessWidget {
  const CompactButtons({super.key, required this.child, this.height = 44});

  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = WidgetStatePropertyAll(Size(0, height));
    ButtonStyle? tweak(ButtonStyle? s) =>
        (s ?? const ButtonStyle()).copyWith(minimumSize: size);
    return Theme(
      data: theme.copyWith(
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: tweak(theme.elevatedButtonTheme.style),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: tweak(theme.filledButtonTheme.style),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: tweak(theme.outlinedButtonTheme.style),
        ),
      ),
      child: child,
    );
  }
}

/// صف أزرار إجراءات يلتف عند ضيق المساحة، بعرض كل زر بحسب محتواه.
class ActionRow extends StatelessWidget {
  const ActionRow({super.key, required this.children, this.alignment});

  final List<Widget> children;
  final WrapAlignment? alignment;

  @override
  Widget build(BuildContext context) {
    return CompactButtons(
      child: Wrap(
        spacing: Space.sm,
        runSpacing: Space.sm,
        alignment: alignment ?? WrapAlignment.start,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: children,
      ),
    );
  }
}
