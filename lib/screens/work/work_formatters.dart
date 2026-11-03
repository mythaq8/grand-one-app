/// تنسيقات مشتركة لأداة تنظيم العمل.

String workMoney(dynamic value) {
  final n = value is num ? value : num.tryParse('$value') ?? 0;
  final text = n == n.roundToDouble() ? n.toInt().toString() : n.toStringAsFixed(2);
  return '$text \$';
}

const List<String> _arMonths = [
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

/// يحوّل YYYY-MM-DD إلى «5 مارس 2027».
String workDate(String? iso) {
  if (iso == null || iso.length < 10) return '-';
  final d = DateTime.tryParse(iso.substring(0, 10));
  if (d == null) return iso;
  return '${d.day} ${_arMonths[d.month - 1]} ${d.year}';
}

String workIsoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// يقصّ HH:MM:SS إلى HH:MM.
String workTime(String? t) => (t == null || t.length < 5) ? '' : t.substring(0, 5);
