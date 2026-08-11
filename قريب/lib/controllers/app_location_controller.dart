import 'package:get/get.dart';

/// يحفظ إحداثيات موقع الضيف أو المستخدم عند عدم وجود مصادقة.
/// يُستخدم لتمرير الموقع لطلبات المحلات (getShops) والمنتجات.
class AppLocationController extends GetxController {
  final Rxn<double> _lng = Rxn<double>();
  final Rxn<double> _lat = Rxn<double>();

  double? get lng => _lng.value;
  double? get lat => _lat.value;

  bool get hasLocation => _lng.value != null && _lat.value != null;

  /// إحداثيات [lng, lat] أو null.
  List<double>? get coordinates =>
      (hasLocation) ? [_lng.value!, _lat.value!] : null;

  void setLocation(double lng, double lat) {
    _lng.value = lng;
    _lat.value = lat;
  }

  void clear() {
    _lng.value = null;
    _lat.value = null;
  }
}
