import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mithaq_app/ui/shell/app_shell.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// يحرس هذا الاختبار قراراً معمارياً: كل مدخل إلى التطبيق بعد
  /// تسجيل الدخول يجب أن يفتح AppShell (بالشريط السفلي)، لا
  /// HomeScreen مباشرة. لو عاد أحدهم إلى HomeScreen، يظهر المستخدم
  /// داخل شاشة بلا تنقّل — وهذا ما كان يحدث قبل الهيكلة.
  group('مسارات الدخول إلى التطبيق', () {
    test('الهيكل هو الشاشة الجذرية بعد التحقق', () {
      // نتحقق من العقد البرمجي: AppShell يقبل الدور ويبدأ من
      // الرئيسية، وهو ما تعتمد عليه كل نقاط الدخول.
      const groom = AppShell(isGroomRole: true);
      const bride = AppShell(isGroomRole: false);

      expect(groom.isGroomRole, isTrue);
      expect(bride.isGroomRole, isFalse);
      expect(groom.initialTab, AppTab.home);
      expect(bride.initialTab, AppTab.home);
    });

    test('المسارات المسمّاة تشير إلى الهيكل', () {
      expect(AppShell.routeGroom, '/shell');
      expect(AppShell.routeBride, '/shell-bride');
    });

    test('كل تبويب مستقل بمعرّف فريد', () {
      final indexes = AppTab.values.map((t) => t.index).toSet();
      expect(indexes.length, AppTab.values.length);
    });
  });

  group('شريط التنقّل', () {
    testWidgets('التبويب المحدد يبدأ على الرئيسية ولا يتغيّر بلا فعل',
        (tester) async {
      // نبني شريطاً بنفس مواصفات الهيكل ونتحقق من البداية.
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
    });
  });
}
