import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_party_app/app_theme.dart';
import 'package:golden_party_app/screens/intro_screen.dart';
import 'package:golden_party_app/ui_copy.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// يبني IntroScreen الحقيقي (بالثيم الحقيقي والأصول الحقيقية)
  /// على ثلاث مقاسات. الشاشة صفحة واحدة.
  ///
  /// ملاحظة: لا نلفّه بـ EasyLocalization في الاختبار لأن
  /// الحزمة تحتاج تهيئة جهاز كاملة تفشل داخل بيئة الاختبار.
  /// شاشة المقدمة لا تستعمل الترجمة أصلاً (كل نصوصها من UiCopy).
  Future<void> pumpIntro(WidgetTester tester, Size size,
      {double textScale = 1.0}) async {
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
          child: IntroScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  /// العنوان يجب أن يكون ظاهراً فوق زر البدء دون تمرير.
  void expectAboveButton(WidgetTester tester, Finder title, Finder button) {
    expect(title, findsOneWidget);
    final titleRect = tester.getRect(title);
    final buttonRect = tester.getRect(button);
    expect(titleRect.top, greaterThanOrEqualTo(0));
    expect(titleRect.bottom, lessThanOrEqualTo(buttonRect.top),
        reason: 'العنوان يجب أن يظهر كاملاً فوق الزر');
  }

  for (final entry in <String, Size>{
    'هاتف صغير 360': const Size(360, 640),
    'هاتف حديث 412': const Size(412, 915),
    'تابلت 900': const Size(900, 1280),
  }.entries) {
    testWidgets('IntroScreen صفحة واحدة على ${entry.key}', (tester) async {
      await pumpIntro(
        tester,
        entry.value,
        textScale: entry.key.contains('360') ? 1.4 : 1.0,
      );

      expect(find.text(UiCopy.introWelcomeTitle), findsOneWidget);
      expect(find.text(UiCopy.introSummary), findsOneWidget);
      expect(find.text('التالي'), findsNothing);
      expect(find.text('تخطي'), findsNothing);
      expect(find.text(UiCopy.introStartButton), findsOneWidget);
      expect(tester.takeException(), isNull);
      expectAboveButton(
        tester,
        find.text(UiCopy.introWelcomeTitle),
        find.text(UiCopy.introStartButton),
      );
    });
  }
}
