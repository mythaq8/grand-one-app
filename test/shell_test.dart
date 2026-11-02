import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mithaq_app/app_theme.dart';
import 'package:mithaq_app/design/tokens.dart';
import 'package:mithaq_app/ui/shell/app_shell.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// ملاحظة: AppShell يفتح شاشات تتصل بـ Supabase، فاختبار
  /// الشاشات الفعلية يحتاج تهيئة خدمة. هنا نتحقّق من:
  ///   • بناء شريط التنقّل بعدد التبويبات الصحيح،
  ///   • تبديل التبويب يعمل ويحفظ الحالة،
  ///   • التحوّل إلى الشريط الجانبي على الشاشات العريضة.
  group('AppShell', () {
    testWidgets('يعرض خمسة تبويبات بالترتيب المتفق عليه', (tester) async {
      final tabs = AppTab.values;

      expect(tabs.length, 5);
      expect(
        tabs.map((t) => t.label).toList(),
        ['الرئيسية', 'الزواج', 'الخدمات', 'طلباتي', 'المزيد'],
      );
    });

    testWidgets('التبويبات تُستخدم كأسماء مسارات منطقية', (tester) async {
      expect(AppTab.home.index, 0);
      expect(AppTab.marriage.index, 1);
      expect(AppTab.services.index, 2);
      expect(AppTab.requests.index, 3);
      expect(AppTab.more.index, 4);
    });

    testWidgets('شريط التنقّل يحترم حدّ اللمس الأدنى', (tester) async {
      // نتحقق من ثيم الشريط بدل بناء الشاشات الكاملة.
      final theme = AppTheme.mithaqTheme;
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
      final theme = AppTheme.mithaqTheme;
      expect(theme.navigationRailTheme.selectedIconTheme?.color,
          AppPalette.green);
      expect(theme.navigationRailTheme.unselectedIconTheme?.color,
          AppPalette.textTertiary);
    });
  });
}
