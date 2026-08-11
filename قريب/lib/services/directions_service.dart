import 'dart:math';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// خدمة للحصول على الطريق الفعلي بين نقطتين باستخدام Google Directions API.
class DirectionsService {
  // مفتاح Google Maps API - يجب أن يكون نفس المفتاح المستخدم في التطبيق
  static const String _apiKey = 'AIzaSyCjXpwoOP5-3B_PMP0nKZ0PkIaqwH-667g';
  
  final PolylinePoints _polylinePoints = PolylinePoints();

  /// الحصول على نقاط الطريق بين موقعين.
  /// 
  /// [origin] - نقطة البداية (السائق)
  /// [destination] - نقطة الوصول (العميل/التوصيل)
  /// 
  /// يُرجع قائمة من LatLng للطريق الفعلي، أو null في حالة الفشل.
  Future<List<LatLng>?> getRouteBetweenPoints({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      final result = await _polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: _apiKey,
        request: PolylineRequest(
          origin: PointLatLng(origin.latitude, origin.longitude),
          destination: PointLatLng(destination.latitude, destination.longitude),
          mode: TravelMode.driving,
        ),
      );

      if (result.points.isNotEmpty) {
        return result.points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();
      }
      
      return null;
    } catch (e) {
      // في حالة الفشل (مثلاً عدم توفر الإنترنت)، نُرجع null
      // وسيتم استخدام خط مستقيم كبديل
      return null;
    }
  }

  /// حساب المسافة التقريبية بين نقطتين (بالكيلومترات).
  double calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // نصف قطر الأرض بالكيلومترات
    
    final lat1Rad = point1.latitude * (pi / 180);
    final lat2Rad = point2.latitude * (pi / 180);
    final deltaLat = (point2.latitude - point1.latitude) * (pi / 180);
    final deltaLng = (point2.longitude - point1.longitude) * (pi / 180);

    final a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLng / 2) * sin(deltaLng / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }
}
