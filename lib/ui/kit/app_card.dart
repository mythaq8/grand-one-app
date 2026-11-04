// lib/ui/kit/app_card.dart
// ============================================================
// بطاقة محتوى موحّدة: نفس الحشو والحدود والزوايا في كل الشاشات.
// ============================================================

import 'package:flutter/material.dart';

import '../../design/tokens.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(Space.lg),
    this.accent,
    this.margin,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  /// لون شريط جانبي رفيع يدل على الحالة (اختياري).
  final Color? accent;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final body = Padding(padding: padding, child: child);
    final card = Card(
      margin: margin ?? EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: accent == null
          ? body
          : Stack(
              children: [
                body,
                PositionedDirectional(
                  start: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(width: 4, color: accent),
                ),
              ],
            ),
    );
    if (onTap == null) return card;
    return Card(
      margin: margin ?? EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: accent == null
            ? body
            : Stack(
                children: [
                  body,
                  PositionedDirectional(
                    start: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(width: 4, color: accent),
                  ),
                ],
              ),
      ),
    );
  }
}
