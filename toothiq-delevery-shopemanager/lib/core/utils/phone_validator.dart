class PhoneValidator {
  static bool isValidIraqiPhone(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11 && digits.startsWith('07')) return true;
    if (digits.length == 10 && digits.startsWith('7')) return true;
    return false;
  }

  static String normalize(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10 && digits.startsWith('7')) {
      return '0$digits';
    }
    return digits;
  }

  /// يحول الرقم العراقي إلى صيغة واتساب الدولية بدون + (مثل 9647XXXXXXXXX).
  static String toWhatsAppNumber(String input) {
    var digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('00')) {
      digits = digits.substring(2);
    }
    if (digits.startsWith('964')) {
      return digits;
    }
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    return '964$digits';
  }
}
