import 'package:flutter_test/flutter_test.dart';
import 'package:grand_one/ui/kit/status_pill.dart';

void main() {
  group('دورة الطلب', () {
    test('حالة التعديل المقترح لها تسمية خاصة', () {
      expect(
        StatusPillFromCode.describe('modification_proposed').label,
        'تعديل مقترح',
      );
    });

    test('انتهاء المهلة يبقى حالة معروفة', () {
      expect(StatusPillFromCode.describe('expired').label, 'انتهت المهلة');
    });
  });
}
