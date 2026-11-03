import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grand_one/app_theme.dart';
import 'package:grand_one/design/tokens.dart';
import 'package:grand_one/ui/shell/app_shell.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppShell', () {
    testWidgets('يعرض أربعة تبويبات بالترتيب المتفق عليه', (tester) async {
      final tabs = AppTab.values;

      expect(tabs.length, 4);
      expect(
        tabs.map((t) => t.label).toList(),
        ['الرئيسية', 'الخدمات', 'طلباتي', 'المزيد'],
      );
    });

    testWidgets('التبويبات تُستخدم كأسماء مسارات منطقية', (tester) async {
      expect(AppTab.home.index, 0);
      expect(AppTab.services.index, 1);
      expect(AppTab.requests.index, 2);
      expect(AppTab.more.index, 3);
    });

    testWidgets('شريط التنقّل يحترم حدّ اللمس الأدنى', (tester) async {
      final theme = AppTheme.grandOneTheme;
      expect(theme.navigationBarTheme.height, Sizes.navBarHeight);
      expect(
        theme.navigationBarTheme.labelBehavior,
        NavigationDestinationLabelBehavior.alwaysShow,
      );
      expect(
        theme.navigationBarTheme.backgroundColor,
        AppPalette.surface,
      );
    });

    testWidgets('الشريط الجانبي معرّف بنفس ألوان الهوية', (tester) async {
      final theme = AppTheme.grandOneTheme;
      expect(theme.navigationRailTheme.selectedIconTheme?.color,
          AppPalette.goldDeep);
      expect(theme.navigationRailTheme.unselectedIconTheme?.color,
          AppPalette.textTertiary);
    });
  });
}
