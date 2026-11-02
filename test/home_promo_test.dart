import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_party_app/app_theme.dart';
import 'package:golden_party_app/screens/home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpCarousel(
    WidgetTester tester, {
    double textScale = 1.0,
    Size size = const Size(360, 700),
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
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: SingleChildScrollView(
              child: HomePromoCarousel(),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('البطاقة الأولى تظهر ثم تتقلب وحدها', (tester) async {
    await pumpCarousel(tester);

    expect(find.text('ثقة تبدأ قبل الخطوبة'), findsWidgets);
    expect(find.text('1 / 10'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(find.text('2 / 10'), findsOneWidget);
    expect(find.text('من الملف إلى التواصل المنضبط'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('لا تفيض على هاتف صغير مع خط أكبر', (tester) async {
    await pumpCarousel(
      tester,
      textScale: 1.4,
      size: const Size(360, 640),
    );
    expect(tester.takeException(), isNull);
  });
}
