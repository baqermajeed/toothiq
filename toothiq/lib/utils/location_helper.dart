import 'package:geolocator/geolocator.dart';

/// حدود تقريبية للعراق — لاكتشاف مواقع المحاكي/الوهمية (مثل Mountain View).
abstract final class IraqLocationBounds {
  static const double minLat = 28.5;
  static const double maxLat = 37.8;
  static const double minLng = 38.0;
  static const double maxLng = 49.5;

  static bool contains(double lat, double lng) {
    return lat >= minLat &&
        lat <= maxLat &&
        lng >= minLng &&
        lng <= maxLng;
  }
}

/// طلب صلاحية الموقع وجلب الإحداثيات الحالية — [lng, lat].
Future<List<double>?> requestAndGetLocation() async {
  try {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      return null;
    }
    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      return null;
    }

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 12),
    );

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: settings,
      );
      return [position.longitude, position.latitude];
    } catch (_) {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        return [last.longitude, last.latitude];
      }
      return null;
    }
  } catch (_) {
    return null;
  }
}
