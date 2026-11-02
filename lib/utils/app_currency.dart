// العملة المعتمدة في GRAND ONE لكل المعاملات المالية.
const String kAppCurrencyCode = 'USD';
const String kAppCurrencySymbol = '\$';

/// يعرض المبلغ مع رمز الدولار، مثل: 12.5 $
String moneyWithCurrency(
  dynamic amount, {
  required String Function(dynamic price) formatPrice,
}) {
  return '${formatPrice(amount)} $kAppCurrencySymbol';
}

/// لاحقة العملة للنصوص الجاهزة.
String get currencySuffix => ' $kAppCurrencySymbol';
