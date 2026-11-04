import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grand_one/screens/event/event_form_screen.dart';
import 'package:grand_one/services/search_date.dart';

void main() {
  tearDown(() => SearchDate.date.value = null);

  testWidgets('نموذج الفعالية: التاريخ إلزامي', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: EventFormScreen(),
        ),
      ),
    );

    await tester.scrollUntilVisible(find.text('إنشاء الفعالية'), 300,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('إنشاء الفعالية'));
    await tester.pump();
    await tester.scrollUntilVisible(find.text('مطلوب'), -300,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('مطلوب'), findsOneWidget);
  });

  testWidgets('تاريخ البحث المختار يُقترح كتاريخ للفعالية', (tester) async {
    final target = DateTime.now().add(const Duration(days: 20));
    SearchDate.date.value = target;
    await tester.pumpWidget(
      const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: EventFormScreen(),
        ),
      ),
    );
    expect(find.text('تاريخ الفعالية *'), findsNothing);
  });

  testWidgets('تعديل مع حجوزات نشطة يقفل التاريخ', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: EventFormScreen(
            existing: {
              'id': 'e1',
              'event_type': 'wedding',
              'event_date': '2027-05-05',
            },
            hasActiveBookings: true,
          ),
        ),
      ),
    );
    expect(find.text('لا يمكن تغيير التاريخ بعد وجود حجوزات نشطة'),
        findsOneWidget);
  });

  test('أنواع الفعاليات تغطي الأنواع السبعة', () {
    expect(kEventTypeLabels.length, 7);
    expect(kEventTypeLabels['wedding'], 'زفاف');
  });
}
