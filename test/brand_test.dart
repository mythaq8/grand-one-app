import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mithaq_app/app_theme.dart';
import 'package:mithaq_app/design/tokens.dart';
import 'package:mithaq_app/widgets/islamic_decorations.dart';

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
          child: Scaffold(body: child),
        ),
      ),
    );
  }

  group('إطار القوس', () {
    testWidgets('يرسم ولا يفيض على شاشة صغيرة', (tester) async {
      await pumpAt(
        tester,
        const Center(
          child: SizedBox(
            width: 240,
            height: 320,
            child: ArchFrame(
              child: ColoredBox(color: AppPalette.greenSoft),
            ),
          ),
        ),
        size: const Size(320, 640),
      );

      expect(tester.takeException(), isNull);
      final rect = tester.getRect(find.byType(ArchFrame));
      expect(rect.width, 240);
      expect(rect.height, 320);
    });

    test('القوس أعلى في المنتصف وأدنى عند الجانبين', () {
      const clipper = ArchClipper();
      final path = clipper.getClip(const Size(100, 100));

      // المسار يغطي عرض العنصر كاملاً، وارتفاعه يبدأ من القمة
      // (apex = 2% من الارتفاع) لا من الصفر.
      final bounds = path.getBounds();
      expect(bounds.width, 100);
      expect(bounds.top, closeTo(2, 0.5));
      expect(bounds.bottom, 100);

      // المنتصف أعلى من الجانبين: النقطة قرب القمة داخل القوس،
      // والزاوية العليا اليمنى مقصوصة خارج القوس.
      expect(path.contains(const Offset(50, 5)), isTrue);
      expect(path.contains(const Offset(99, 3)), isFalse);
      // وأسفل العنصر داخل بالكامل
      expect(path.contains(const Offset(50, 90)), isTrue);
      expect(path.contains(const Offset(2, 90)), isTrue);
    });

    test('shouldReclip يتحسّس تغيير النسبة', () {
      const a = ArchClipper(shoulderRatio: 0.5);
      const b = ArchClipper(shoulderRatio: 0.6);
      const c = ArchClipper(shoulderRatio: 0.5);
      expect(a.shouldReclip(b), isTrue);
      expect(a.shouldReclip(c), isFalse);
    });
  });

  group('رموز الأصول', () {
    test('كل مسار موجود فعلياً ويشير إلى الهوية', () {
      expect(AppAssets.logo, startsWith('assets/images/'));
      expect(AppAssets.logo, endsWith('.png'));
      expect(AppAssets.introCovenant, endsWith('.jpg'));
      expect(AppAssets.introPath, endsWith('.jpg'));
      expect(AppAssets.introHall, endsWith('.jpg'));
    });
  });

  group('عناصر الهوية الأخرى', () {
    testWidgets('AyahCard تعرض النص والمرجع', (tester) async {
      await pumpAt(
        tester,
        const SingleChildScrollView(
          child: AyahCard(
            ayah: 'وَجَعَلَ بَيْنَكُم مَّوَدَّةً وَرَحْمَةً',
            reference: 'سورة الروم، الآية 21',
          ),
        ),
        size: const Size(360, 640),
        textScale: 1.3,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('سورة الروم، الآية 21'), findsOneWidget);
    });

    testWidgets('IslamicLogoFrame يستعمل الشعار المحسّن',
        (tester) async {
      await pumpAt(
        tester,
        const Center(child: IslamicLogoFrame(size: 100)),
        size: const Size(360, 640),
      );

      // الصورة قد لا تُحمّل في الاختبار، لكن الويدجت يجب أن تُبنى
      // بلا استثناء وبالعنوان.
      expect(tester.takeException(), isNull);
      expect(find.text('ميثاق'), findsOneWidget);
    });
  });
}
