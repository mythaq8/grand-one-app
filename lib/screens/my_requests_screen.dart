// lib/screens/my_requests_screen.dart
// ============================================================
// تبويب «طلباتي» — بوابة واحدة للطلبات الموجودة
// ------------------------------------------------------------
// لم أُنشئ شاشة طلبات جديدة. هذه الشاشة تجمع ثلاث شاشات
// موجودة تعمل فعلاً، عبر مبدّل بسيط:
//   • الحجوزات        → MyBookingsScreen
//   • طلبات المناسبة  → MyOccasionRequestsScreen
//   • طلبات الحفلات   → MyPartyRequestsScreen   (المسار القديم)
//
// لا منطق أعمال هنا، ولا استدعاء للخادم. الشاشات الثلاث
// تُحمّل بياناتها بنفسها كما كانت.
// ============================================================

import 'package:flutter/material.dart';

import '../design/tokens.dart';
import '../design/typography.dart';
import '../ui/layout/responsive.dart';
import 'my_bookings_screen.dart';
import 'my_occasion_requests_screen.dart';
import 'my_party_requests_screen.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  int _index = 0;

  void _select(int i) {
    if (i == _index) return;
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.lg,
                Space.md,
                Space.lg,
                Space.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'طلباتي',
                    style: AppText.section.copyWith(
                      color: AppPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: Space.xs),
                  Text(
                    'خيارات واضحة وتواصل مباشر — تابع كل طلباتك من هنا.',
                    style: AppText.caption,
                  ),
                ],
              ),
            ),
            _buildSwitcher(context),
            const SizedBox(height: Space.sm),
            Expanded(
              child: IndexedStack(
                index: _index,
                children: const [
                  MyBookingsScreen(embedded: true),
                  MyOccasionRequestsScreen(embedded: true),
                  MyPartyRequestsScreen(embedded: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitcher(BuildContext context) {
    final items = <({String label, IconData icon})>[
      (label: 'الحجوزات', icon: Icons.calendar_month_outlined),
      (label: 'التخطيط', icon: Icons.celebration_outlined),
      (label: 'السابق', icon: Icons.history_outlined),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.horizontalPadding(context),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // على الشاشات الضيقة مع تكبير الخط قد لا تتسع الثلاثة
          // أفقياً، فنسمح بالتمرير الأفقي بدل ضغط النص.
          final narrow = constraints.maxWidth < 360;

          final row = Row(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(width: Space.sm),
                Expanded(
                  child: _SwitcherChip(
                    label: items[i].label,
                    icon: items[i].icon,
                    selected: _index == i,
                    onTap: () => _select(i),
                    compact: narrow,
                  ),
                ),
              ],
            ],
          );

          return narrow ? SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(width: 360, child: row),
          ) : row;
        },
      ),
    );
  }
}

class _SwitcherChip extends StatelessWidget {
  const _SwitcherChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppPalette.navy : AppPalette.surface,
      borderRadius: Radii.brSm,
      child: InkWell(
        onTap: onTap,
        borderRadius: Radii.brSm,
        child: Ink(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: Space.sm),
          decoration: BoxDecoration(
            borderRadius: Radii.brSm,
            border: Border.all(
              color: selected
                  ? AppPalette.gold.withValues(alpha: 0.55)
                  : AppPalette.border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: Sizes.iconSm + 2,
                color: selected ? AppPalette.goldLight : AppPalette.textSecondary,
              ),
              const SizedBox(width: Space.xs + 2),
              Flexible(
                child: Text(
                  label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.buttonSmall.copyWith(
                    fontSize: compact ? 12 : 13,
                    color: selected
                        ? AppPalette.onPrimary
                        : AppPalette.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
