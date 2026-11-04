import 'package:flutter/foundation.dart';

/// تاريخ مناسبة العميل المختار للبحث (في الذاكرة فقط).
/// الرئيسية تضبطه، وشاشة الخدمات تستمع له وتعيد التحميل.
class SearchDate {
  SearchDate._();

  static final ValueNotifier<DateTime?> date = ValueNotifier<DateTime?>(null);

  static String? get iso {
    final d = date.value;
    if (d == null) return null;
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
