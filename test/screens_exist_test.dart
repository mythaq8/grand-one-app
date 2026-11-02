import 'package:flutter_test/flutter_test.dart';
import 'package:mithaq_app/screens/intro_screen.dart';
import 'package:mithaq_app/screens/more_screen.dart';
import 'package:mithaq_app/screens/my_requests_screen.dart';
import 'package:mithaq_app/ui/shell/app_shell.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('الشاشات الجديدة موجودة وقابلة للبناء', () {
    test('فئات الشاشات معرّفة', () {
      // اختبار بسيط يضمن عدم حذف أي شاشة أو إعادة تسميتها خطأً
      // أثناء الهيكلة. أي كسر في الاستيراد يظهر هنا.
      expect(const IntroScreen(), isNotNull);
      expect(const MyRequestsScreen(), isNotNull);
      expect(const MoreScreen(isGroomRole: true), isNotNull);
      expect(const MoreScreen(isGroomRole: false), isNotNull);
      expect(const AppShell(isGroomRole: true), isNotNull);
      expect(const AppShell(isGroomRole: false), isNotNull);
    });

    test('الهيكل يبدأ من الرئيسية افتراضياً', () {
      const shell = AppShell(isGroomRole: true);
      expect(shell.initialTab, AppTab.home);
      expect(shell.isGroomRole, isTrue);
    });

    test('كل تبويب له اسم عربي غير فارغ', () {
      for (final tab in AppTab.values) {
        expect(tab.label.trim(), isNotEmpty);
        expect(tab.label, isNot(contains('_')));
      }
    });
  });
}
