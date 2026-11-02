import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mithaq_app/widgets/form_fields.dart';
import 'package:mithaq_app/widgets/islamic_decorations.dart';
import 'package:mithaq_app/widgets/screen_fit.dart';
import 'package:mithaq_app/widgets/ux_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpSurface(
    WidgetTester tester,
    Widget home, {
    Size size = const Size(320, 640),
    double textScale = 1.5,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: home,
        ),
      ),
    );
  }

  test('شريط العنوان يحافظ على ارتفاعه عند حجم الخط العادي', () {
    expect(const IslamicAppBar(title: 'ميثاق').preferredSize.height, 60);
    expect(
      const IslamicAppBar(title: 'ميثاق', subtitle: 'فرعي').preferredSize.height,
      72,
    );
  });

  testWidgets('زر ميثاق لا يتجاوز عرضاً ضيقاً مع خط أكبر', (tester) async {
    await pumpSurface(
      tester,
      Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: IslamicButton(
            label: 'إرسال طلبات الزواج المحددة إلى الأهل الآن',
            icon: const Icon(Icons.send_rounded, size: 18),
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('إرسال طلبات الزواج المحددة إلى الأهل الآن'), findsOneWidget);
    final button = tester.getSize(find.byType(ElevatedButton));
    expect(button.width, lessThanOrEqualTo(296));
    expect(button.height, greaterThanOrEqualTo(52));
  });

  testWidgets('عنوان الشريط يُقص بنقاط ولا يخرج عن الشاشة', (tester) async {
    await pumpSurface(
      tester,
      Scaffold(
        appBar: IslamicAppBar(
          title: 'تسجيل ملف الفتاة ومراجعة البيانات الكاملة',
          subtitle: 'الخطوة الثانية من البيانات الشخصية',
          actions: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.settings)),
          ],
        ),
        body: const SizedBox.shrink(),
      ),
      size: const Size(320, 640),
      textScale: 1.4,
    );

    expect(tester.takeException(), isNull);
    final bar = tester.getRect(find.byType(IslamicAppBar));
    expect(bar.right, lessThanOrEqualTo(320));
    expect(bar.left, greaterThanOrEqualTo(0));
  });

  testWidgets('الفاصل الذهبي يضيق مع المساحة المتاحة', (tester) async {
    await pumpSurface(
      tester,
      const Scaffold(
        body: Center(
          child: SizedBox(
            width: 100,
            child: OrnamentDivider(width: 180),
          ),
        ),
      ),
      textScale: 1,
    );

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(OrnamentDivider)).width, 100);
  });

  testWidgets('بطاقة المسار تبقى داخل عرض ضيق', (tester) async {
    await pumpSurface(
      tester,
      Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(8),
          child: JourneyCard(
            title: 'خدمات الأعراس والمناسبات',
            body: 'قاعات وتصوير وضيافة في محافظتك مع تفاصيل الحجز',
            icon: Icons.celebration_outlined,
            accent: const Color(0xFF0E6B4F),
            onTap: () {},
          ),
        ),
      ),
      size: const Size(320, 640),
      textScale: 1.4,
    );

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(JourneyCard)).width, lessThanOrEqualTo(304));
  });

  testWidgets('نافذة الاختيار تبقى داخل شاشة قصيرة', (tester) async {
    await pumpSurface(
      tester,
      Scaffold(
        body: AppMultiSelect(
          label: 'المحافظة',
          options: List<String>.generate(24, (index) => 'خيار رقم $index'),
          selected: const [],
          onChanged: (_) {},
        ),
      ),
      size: const Size(320, 480),
      textScale: 1.3,
    );

    await tester.tap(find.byType(InkWell).first);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('تم'), findsOneWidget);
    final dialog = tester.getRect(find.byType(AlertDialog));
    expect(dialog.top, greaterThanOrEqualTo(0));
    expect(dialog.bottom, lessThanOrEqualTo(480));
    expect(dialog.left, greaterThanOrEqualTo(0));
    expect(dialog.right, lessThanOrEqualTo(320));
  });

  testWidgets('الزر السفلي يبقى فوق حافة الجهاز', (tester) async {
    tester.view.padding = const FakeViewPadding(bottom: 34);
    tester.view.viewPadding = const FakeViewPadding(bottom: 34);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await pumpSurface(
      tester,
      IslamicScaffold(
        appBar: const IslamicAppBar(title: 'ميثاق'),
        body: Align(
          alignment: Alignment.bottomCenter,
          child: IslamicButton(
            label: 'متابعة',
            onPressed: () {},
          ),
        ),
      ),
      size: const Size(360, 640),
      textScale: 1.2,
    );

    expect(tester.takeException(), isNull);
    final button = tester.getRect(find.text('متابعة'));
    expect(button.bottom, lessThanOrEqualTo(640 - 34));
  });

  testWidgets('تبويبات الخدمات تبقى داخل شاشة ضيقة مع خط أكبر', (tester) async {
    await pumpSurface(
      tester,
      Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: const [
              Expanded(
                child: ShrinkIconLabel(
                  icon: Icons.miscellaneous_services_rounded,
                  label: 'الخدمات',
                  color: Color(0xFF064E43),
                ),
              ),
              Expanded(
                child: ShrinkIconLabel(
                  icon: Icons.storefront_rounded,
                  label: 'المزودون',
                  color: Color(0xFF064E43),
                ),
              ),
              Expanded(
                child: ShrinkIconLabel(
                  icon: Icons.celebration_outlined,
                  label: 'تنظيم مناسبة',
                  color: Color(0xFF064E43),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
      size: const Size(320, 640),
      textScale: 1.5,
    );

    expect(tester.takeException(), isNull);
    for (final label in ['الخدمات', 'المزودون', 'تنظيم مناسبة']) {
      final rect = tester.getRect(find.text(label));
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(320));
    }
  });

  testWidgets('عرض الحوار لا يتجاوز شاشة 320', (tester) async {
    late double width;
    late double height;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            viewInsets: EdgeInsets.only(bottom: 240),
            padding: EdgeInsets.only(bottom: 24),
          ),
          child: Builder(
            builder: (context) {
              width = dialogWidth(context, 500);
              height = dialogHeight(context, 400);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(width, lessThanOrEqualTo(272));
    expect(height, lessThanOrEqualTo(280));
    expect(height, greaterThanOrEqualTo(140));
  });

  testWidgets('إطار الشاشة يملأ الهاتف ويتمركز على الشاشة العريضة', (tester) async {
    Future<void> pumpFrame(Size size) {
      return pumpSurface(
        tester,
        const Scaffold(
          body: ScreenFrame(
            maxWidth: 960,
            child: ColoredBox(
              key: Key('frame-fill'),
              color: Color(0xFF064E43),
              child: SizedBox.expand(),
            ),
          ),
        ),
        size: size,
        textScale: 1,
      );
    }

    await pumpFrame(const Size(320, 640));
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byKey(const Key('frame-fill'))), const Size(320, 640));

    await pumpFrame(const Size(1280, 800));
    expect(tester.takeException(), isNull);
    final wide = tester.getSize(find.byKey(const Key('frame-fill')));
    expect(wide.width, 960);
    expect(wide.height, 800);
  });

  testWidgets('الزر يبقى داخل شاشة متوسطة مع تكبير الخط', (tester) async {
    await pumpSurface(
      tester,
      Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: IslamicButton(
            label: 'تأكيد الحجز وإرسال الطلب',
            icon: const Icon(Icons.check_rounded, size: 18),
            onPressed: () {},
          ),
        ),
      ),
      size: const Size(360, 780),
      textScale: 1.4,
    );

    expect(tester.takeException(), isNull);
    final rect = tester.getRect(find.byType(ElevatedButton));
    expect(rect.left, greaterThanOrEqualTo(0));
    expect(rect.right, lessThanOrEqualTo(360));
  });
}
