import 'package:flutter_test/flutter_test.dart';
import 'package:grand_one/screens/intro_screen.dart';
import 'package:grand_one/screens/more_screen.dart';
import 'package:grand_one/screens/my_requests_screen.dart';
import 'package:grand_one/ui/shell/app_shell.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('الشاشات الجديدة موجودة وقابلة للبناء', () {
    test('فئات الشاشات معرّفة', () {
      expect(const IntroScreen(), isNotNull);
      expect(const MyRequestsScreen(), isNotNull);
      expect(const MoreScreen(), isNotNull);
      expect(const AppShell(), isNotNull);
    });

    test('الهيكل يبدأ من الرئيسية افتراضياً', () {
      const shell = AppShell();
      expect(shell.initialTab, AppTab.home);
    });

    test('كل تبويب له اسم عربي غير فارغ', () {
      for (final tab in AppTab.values) {
        expect(tab.label.trim(), isNotEmpty);
        expect(tab.label, isNot(contains('_')));
      }
      expect(
        AppTab.values.map((t) => t.label).toList(),
        ['الرئيسية', 'الخدمات', 'طلباتي', 'المزيد'],
      );
    });
  });
}
