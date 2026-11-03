import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grand_one/ui/shell/app_shell.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('مسارات الدخول إلى التطبيق', () {
    test('الهيكل هو الشاشة الجذرية بعد التحقق', () {
      const shell = AppShell();

      expect(shell.initialTab, AppTab.home);
    });

    test('المسارات المسمّاة تشير إلى الهيكل', () {
      expect(AppShell.routeGroom, '/shell');
    });

    test('كل تبويب مستقل بمعرّف فريد', () {
      final indexes = AppTab.values.map((t) => t.index).toSet();
      expect(indexes.length, AppTab.values.length);
      expect(AppTab.values.length, 4);
    });
  });

  group('شريط التنقّل', () {
    testWidgets('التبويب المحدد يبدأ على الرئيسية ولا يتغيّر بلا فعل',
        (tester) async {
      var selected = AppTab.home.index;
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              bottomNavigationBar: NavigationBar(
                selectedIndex: selected,
                onDestinationSelected: (i) => selected = i,
                destinations: [
                  for (final tab in AppTab.values)
                    NavigationDestination(
                      icon: Icon(tab.icon),
                      label: tab.label,
                    ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(selected, AppTab.home.index);
      expect(find.text('الرئيسية'), findsOneWidget);
      expect(find.text('المزيد'), findsOneWidget);
      expect(find.text('الخدمات'), findsOneWidget);
    });
  });
}
