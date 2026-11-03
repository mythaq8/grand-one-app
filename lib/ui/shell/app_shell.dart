// lib/ui/shell/app_shell.dart
// ============================================================
// هيكل التنقّل — GRAND ONE (خدمات فقط)
// ============================================================

import 'package:flutter/material.dart';

import '../../design/tokens.dart';
import '../../design/typography.dart';
import '../../screens/home_screen.dart';
import '../../screens/my_requests_screen.dart';
import '../../screens/more_screen.dart';
import '../../screens/services_screen.dart';
import '../../widgets/brand_mark.dart';
import '../layout/responsive.dart';

/// تبويبات تطبيق الخدمات فقط.
enum AppTab {
  home(
    label: 'الرئيسية',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
  ),
  services(
    label: 'الخدمات',
    icon: Icons.storefront_outlined,
    selectedIcon: Icons.storefront_rounded,
  ),
  requests(
    label: 'طلباتي',
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long_rounded,
  ),
  more(
    label: 'المزيد',
    icon: Icons.more_horiz_rounded,
    selectedIcon: Icons.more_horiz_rounded,
  );

  const AppTab({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    this.initialTab = AppTab.home,
  });

  final AppTab initialTab;

  static const String routeGroom = '/shell';

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late AppTab _current = widget.initialTab;
  final Set<AppTab> _visited = {AppTab.home};

  void _select(AppTab tab) {
    if (tab == _current) return;
    setState(() {
      _current = tab;
      _visited.add(tab);
    });
  }

  Widget _screenFor(AppTab tab) {
    switch (tab) {
      case AppTab.home:
        return HomeScreen(
          embedded: true,
          onOpenServicesTab: () => _select(AppTab.services),
          onOpenRequestsTab: () => _select(AppTab.requests),
        );
      case AppTab.services:
        return const ServicesScreen(embedded: true);
      case AppTab.requests:
        return const MyRequestsScreen();
      case AppTab.more:
        return const MoreScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = Responsive.of(context);
    final useRail = size.useRail;

    final body = IndexedStack(
      index: _current.index,
      children: [
        for (final tab in AppTab.values)
          _visited.contains(tab)
              ? _screenFor(tab)
              : const SizedBox.shrink(),
      ],
    );

    if (useRail) {
      return Scaffold(
        body: Row(
          children: [
            _buildRail(context),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: _buildNavigationBar(context),
    );
  }

  Widget _buildNavigationBar(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppPalette.surface,
        border: const Border(
          top: BorderSide(color: AppPalette.borderLight),
        ),
        boxShadow: [
          BoxShadow(
            color: AppPalette.navy.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: NavigationBar(
          selectedIndex: _current.index,
          onDestinationSelected: (i) => _select(AppTab.values[i]),
          destinations: [
            for (final tab in AppTab.values)
              NavigationDestination(
                icon: Icon(tab.icon),
                selectedIcon: Icon(tab.selectedIcon),
                label: tab.label,
                tooltip: tab.label,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRail(BuildContext context) {
    return NavigationRail(
      selectedIndex: _current.index,
      onDestinationSelected: (i) => _select(AppTab.values[i]),
      labelType: NavigationRailLabelType.all,
      minWidth: 76,
      backgroundColor: AppPalette.surface,
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.lg),
        child: const BrandMark(size: 56),
      ),
      destinations: [
        for (final tab in AppTab.values)
          NavigationRailDestination(
            icon: Icon(tab.icon),
            selectedIcon: Icon(tab.selectedIcon),
            label: Text(tab.label),
          ),
      ],
    );
  }
}

class ShellPageHeader extends StatelessWidget {
  const ShellPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Responsive.horizontalPadding(context),
        Space.md,
        Space.sm,
        Space.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppText.section.copyWith(
                    color: AppPalette.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppText.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}
