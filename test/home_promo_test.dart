import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grand_one/app_theme.dart';
import 'package:grand_one/screens/home_screen.dart';

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
        theme: AppTheme.grandOneTheme,
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
    // اسمح لمحاولة التحميل البعيد بالفشل بهدوء والبقاء على الـ fallback
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('البطاقة الأولى تظهر ثم تتقلب وحدها', (tester) async {
    await pumpCarousel(tester);

    expect(find.text('عالم متكامل من الخدمات'), findsWidgets);
    expect(find.text('1 / 3'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(find.text('2 / 3'), findsOneWidget);
    expect(find.text('اختر خدماتك بكل سهولة'), findsWidgets);
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
