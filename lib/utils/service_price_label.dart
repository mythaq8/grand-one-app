import 'app_currency.dart';

/// تسمية سعر واضحة حسب نموذج التسعير (قائمة / بطاقة / تفاصيل).
String servicePriceLabel(
  Map<String, dynamic>? service, {
  required String Function(dynamic price) formatPrice,
}) {
  if (service == null) return '';

  final model = service['pricing_model']?.toString() ?? 'fixed_package';

  if (model == 'quote_request') {
    return 'حسب العرض';
  }

  if (model == 'per_unit') {
    final unitRaw = service['unit_label']?.toString().trim() ?? '';
    final unit = unitRaw.isEmpty ? 'شخص' : unitRaw;
    final price = service['unit_price'] ?? service['base_price'];
    if (price == null) return '';
    final n = _toDouble(price);
    if (n <= 0 && service['unit_price'] == null) return '';
    return '${moneyWithCurrency(price, formatPrice: formatPrice)} / $unit';
  }

  if (model == 'per_duration') {
    final unit = service['duration_unit']?.toString() ?? 'day';
    final unitAr = unit == 'hour'
        ? 'ساعة'
        : unit == 'night'
            ? 'ليلة'
            : 'يوم';
    final price = service['duration_price'] ?? service['base_price'];
    if (price == null) return '';
    return '${moneyWithCurrency(price, formatPrice: formatPrice)} / $unitAr';
  }

  final price = service['base_price'];
  if (price == null) return '';
  return moneyWithCurrency(price, formatPrice: formatPrice);
}

bool serviceHasDisplayablePrice(Map<String, dynamic>? service) {
  if (service == null) return false;
  final label = servicePriceLabel(
    service,
    formatPrice: (p) => p.toString(),
  );
  return label.isNotEmpty;
}

double _toDouble(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse(v?.toString() ?? '') ?? 0;
}
