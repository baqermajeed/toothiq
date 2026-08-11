import 'package:geolocator/geolocator.dart';

/// طلب صلاحية الموقع وجلب الإحداثيات الحالية.
/// يُرجع [lng, lat] عند النجاح أو null عند الفشل/الرفض.
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
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
    );
    return [position.longitude, position.latitude];
  } catch (_) {
    return null;
  }
}
