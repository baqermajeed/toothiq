/// تحويل تاريخ الانتهاء المُدخل يدوياً إلى صيغة يقبلها السيرفر.
class ExpiryDateUtils {
  static String? fromDateTime(DateTime? date) {
    if (date == null) return null;
    return _formatDate(date);
  }

  static DateTime? parseToDateTime(String? raw) {
    final api = toApiValue(raw);
    if (api == null) return null;
    return DateTime.tryParse(api);
  }

  static String formatForPicker(DateTime date) {
    return '${date.day} / ${date.month} / ${date.year}';
  }

  static String? toApiValue(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;

    final input = raw.trim().replaceAll(RegExp(r'\s+'), '');

    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(input)) {
      return input;
    }

    final parsed = DateTime.tryParse(input);
    if (parsed != null) {
      return _formatDate(parsed);
    }

    final monthYear = RegExp(r'^(\d{1,2})[/.-](\d{4})$').firstMatch(input);
    if (monthYear != null) {
      final month = int.tryParse(monthYear.group(1)!);
      final year = int.tryParse(monthYear.group(2)!);
      if (month != null && year != null && month >= 1 && month <= 12) {
        return _formatDate(DateTime(year, month + 1, 0));
      }
    }

    final dayMonthYear = RegExp(r'^(\d{1,2})[/.-](\d{1,2})[/.-](\d{4})$')
        .firstMatch(input);
    if (dayMonthYear != null) {
      final day = int.tryParse(dayMonthYear.group(1)!);
      final month = int.tryParse(dayMonthYear.group(2)!);
      final year = int.tryParse(dayMonthYear.group(3)!);
      if (day != null && month != null && year != null) {
        final date = DateTime(year, month, day);
        if (date.year == year && date.month == month && date.day == day) {
          return _formatDate(date);
        }
      }
    }

    return null;
  }

  static String? toDisplayValue(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final parsed = DateTime.tryParse(raw.trim());
    if (parsed == null) return raw.trim();
    return formatForPicker(parsed);
  }

  static String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
