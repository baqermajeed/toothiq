/// وقت التوصيل المتوقع يظهر فقط داخل محافظة النجف.
abstract final class DeliveryEta {
  static const najafText = '45 د - ساعة';
  static const fieldLabel = 'الوقت المتوقع للتوصيل :';

  static bool isNajaf({
    String? governorate,
    String? governorateId,
    String? addressLine,
  }) {
    final id = (governorateId ?? '').trim().toLowerCase();
    if (id == 'najaf') return true;

    final name = (governorate ?? '').trim();
    if (_looksLikeNajaf(name)) return true;

    final address = (addressLine ?? '').trim();
    return _looksLikeNajaf(address);
  }

  static String? textFor({
    String? governorate,
    String? governorateId,
    String? addressLine,
  }) {
    if (!isNajaf(
      governorate: governorate,
      governorateId: governorateId,
      addressLine: addressLine,
    )) {
      return null;
    }
    return najafText;
  }

  static bool _looksLikeNajaf(String value) {
    if (value.isEmpty) return false;
    final normalized = value.toLowerCase();
    return value.contains('نجف') ||
        normalized.contains('najaf') ||
        normalized.contains('al-najaf');
  }
}
