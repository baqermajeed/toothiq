import 'package:intl/intl.dart';

/// تنسيق السعر بعرض فواصل الآلاف للقراءة السهلة.
/// مثال: 1500000 → "١٬٥٠٠٬٠٠٠ د.ع" أو "1,500,000 د.ع"
String formatPrice(double value) {
  final hasDecimals = value != value.round();
  final formatter = NumberFormat(
    hasDecimals ? '#,###.#' : '#,###',
    'ar',
  );
  final formatted = formatter.format(value);
  return '$formatted د.ع';
}
