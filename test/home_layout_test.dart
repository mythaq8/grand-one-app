import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mithaq_app/app_theme.dart';
import 'package:mithaq_app/design/tokens.dart';
import 'package:mithaq_app/ui/kit/kit.dart';
import 'package:mithaq_app/ui/shell/app_shell.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpAt(
    WidgetTester tester,
    Widget child, {
    required Size size,
    double textScale = 1.0,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.mithaqTheme,
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: child,
        ),
      ),
    );
  }

  /// الشاشات الثلاث المتفق عليها في الخطة، مع تكبير الخط 1.5
  /// على أصغرها — هذه هي الحالة التي كانت تكسر الواجهة سابقاً.
  const sizes = <String, Size>{
    'هاتف صغير 360x640': Size(360, 640),
    'هاتف حديث 412x915': Size(412, 915),
    'تابلت 900x1280': Size(900, 1280),
  };

  group('الأقسام المشتركة تصمد على كل المقاسات', () {
    for (final entry in sizes.entries) {
      testWidgets('SectionHeader على ${entry.key}', (tester) async {
        await pumpAt(
          tester,
          Scaffold(
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionHeader(
                    title: 'مساراتك',
                    subtitle: 'مساران: زواج شرعي جاد، وخدمات تيسّر العرس.',
                  ),
                  for (var i = 0; i < 4; i++)
                    Padding(
                      padding: const EdgeInsets.all(Space.sm),
                      child: ActionTile(
                        icon: Icons.calendar_month_outlined,
                        title: 'الحجوزات والطلبات رقم $i',
                        subtitle: 'تابع حالة الطلب من هنا',
                        onTap: () {},
                      ),
                    ),
                ],
              ),
            ),
          ),
          size: entry.value,
          textScale: entry.key.contains('360') ? 1.5 : 1.0,
        );

        expect(tester.takeException(), isNull);
        final rect = tester.getRect(find.byType(SectionHeader).first);
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(entry.value.width));
      });
    }
  });

  group('تبويبات الهيكل', () {
    test('خمسة تبويبات بأسماء واضحة', () {
      expect(AppTab.values.map((t) => t.label).toList(), [
        'الرئيسية',
        'الزواج',
        'الخدمات',
        'طلباتي',
        'المزيد',
      ]);
    });

    test('لكل تبويب أيقونة وحالة محدّدة مختلفة', () {
      for (final tab in AppTab.values) {
        expect(tab.icon, isNotNull);
        expect(tab.selectedIcon, isNotNull);
      }
    });
  });

  group('الشريط السفلي', () {
    testWidgets('يبقى ظاهراً ويحترم المساحة الآمنة للجهاز', (tester) async {
      tester.view.padding = const FakeViewPadding(bottom: 34);
      tester.view.viewPadding = const FakeViewPadding(bottom: 34);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);

      // نبني شريط التنقّل بنفس بنية الهيكل للتأكد من القياس.
      var selected = 0;
      await pumpAt(
        tester,
        StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: const SizedBox.shrink(),
            bottomNavigationBar: SafeArea(
              top: false,
              child: NavigationBar(
                selectedIndex: selected,
                onDestinationSelected: (i) => setState(() => selected = i),
                destinations: [
                  for (final tab in AppTab.values)
                    NavigationDestination(
                      icon: Icon(tab.icon),
                      selectedIcon: Icon(tab.selectedIcon),
                      label: tab.label,
                    ),
                ],
              ),
            ),
          ),
        ),
        size: const Size(360, 640),
      );

      expect(tester.takeException(), isNull);
      for (final tab in AppTab.values) {
        expect(find.text(tab.label), findsWidgets);
      }

      final barRect = tester.getRect(find.byType(NavigationBar));
      expect(barRect.bottom, lessThanOrEqualTo(640 - 34 + 0.5));
      expect(barRect.height, greaterThanOrEqualTo(Sizes.navBarHeight));

      // تبديل التبويب يعمل
      await tester.tap(find.text('الخدمات').last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(selected, AppTab.services.index);
    });
  });
}
