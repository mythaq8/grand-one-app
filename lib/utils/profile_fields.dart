// ============================================================
// profile_fields.dart — قراءة موحّدة لحقول الملف (features + legacy)
// ============================================================

import 'dart:convert';

/// تحويل قيمة JSON/نص إلى Map.
Map<String, dynamic> asJsonMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((k, v) => MapEntry(k.toString(), v));
  }
  if (value is String && value.trim().isNotEmpty) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry(k.toString(), v));
      }
    } catch (_) {}
  }
  return {};
}

/// تحويل قيمة إلى قائمة نصوص.
List<String> asStringList(dynamic value) {
  if (value is List) {
    return value
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
  if (value == null) return [];
  final text = value.toString().trim();
  if (text.isEmpty) return [];
  try {
    final decoded = jsonDecode(text);
    if (decoded is List) {
      return decoded
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
  } catch (_) {}
  return [text];
}

/// قراءة ميزة من features ثم العمود القديم.
String? featureDisplay(
  Map<String, dynamic>? row,
  String key, {
  String? legacyColumn,
}) {
  if (row == null) return null;
  final features = asJsonMap(row['features']);
  final fromFeature = asStringList(features[key]);
  if (fromFeature.isNotEmpty) {
    return fromFeature.join('، ');
  }
  final legacyKey = legacyColumn ?? key;
  final legacy = asStringList(row[legacyKey]);
  if (legacy.isNotEmpty) return legacy.join('، ');
  final raw = row[legacyKey]?.toString().trim();
  if (raw != null && raw.isNotEmpty) return raw;
  return null;
}

/// هل الميزة محددة (غير فارغة)؟
bool hasFeature(
  Map<String, dynamic>? row,
  String key, {
  String? legacyColumn,
}) {
  final text = featureDisplay(row, key, legacyColumn: legacyColumn);
  return text != null && text.trim().isNotEmpty;
}

int? ageFromBirthDate(dynamic birthDate) {
  if (birthDate == null) return null;
  final date = DateTime.tryParse(birthDate.toString());
  if (date == null) return null;
  final now = DateTime.now();
  var age = now.year - date.year;
  if (now.month < date.month ||
      (now.month == date.month && now.day < date.day)) {
    age--;
  }
  return age < 0 ? null : age;
}

String? ageLabel(dynamic birthDate) {
  final age = ageFromBirthDate(birthDate);
  return age == null ? null : '$age سنة';
}

/// تسميات متطلبات الفتاة للعرض.
const Map<String, String> kBrideRequirementLabels = {
  'governorate': 'المحافظة المطلوبة',
  'residence': 'الإقامة المطلوبة',
  'education': 'التعليم المطلوب',
  'education_level': 'التعليم المطلوب',
  'income': 'الدخل المطلوب',
  'age': 'عمر الشاب المطلوب',
  'financial_status': 'الحالة المادية المطلوبة',
  'housing': 'السكن المطلوب',
  'housing_type': 'السكن المطلوب',
  'smoking': 'شرط التدخين',
  'hookah': 'شرط النرجيلة',
  'religious_commitment': 'الالتزام الديني المطلوب',
  'height': 'الطول المطلوب',
  'weight': 'الوزن المطلوب',
  'skin_color': 'لون البشرة المطلوب',
};

/// قائمة صفوف عرض لمتطلبات الفتاة.
List<MapEntry<String, String>> brideRequirementRows(
  Map<String, dynamic>? bride,
) {
  final req = asJsonMap(bride?['requirements']);
  if (req.isEmpty) return const [];

  final rows = <MapEntry<String, String>>[];
  final seen = <String>{};

  for (final entry in req.entries) {
    final key = entry.key;
    // حقل الدين أُزيل من المنتج؛ نتجاهل القيم القديمة إن بقيت في JSON.
    if (key == 'religion') continue;
    final label = kBrideRequirementLabels[key] ?? key;
    if (seen.contains(label)) continue;
    final values = asStringList(entry.value);
    if (values.isEmpty) continue;
    seen.add(label);
    rows.add(MapEntry(label, values.join('، ')));
  }
  return rows;
}

/// مفاتيح ميزات الفتاة المعتمدة في التسجيل.
const List<MapEntry<String, String>> kBrideFeatureKeys = [
  MapEntry('quran_memorization', 'حفظ القرآن'),
  MapEntry('religious_study', 'دراسة شرعية'),
  MapEntry('secured_housing', 'سكن مؤمن'),
  MapEntry('accept_polygamy', 'قبول التعدد'),
  MapEntry('reduced_mahr', 'مهر منخفض'),
  MapEntry('high_financial_status', 'حالة مادية مرتفعة'),
];
