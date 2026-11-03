import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grand_one/screens/work/work_booking_form_screen.dart';
import 'package:grand_one/screens/work/work_formatters.dart';

void main() {
  group('تنسيقات أداة التنظيم', () {
    test('المبلغ بالدولار بلا كسور زائدة', () {
      expect(workMoney(150), '150 \$');
      expect(workMoney(12.5), '12.50 \$');
      expect(workMoney(null), '0 \$');
    });

    test('التاريخ والوقت', () {
      expect(workDate('2027-03-05'), '5 مارس 2027');
      expect(workDate(null), '-');
      expect(workIsoDate(DateTime(2027, 3, 5)), '2027-03-05');
      expect(workTime('18:30:00'), '18:30');
      expect(workTime(null), '');
    });
  });

  group('نموذج الحجز الخارجي', () {
    testWidgets('الحقول الثلاثة الإلزامية تمنع الحفظ', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: WorkBookingFormScreen(canBlockCalendar: true),
          ),
        ),
      );

      await tester.scrollUntilVisible(find.text('إضافة الحجز'), 300,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('إضافة الحجز'));
      await tester.pump();

      await tester.scrollUntilVisible(find.text('اسم العميل مطلوب'), -300,
          scrollable: find.byType(Scrollable).first);
      expect(find.text('اسم العميل مطلوب'), findsOneWidget);
      expect(find.text('مطلوب'), findsWidgets);
    });

    testWidgets('خيار إغلاق التقويم يظهر للمزوّد فقط', (tester) async {
      Future<void> pump(bool canBlock) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: WorkBookingFormScreen(canBlockCalendar: canBlock),
            ),
          ),
        );
        await tester.scrollUntilVisible(find.text('إضافة الحجز'), 300,
            scrollable: find.byType(Scrollable).first);
      }

      await pump(true);
      expect(find.text('إغلاق هذا التاريخ أمام عملاء التطبيق'), findsOneWidget);
      await pump(false);
      expect(find.text('إغلاق هذا التاريخ أمام عملاء التطبيق'), findsNothing);
    });
  });
}
