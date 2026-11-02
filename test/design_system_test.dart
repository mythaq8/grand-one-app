import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_party_app/app_theme.dart';
import 'package:golden_party_app/design/tokens.dart';
import 'package:golden_party_app/ui/kit/kit.dart';
import 'package:golden_party_app/ui/layout/responsive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    Size size = const Size(390, 844),
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

  group('نظام التصميم', () {
    test('نقاط الكسر تصنّف العروض تصنيفاً صحيحاً', () {
      expect(Responsive.fromWidth(360), ScreenSize.compact);
      expect(Responsive.fromWidth(599), ScreenSize.compact);
      expect(Responsive.fromWidth(600), ScreenSize.medium);
      expect(Responsive.fromWidth(899), ScreenSize.medium);
      expect(Responsive.fromWidth(900), ScreenSize.expanded);
      expect(Responsive.fromWidth(1440), ScreenSize.expanded);
    });

    test('عدد الأعمدة لا ينزل تحت عمود واحد ولا يزيد عن الحد', () {
      expect(Responsive.gridColumns(320, minItemWidth: 160), 2);
      expect(Responsive.gridColumns(200, minItemWidth: 160), 1);
      expect(Responsive.gridColumns(1200, minItemWidth: 160, max: 3), 3);
      expect(Responsive.gridColumns(0), 1);
      expect(Responsive.gridColumns(double.infinity), 1);
    });

    test('الثيم يستعمل الخط والألوان الموحّدة', () {
      final theme = AppTheme.mithaqTheme;
      expect(theme.colorScheme.primary, AppPalette.green);
      expect(theme.colorScheme.secondary, AppPalette.gold);
      expect(theme.scaffoldBackgroundColor, AppPalette.background);
      expect(theme.navigationBarTheme.indicatorColor, AppPalette.greenSoft);
      expect(theme.textTheme.bodyLarge?.fontFamily, 'Tajawal');
    });
  });

  group('طابع الحالة', () {
    test('يعرف حالات الحجز الحقيقية', () {
      expect(StatusPillFromCode.describe('pending').tone, PillTone.warning);
      expect(StatusPillFromCode.describe('approved').tone, PillTone.success);
      expect(StatusPillFromCode.describe('rejected').tone, PillTone.danger);
      expect(StatusPillFromCode.describe('completed').tone, PillTone.success);
    });

    test('يعرف حالات رغبات الزواج', () {
      expect(
        StatusPillFromCode.describe('awaiting_groom').tone,
        PillTone.gold,
      );
      expect(StatusPillFromCode.describe('matched').tone, PillTone.success);
    });

    test('الحالة المجهولة لا تنهار', () {
      final d = StatusPillFromCode.describe('something_new');
      expect(d.tone, PillTone.neutral);
      expect(d.label, 'something_new');
    });
  });

  testWidgets('طابع الحالة يبقى داخل عرض ضيق', (tester) async {
    await pump(
      tester,
      const Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            StatusPill(
              label: 'بانتظار تحقق الإدارة',
              tone: PillTone.info,
              icon: Icons.hourglass_top_rounded,
            ),
          ],
        ),
      ),
      size: const Size(320, 640),
      textScale: 1.5,
    );

    expect(tester.takeException(), isNull);
    final rect = tester.getRect(find.byType(StatusPill));
    expect(rect.right, lessThanOrEqualTo(320));
    expect(rect.left, greaterThanOrEqualTo(0));
  });

  testWidgets('SectionHeader يحصر عنواناً طويلاً داخل الشاشة', (tester) async {
    await pump(
      tester,
      const SectionHeader(
        title: 'خدمات الأعراس والمناسبات في محافظة دمشق وريفها',
        subtitle: 'قاعات وتصوير وضيافة',
        icon: Icons.celebration_outlined,
      ),
      size: const Size(320, 640),
      textScale: 1.5,
    );

    expect(tester.takeException(), isNull);
    final rect = tester.getRect(find.byType(SectionHeader));
    expect(rect.right, lessThanOrEqualTo(320));
  });

  testWidgets('AdaptiveGrid يزيد الأعمدة على الشاشة العريضة', (tester) async {
    Widget grid() => AdaptiveGrid(
          itemCount: 6,
          minItemWidth: 140,
          itemBuilder: (_, i) => Container(
            key: ValueKey('cell-$i'),
            color: AppPalette.surfaceTint,
          ),
        );

    await pump(tester, grid(), size: const Size(360, 640));
    final narrow = tester.getRect(find.byKey(const ValueKey('cell-1')));
    expect(tester.takeException(), isNull);

    await pump(tester, grid(), size: const Size(900, 700));
    final wide = tester.getRect(find.byKey(const ValueKey('cell-1')));
    expect(tester.takeException(), isNull);

    // على الشاشة العريضة يجب أن يكون العمود الثاني إلى يسار
    // نظيره على الهاتف (أو أوسع)، لأن عدد الأعمدة زاد.
    expect(wide.width, isNot(equals(narrow.width)));
  });

  testWidgets('EmptyState و ErrorState يظهران ويعمل زر الإجراء', (tester) async {
    var tapped = 0;
    await pump(
      tester,
      EmptyState(
        title: 'لا توجد طلبات',
        body: 'ستظهر طلباتك هنا بعد إرسالها.',
        actionLabel: 'ابدأ',
        onAction: () => tapped++,
      ),
    );

    expect(find.text('لا توجد طلبات'), findsOneWidget);
    await tester.tap(find.text('ابدأ'));
    expect(tapped, 1);

    await pump(
      tester,
      ErrorState(
        message: 'تعذّر الاتصال',
        onRetry: () => tapped++,
      ),
    );
    await tester.tap(find.text('إعادة المحاولة'));
    expect(tapped, 2);
  });

  testWidgets('ContentMaxWidth يحدّ العرض على الشاشة العريضة فقط', (tester) async {
    const key = Key('bounded');

    await pump(
      tester,
      const ContentMaxWidth(
        maxWidth: 600,
        child: SizedBox(key: key, height: 40),
      ),
      size: const Size(360, 640),
    );
    expect(tester.getSize(find.byKey(key)).width, lessThanOrEqualTo(360));

    await pump(
      tester,
      const ContentMaxWidth(
        maxWidth: 600,
        child: SizedBox(key: key, height: 40),
      ),
      size: const Size(1200, 800),
    );
    expect(tester.getSize(find.byKey(key)).width, 600);
  });
}
