import 'package:flutter_test/flutter_test.dart';
import 'package:mithaq_app/utils/chat_filter.dart';

void main() {
  test('ordinary chat stays allowed', () {
    expect(ChatFilter.validate('السلام عليكم، كيف حالك؟').allowed, isTrue);
    expect(ChatFilter.validate('عمري 25 وطولي 170').allowed, isTrue);
    expect(ChatFilter.validate('المهر حوالي 5000000').allowed, isTrue);
  });

  test('hidden phone numbers are blocked', () {
    expect(ChatFilter.validate('٠٩٩١٢٣٤٥٦٧').violationType, 'phone_number');
    expect(ChatFilter.validate('09.91.234.567').violationType, 'phone_number');
    expect(
      ChatFilter.validate('صفر تسعة تسعة واحد اثنين ثلاثة أربعة خمسة ستة سبعة')
          .violationType,
      'phone_number',
    );
  });

  test('separated contact words and insults are blocked', () {
    expect(ChatFilter.validate('راسلني و ا ت س ا ب').violationType, 'social_media');
    expect(ChatFilter.validate('غ ب ي').violationType, 'bad_word');
    expect(ChatFilter.validate('حسابي t.me/example').violationType, 'url');
  });
}
