class PhoneValidator {
  /// يقبل أرقام عراقية: 07xxxxxxxxx أو 7xxxxxxxxx
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
}
