import 'package:flutter_test/flutter_test.dart';
import 'package:grand_one/screens/event/event_planning_tab.dart';

void main() {
  test('المهام: العنوان والاستحقاق', () {
    expect(kTasksKind.titleOf({'title': 'حجز القاعة'}), 'حجز القاعة');
    expect(kTasksKind.subtitleOf!({'due_date': null}), isNull);
    expect(kTasksKind.subtitleOf!({'due_date': '2027-03-05'}), 'قبل 5 مارس 2027');
    expect(kTasksKind.checkField, 'is_done');
  });

  test('الجدول: الوقت يُقصّ إلى HH:MM', () {
    expect(
      kTimelineKind.titleOf({'start_time': '18:30:00', 'title': 'دخول العروسين'}),
      '18:30  دخول العروسين',
    );
  });

  test('الميزانية: فئة وتقدير وفعلي', () {
    final sub = kBudgetKind.subtitleOf!({
      'category': 'photo',
      'estimated_usd': 300,
      'actual_usd': 250.5,
    });
    expect(sub, 'التصوير • تقدير 300 \$ • فعلي 250.50 \$');
    expect(kBudgetKind.checkField, 'is_paid');
    expect(kBudgetCategories.keys, containsAll(['venue', 'photo', 'decor', 'rental', 'gifts', 'other']));
  });

  test('الإلهام: الملاحظة والرابط معاً', () {
    final sub = kInspirationKind.subtitleOf!({'note': 'ألوان ذهبية', 'link_url': 'https://x.test/a'});
    expect(sub, 'ألوان ذهبية\nhttps://x.test/a');
    expect(kInspirationKind.subtitleOf!({'note': null, 'link_url': null}), isNull);
  });
}
