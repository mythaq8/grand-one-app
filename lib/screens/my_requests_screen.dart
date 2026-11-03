// lib/screens/my_requests_screen.dart
// تبويب «طلباتي» — حجوزات + تنظيم مناسبات (party القديم أُزيل)

import 'package:flutter/material.dart';

import '../design/tokens.dart';
import '../design/typography.dart';
import '../ui/layout/responsive.dart';
import 'my_bookings_screen.dart';
import 'my_occasion_requests_screen.dart';

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
                    'تابع حجوزاتك وطلبات تنظيم المناسبات من هنا.',
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
    ];

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.horizontalPadding(context),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            children: List.generate(items.length, (i) {
              final selected = _index == i;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: i == 0 ? 0 : Space.xs,
                    right: i == items.length - 1 ? 0 : Space.xs,
                  ),
                  child: Material(
                    color: selected
                        ? AppPalette.navy.withValues(alpha: 0.12)
                        : AppPalette.surface,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _select(i),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: Space.sm,
                          horizontal: Space.xs,
                        ),
                        child: Column(
                          children: [
                            Icon(
                              items[i].icon,
                              color: selected
                                  ? AppPalette.navy
                                  : AppPalette.textSecondary,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              items[i].label,
                              style: AppText.caption.copyWith(
                                color: selected
                                    ? AppPalette.navy
                                    : AppPalette.textSecondary,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
