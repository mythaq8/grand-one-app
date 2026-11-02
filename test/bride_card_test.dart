import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mithaq_app/app_theme.dart';
import 'package:mithaq_app/design/tokens.dart';
import 'package:mithaq_app/screens/exploration/widgets/bride_result_card.dart';

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
          child: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(Space.sm),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  group('بطاقة نتيجة البحث', () {
    testWidgets('تعرض الرمز والمكان والاختيار يعمل', (tester) async {
      var toggled = 0;
      await pumpAt(
        tester,
        BrideResultCard(
          code: 'B-1042',
          location: 'دمشق - المزة',
          details: const [
            BrideChipData(icon: Icons.cake_outlined, label: '27 سنة'),
            BrideChipData(icon: Icons.school_outlined, label: 'إجازة'),
          ],
          selected: false,
          onToggle: () => toggled++,
          onOpenProfile: () {},
        ),
        size: const Size(390, 844),
      );

      expect(find.text('رمز العروس: B-1042'), findsOneWidget);
      expect(find.text('دمشق - المزة'), findsOneWidget);
      expect(find.text('27 سنة'), findsOneWidget);
      expect(find.text('إجازة'), findsOneWidget);

      await tester.tap(find.text('رمز العروس: B-1042'));
      expect(toggled, 1);
    });

    testWidgets('لا تعرض قيماً غير محددة', (tester) async {
      await pumpAt(
        tester,
        BrideResultCard(
          code: 'B-2',
          location: '',
          details: const [
            BrideChipData(icon: Icons.cake_outlined, label: '24 سنة'),
          ],
          unknownCount: 9,
          selected: false,
          onToggle: () {},
          onOpenProfile: () {},
        ),
        size: const Size(390, 844),
      );

      // القيمة المعلومة ظاهرة
      expect(find.text('24 سنة'), findsOneWidget);
      // ولا يوجد أي نص «غير محدد» في البطاقة
      expect(find.textContaining('غير محدد'), findsNothing);
      // بدلاً منه سطر واحد يلخّص النقص
      expect(find.text('9 معلومة لم تُذكر بعد'), findsOneWidget);
    });

    testWidgets('الميزات تظهر فقط عندما تكون موجودة', (tester) async {
      await pumpAt(
        tester,
        const BrideResultCard(
          code: 'B-3',
          location: 'حمص',
          details: [],
          features: [
            (
              label: 'حافظة للقرآن',
              bg: AppPalette.goldSoft,
              fg: AppPalette.goldDark
            ),
          ],
          selected: false,
          onToggle: _noop,
          onOpenProfile: _noop,
        ),
        size: const Size(390, 844),
      );

      expect(find.text('حافظة للقرآن'), findsOneWidget);
      expect(find.text('تقبل التعدد'), findsNothing);
    });

    testWidgets('الحالة المختارة تُظهر علامة اختيار', (tester) async {
      await pumpAt(
        tester,
        BrideResultCard(
          code: 'B-4',
          location: '',
          details: const [],
          selected: true,
          onToggle: () {},
          onOpenProfile: () {},
        ),
        size: const Size(390, 844),
      );

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(find.byIcon(Icons.person_outline_rounded), findsNothing);
    });

    for (final entry in <String, Size>{
      'هاتف صغير 320 مع خط 1.5': const Size(320, 640),
      'هاتف 412': const Size(412, 915),
      'تابلت 900': const Size(900, 1280),
    }.entries) {
      testWidgets('تصمد على ${entry.key}', (tester) async {
        await pumpAt(
          tester,
          BrideResultCard(
            code: 'BRIDE-1234567890',
            location: 'محافظة دمشق - منطقة المزة الغربية',
            details: const [
              BrideChipData(icon: Icons.cake_outlined, label: '29 سنة'),
              BrideChipData(icon: Icons.height_outlined, label: '165 سم'),
              BrideChipData(
                icon: Icons.school_outlined,
                label: 'إجازة جامعية في الهندسة',
              ),
              BrideChipData(
                icon: Icons.menu_book_outlined,
                label: 'التزام واضح',
              ),
            ],
            features: const [
              (
                label: 'حافظة للقرآن',
                bg: AppPalette.goldSoft,
                fg: AppPalette.goldDark
              ),
              (
                label: 'تقبل التعدد',
                bg: AppPalette.successLight,
                fg: AppPalette.success
              ),
            ],
            unknownCount: 4,
            selected: false,
            onToggle: () {},
            onOpenProfile: () {},
          ),
          size: entry.value,
          textScale: entry.key.contains('320') ? 1.5 : 1.0,
        );

        expect(tester.takeException(), isNull);
        final rect = tester.getRect(find.byType(BrideResultCard));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(entry.value.width));
      });
    }
  });
}

void _noop() {}
