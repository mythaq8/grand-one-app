import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mithaq_app/app_theme.dart';
import 'package:mithaq_app/design/tokens.dart';
import 'package:mithaq_app/screens/services/widgets/results_grid.dart';
import 'package:mithaq_app/screens/services/widgets/service_cards.dart';

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

  group('بطاقة الخدمة', () {
    testWidgets('شكل القائمة لا يفيض على شاشة 320 مع خط 1.5',
        (tester) async {
      await pumpAt(
        tester,
        Padding(
          padding: const EdgeInsets.all(Space.sm),
          child: ServiceCard(
            name: 'قاعة أفراح كبيرة للمناسبات والأعراس',
            priceLabel: 'يبدأ من 1200 \$ للحجز الكامل',
            governorate: 'دمشق',
            location: 'المزة',
            rating: 4.6,
            reviewsCount: 24,
            onTap: () {},
          ),
        ),
        size: const Size(320, 640),
        textScale: 1.5,
      );

      expect(tester.takeException(), isNull);
      final rect = tester.getRect(find.byType(ServiceCard));
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(320));
    });

    testWidgets('الشكل المدمج يعرض الاسم والسعر', (tester) async {
      await pumpAt(
        tester,
        SizedBox(
          width: 300,
          height: 260,
          child: ServiceCard(
            compact: true,
            name: 'تصوير أعراس',
            priceLabel: '250 \$',
            governorate: 'دمشق',
            rating: 4.2,
            onTap: () {},
          ),
        ),
        size: const Size(360, 640),
      );

      expect(find.text('تصوير أعراس'), findsOneWidget);
      expect(find.text('250 \$'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('الشكل المدمج يصمد داخل خلية شبكة ضيقة مع خط 1.5',
        (tester) async {
      await pumpAt(
        tester,
        SizedBox(
          width: 170,
          height: 416,
          child: ServiceCard(
            compact: true,
            name: 'قاعة أفراح للمناسبات الكبيرة في دمشق',
            priceLabel: 'يبدأ من 1200 \$',
            governorate: 'دمشق',
            location: 'المزة',
            rating: 4.9,
            reviewsCount: 120,
            isBookable: false,
            onTap: () {},
          ),
        ),
        size: const Size(360, 640),
        textScale: 1.5,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('الخدمة غير المتاحة تُظهر تنبيهاً واضحاً', (tester) async {
      await pumpAt(
        tester,
        SizedBox(
          width: 320,
          child: ServiceCard(
            name: 'خدمة موقوفة',
            priceLabel: '',
            isBookable: false,
            onTap: () {},
          ),
        ),
        size: const Size(360, 640),
      );

      expect(find.text('غير متاح للحجز حالياً'), findsOneWidget);
    });

    testWidgets('التقييم الصفري لا يرسم شارة فارغة', (tester) async {
      await pumpAt(
        tester,
        const SizedBox(
          width: 120,
          child: RatingBadge(rating: 0, reviewsCount: 0),
        ),
        size: const Size(360, 640),
      );

      expect(find.byType(RatingBadge), findsOneWidget);
      expect(find.text('0.0'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('شبكة النتائج', () {
    Widget grid({int count = 6}) => ResultsGrid(
          itemCount: count,
          onRefresh: () async {},
          itemBuilder: (_, i) => ServiceCard(
            name: 'خدمة رقم $i',
            priceLabel: '100 \$',
            onTap: () {},
          ),
        );

    testWidgets('تعمل على الهاتف بشاشة 360', (tester) async {
      await pumpAt(tester, grid(), size: const Size(360, 640));
      expect(tester.takeException(), isNull);
      expect(find.text('خدمة رقم 0'), findsOneWidget);
    });

    testWidgets('تعمل على التابلت 900 بلا أخطاء', (tester) async {
      await pumpAt(tester, grid(), size: const Size(900, 1280));
      expect(tester.takeException(), isNull);
      expect(find.text('خدمة رقم 0'), findsOneWidget);
    });

    testWidgets('الحالة الفارغة لا تبني أي بطاقة', (tester) async {
      await pumpAt(tester, grid(count: 0), size: const Size(360, 640));
      expect(tester.takeException(), isNull);
      expect(find.byType(ServiceCard), findsNothing);
    });
  });

  group('بطاقة المزود', () {
    testWidgets('تظهر علامة التوثيق وتصمد على شاشة ضيقة', (tester) async {
      await pumpAt(
        tester,
        Padding(
          padding: const EdgeInsets.all(Space.sm),
          child: ProviderCard(
            name: 'مؤسسة النور للتصوير',
            governorate: 'دمشق',
            description: 'تصوير أعراس ومناسبات بجودة عالية',
            rating: 4.8,
            reviewsCount: 12,
            isVerified: true,
            onTap: () {},
          ),
        ),
        size: const Size(320, 640),
        textScale: 1.4,
      );

      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
      final rect = tester.getRect(find.byType(ProviderCard));
      expect(rect.right, lessThanOrEqualTo(320));
    });
  });
}
