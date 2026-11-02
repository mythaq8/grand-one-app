// lib/utils/chat_filter.dart
// ============================================================
// ChatFilter — فلتر رسائل المحادثة الشرعية
// ============================================================

class ChatFilter {
  final bool allowed;
  final String? reason;
  final String? violationType;

  const ChatFilter({
    required this.allowed,
    this.reason,
    this.violationType,
  });

  // ============================================================
  // Regex patterns (static — لا يُعاد بناؤها في كل استدعاء)
  // ============================================================

  static final RegExp _emailPattern = RegExp(
    r'[\w\.-]+@[\w\.-]+\.\w+',
  );

  static final RegExp _urlPattern = RegExp(
    r'(https?://|www\.)\S+',
    caseSensitive: false,
  );

  /// رقم هاتف سوري:
  /// - 09XXXXXXXX (10 أرقام)
  /// - 9XXXXXXXX (بدون 0)
  /// - +9639XXXXXXXX
  /// - 009639XXXXXXXX
  static final RegExp _syrianPhonePattern = RegExp(
    r'(\+?963|00963)?[\s-]?9[\s-]?\d[\s-]?\d[\s-]?\d[\s-]?\d[\s-]?\d[\s-]?\d[\s-]?\d[\s-]?\d',
  );

  /// رقم هاتف دولي:
  /// - +XXXXXXXXXX (10-15 رقم)
  static final RegExp _internationalPattern = RegExp(
    r'\+\d[\d\s-]{9,14}',
  );

  /// أرقام طويلة متتالية (12+ رقم):
  /// أرقام هواتف فعلية — لا أسعار ولا تواريخ
  static final RegExp _longNumberPattern = RegExp(
    r'\d{12,}',
  );

  /// الرموز غير المرئية والتحكمية
  static final RegExp _invisibleCharsPattern = RegExp(
    r'[\u200B-\u200F\u202A-\u202E\uFEFF]',
  );

  /// المسافات المتعددة
  static final RegExp _multiSpacePattern = RegExp(r'\s+');

  // ============================================================
  // قوائم ثابتة
  // ============================================================

  /// كلمات وسائل التواصل الاجتماعي
  static const List<String> _socialWords = [
    // ═══ تطبيقات الدردشة ═══
    'واتساب', 'واتس', 'whatsapp', 'whats',
    'تيليغرام', 'تليغرام', 'telegram',
    'فايبر', 'viber',
    'إيمو', 'imo',
    'سيجنال', 'signal',
    'لاين', 'line',
    'كاكاو', 'kakao',
    'وي تشات', 'wechat',

    // ═══ شبكات التواصل ═══
    'فيسبوك', 'فيس بوك', 'facebook', 'fb',
    'انستغرام', 'انستقرام', 'انستا', 'instagram', 'insta',
    'سناب', 'سنابشات', 'snapchat', 'snap',
    'تويتر', 'twitter', 'x.com',
    'ماسنجر', 'messenger',
    'تيك توك', 'تيكتوك', 'tiktok',
    'ديسكورد', 'discord',

    // ═══ عبارات صريحة لتبادل الأرقام ═══
    'رقمي هو', 'رقمي:', 'رقم هاتفي', 'رقم جوالي',
    'رقم موبايلي', 'رقم تلفوني', 'رقم واتسابي',
    'my number', 'my phone', 'my whatsapp',
    'أعطني رقمك', 'اعطني رقمك', 'اعطيني رقمك',
    'give me your number',

    // ═══ أفعال الاتصال الصريحة ═══
    'اتصل بي', 'كلمني على', 'راسلني على',
    'call me', 'text me', 'message me on',
  ];

  /// ألفاظ غير لائقة
  static const List<String> _badWords = [
    // ═══ ألفاظ تحقيرية ═══
    'غبي', 'غبية', 'أغبى',
    'أحمق', 'حمقاء',
    'تافه', 'تافهة',
    'حقير', 'حقيرة',
    'سخيف', 'سخيفة',
    'مجنون', 'مجنونة',
    'معتوه', 'معتوهة',
    'أبله', 'بلهاء',

    // ═══ ألفاظ مسيئة ═══
    'كلب', 'كلبة',
    'حمار', 'حمارة',
    'خنزير', 'خنزيرة',
    'قذر', 'قذرة',
    'وسخ', 'وسخة',

    // ═══ ألفاظ الكذب ═══
    'كذاب', 'كذابة',
    'نصاب', 'نصابة',
    'محتال', 'محتالة',

    // ═══ ألفاظ عامية ═══
    'زفت',
    'خرا',
    'لعنة',
    'يلعن',
  ];

  // ============================================================
  // تنظيف النص
  // ============================================================

  /// تنظيف النص من:
  /// - Arabic tatweel (ـ)
  /// - الرموز غير المرئية (RTL/LTR marks, zero-width spaces)
  /// - المسافات المتعددة
  static String _normalize(String text) {
    return text
        // إزالة الـ tatweel العربي (U+0640)
        .replaceAll('\u0640', '')
        // إزالة الرموز غير المرئية
        .replaceAll(_invisibleCharsPattern, '')
        // تحويل المسافات المتعددة إلى مسافة واحدة
        .replaceAll(_multiSpacePattern, ' ')
        .trim();
  }

  // ============================================================
  // الفحص الرئيسي
  // ============================================================

  static ChatFilter validate(String text) {
    final trimmed = text.trim();

    // ═══ فحص الحجم الأدنى (قبل كل شيء) ═══
    if (trimmed.length < 2) {
      return const ChatFilter(
        allowed: false,
        reason: '⚠️ الرسالة قصيرة جداً.',
        violationType: 'short_message',
      );
    }

    // ═══ تنظيف النص للفحوصات التالية ═══
    final normalized = _normalize(trimmed);
    final lower = normalized.toLowerCase();
    final hardened = _hardened(trimmed);
    if (!hardened.allowed) return hardened;

    // ============================================================
    // 1. فحص البريد الإلكتروني
    // ============================================================
    if (_emailPattern.hasMatch(normalized)) {
      return const ChatFilter(
        allowed: false,
        reason: '🚫 يمنع ذكر البريد الإلكتروني.',
        violationType: 'email',
      );
    }

    // ============================================================
    // 2. فحص الروابط
    // ============================================================
    if (_urlPattern.hasMatch(normalized)) {
      return const ChatFilter(
        allowed: false,
        reason: '🚫 يمنع ذكر الروابط.',
        violationType: 'url',
      );
    }

    // ============================================================
    // 3. فحص أرقام الهاتف
    // ============================================================
    if (_syrianPhonePattern.hasMatch(normalized) ||
        _internationalPattern.hasMatch(normalized) ||
        _longNumberPattern.hasMatch(normalized)) {
      return const ChatFilter(
        allowed: false,
        reason: '🚫 يمنع تبادل الأرقام في المحادثة.',
        violationType: 'phone_number',
      );
    }

    // ============================================================
    // 4. فحص وسائل التواصل
    // ============================================================
    for (final word in _socialWords) {
      if (lower.contains(word.toLowerCase())) {
        return const ChatFilter(
          allowed: false,
          reason: '🚫 يمنع ذكر وسائل التواصل.',
          violationType: 'social_media',
        );
      }
    }

    // ============================================================
    // 5. فحص الألفاظ غير اللائقة
    // ============================================================
    for (final word in _badWords) {
      if (lower.contains(word.toLowerCase())) {
        return const ChatFilter(
          allowed: false,
          reason: '🚫 يمنع استخدام الألفاظ غير اللائقة.',
          violationType: 'bad_word',
        );
      }
    }

    // ═══ اجتاز جميع الفحوصات ═══
    return const ChatFilter(allowed: true);
  }

  static String _prepare(String text) {
    final buffer = StringBuffer();
    for (final rune in text.runes) {
      final char = String.fromCharCode(rune);
      const arabicDigits = '٠١٢٣٤٥٦٧٨٩';
      const persianDigits = '۰۱۲۳۴۵۶۷۸۹';
      final arabicIndex = arabicDigits.indexOf(char);
      if (arabicIndex >= 0) {
        buffer.write(arabicIndex);
        continue;
      }
      final persianIndex = persianDigits.indexOf(char);
      if (persianIndex >= 0) {
        buffer.write(persianIndex);
        continue;
      }
      buffer.write(switch (char) {
        'أ' || 'إ' || 'آ' || 'ٱ' => 'ا',
        'ة' => 'ه',
        'ى' || 'ئ' => 'ي',
        'ؤ' => 'و',
        _ => char,
      });
    }
    return buffer
        .toString()
        .replaceAll(RegExp(r'[\u0640\u064B-\u0652\u061C\u200B-\u200F\u202A-\u202E\uFEFF]'), '')
        .replaceAll(RegExp(r'[\u2000-\u200A\u202F\u205F\u3000\u00A0]'), ' ')
        .toLowerCase();
  }

  static String _lettersOnly(String prepared) {
    final mapped = prepared
        .replaceAll('4', 'a')
        .replaceAll('3', 'e')
        .replaceAll('1', 'i')
        .replaceAll('0', 'o')
        .replaceAll('5', 's')
        .replaceAll('7', 't');
    return mapped
        .replaceAll(RegExp(r'[^a-z\u0621-\u064A]'), '')
        .replaceAllMapped(RegExp(r'(.)\1{2,}'), (match) => match.group(1)!);
  }

  static const List<(String, String)> _numberWords = [
    ('صفر', '0'),
    ('زيرو', '0'),
    ('واحد', '1'),
    ('اثنين', '2'),
    ('اثنان', '2'),
    ('ثلاثه', '3'),
    ('اربعه', '4'),
    ('خمسه', '5'),
    ('سته', '6'),
    ('سبعه', '7'),
    ('ثمانيه', '8'),
    ('ثماني', '8'),
    ('تسعه', '9'),
    ('zero', '0'),
    ('one', '1'),
    ('two', '2'),
    ('three', '3'),
    ('four', '4'),
    ('five', '5'),
    ('six', '6'),
    ('seven', '7'),
    ('eight', '8'),
    ('nine', '9'),
  ];

  static int _matchNumberWord(String source, int index) {
    var best = 0;
    for (final entry in _numberWords) {
      if (entry.$1.length > best && source.startsWith(entry.$1, index)) {
        best = entry.$1.length;
      }
    }
    return best;
  }

  static String _digitOfWord(String source, int index, int length) {
    final slice = source.substring(index, index + length);
    for (final entry in _numberWords) {
      if (entry.$1 == slice) return entry.$2;
    }
    return '';
  }

  static String _spelledIfPure(String letters) {
    if (letters.isEmpty) return '';
    var index = 0;
    final out = StringBuffer();
    while (index < letters.length) {
      final length = _matchNumberWord(letters, index);
      if (length == 0) return '';
      out.write(_digitOfWord(letters, index, length));
      index += length;
    }
    return out.toString();
  }

  static String _messageDigits(String text) {
    final prepared = _prepare(text);
    final tokens = prepared
        .replaceAll(RegExp(r'[^0-9a-z\u0621-\u064A]+'), ' ')
        .trim()
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty);

    final out = StringBuffer();
    var letterBuf = '';
    void flush() {
      final pure = _spelledIfPure(letterBuf.replaceAll(RegExp(r'[^a-z\u0621-\u064A]'), ''));
      if (pure.isNotEmpty) out.write(pure);
      letterBuf = '';
    }

    for (final token in tokens) {
      if (RegExp(r'^[0-9]+$').hasMatch(token)) {
        flush();
        out.write(token);
        continue;
      }
      final wordLength = _matchNumberWord(token, 0);
      if (wordLength == token.length) {
        flush();
        out.write(_digitOfWord(token, 0, wordLength));
        continue;
      }
      if (token.length == 1 && RegExp(r'^[a-z\u0621-\u064A]$').hasMatch(token)) {
        letterBuf += token;
        continue;
      }
      flush();
      for (final part in RegExp(r'[0-9]+|[^0-9]+').allMatches(token)) {
        final value = part.group(0)!;
        if (RegExp(r'^[0-9]+$').hasMatch(value)) {
          flush();
          out.write(value);
        } else {
          letterBuf += value;
          flush();
        }
      }
    }
    flush();
    return out.toString();
  }

  static bool _isPhone(String digits) {
    if (digits.length >= 10) return true;
    if (digits.length == 9 && digits.startsWith('9')) return true;
    if (digits.length == 8 && digits.startsWith('9')) return true;
    return false;
  }

  static ChatFilter _hardened(String text) {
    final prepared = _prepare(text);
    final spaced = prepared.replaceAll(RegExp(r'\s+'), ' ').trim();
    final letters = _lettersOnly(prepared);
    final compact = spaced.replaceAll(' ', '');
    final digits = _messageDigits(text);

    if (RegExp(r'[\w.+-]+@[\w.-]+\.[a-z]{2,}').hasMatch(spaced) ||
        ['gmail', 'hotmail', 'yahoo', 'outlook', 'icloud', 'proton']
            .any(letters.contains)) {
      return const ChatFilter(
        allowed: false,
        reason: '🚫 يمنع ذكر البريد الإلكتروني.',
        violationType: 'email',
      );
    }

    if (compact.contains('http://') ||
        compact.contains('https://') ||
        compact.contains('www.') ||
        RegExp(r'(?:^|[^a-z0-9])(?:t|wa)\.me(?:/|$)').hasMatch(compact) ||
        RegExp(r'[a-z0-9][a-z0-9-]{1,}\.(?:com|net|org|me|io|app|ly|info|link|xyz)(?:[^a-z]|$)')
            .hasMatch(compact)) {
      return const ChatFilter(
        allowed: false,
        reason: '🚫 يمنع ذكر الروابط.',
        violationType: 'url',
      );
    }

    if (_isPhone(digits)) {
      return const ChatFilter(
        allowed: false,
        reason: '🚫 يمنع تبادل الأرقام في المحادثة.',
        violationType: 'phone_number',
      );
    }

    const stems = [
      'whatsapp', 'watsapp', 'telegram', 'instagram', 'snapchat', 'tiktok',
      'facebook', 'viber', 'واتساب', 'واتس', 'تيليغرام', 'تليغرام', 'انستا',
      'فيسبوك', 'سناب', 'فايبر', 'رقميهو', 'اتصلبي',
    ];
    if (stems.any((stem) => letters.contains(_lettersOnly(_prepare(stem))))) {
      return const ChatFilter(
        allowed: false,
        reason: '🚫 يمنع ذكر وسائل التواصل.',
        violationType: 'social_media',
      );
    }

    if (_badWords.any((word) => letters.contains(_lettersOnly(_prepare(word))))) {
      return const ChatFilter(
        allowed: false,
        reason: '🚫 يمنع استخدام الألفاظ غير اللائقة.',
        violationType: 'bad_word',
      );
    }

    return const ChatFilter(allowed: true);
  }
}