import 'package:flutter/material.dart';

import '../../../design/tokens.dart';
import '../../../design/typography.dart';

/// شارات البطاقة: «متاح في تاريخك» + (موثّق، الأكثر حجزاً، مميّز).
class AvailabilityBadges extends StatelessWidget {
  const AvailabilityBadges({
    super.key,
    this.availableOnDate,
    this.badges = const [],
  });

  /// null = لا تاريخ مختار فلا نعرض حالة التوفر.
  final bool? availableOnDate;
  final List<String> badges;

  static const Map<String, String> _labels = {
    'featured': 'مميّز',
    'top_booked': 'الأكثر حجزاً',
    'verified': 'موثّق',
  };

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    if (availableOnDate == true) {
      chips.add(_chip('متاح في تاريخك', AppPalette.success, Colors.white));
    } else if (availableOnDate == false) {
      chips.add(_chip('غير متاح في تاريخك', AppPalette.textMuted, Colors.white));
    }
    for (final key in ['featured', 'top_booked', 'verified']) {
      if (badges.contains(key)) {
        chips.add(
          _chip(
            _labels[key]!,
            key == 'featured' ? AppPalette.gold : AppPalette.goldSoft,
            key == 'featured' ? AppPalette.navy : AppPalette.goldDeep,
          ),
        );
      }
    }
    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(spacing: 4, runSpacing: 4, children: chips);
  }

  Widget _chip(String label, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(Radii.pill),
        ),
        child: Text(label, style: AppText.micro.copyWith(color: fg)),
      );
}
