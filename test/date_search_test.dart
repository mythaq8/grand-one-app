import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grand_one/screens/services/widgets/availability_badges.dart';
import 'package:grand_one/services/search_date.dart';

void main() {
  tearDown(() => SearchDate.date.value = null);

  test('SearchDate يعيد التاريخ بصيغة ISO', () {
    expect(SearchDate.iso, isNull);
    SearchDate.date.value = DateTime(2027, 3, 5);
    expect(SearchDate.iso, '2027-03-05');
  });

  testWidgets('الشارات: متاح + مميّز + موثّق', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AvailabilityBadges(
            availableOnDate: true,
            badges: ['verified', 'featured'],
          ),
        ),
      ),
    );
    expect(find.text('متاح في تاريخك'), findsOneWidget);
    expect(find.text('مميّز'), findsOneWidget);
    expect(find.text('موثّق'), findsOneWidget);
    expect(find.text('الأكثر حجزاً'), findsNothing);
  });

  testWidgets('بلا تاريخ ولا شارات لا يظهر شيء', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AvailabilityBadges())),
    );
    expect(find.byType(Container), findsNothing);
  });

  testWidgets('غير متاح يظهر بنص واضح', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AvailabilityBadges(availableOnDate: false)),
      ),
    );
    expect(find.text('غير متاح في تاريخك'), findsOneWidget);
  });
}
