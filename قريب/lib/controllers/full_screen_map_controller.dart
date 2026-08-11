import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../core/theme/app_colors.dart';
import '../services/directions_service.dart';
import '../services/driver_tracking_socket_service.dart';
import '../utils/map_debug_logger.dart';
import '../utils/map_marker_helper.dart';

/// وضع الخريطة: عرض فقط (تفاصيل الطلب) أو اختيار موقع (تعديل الملف).
enum FullScreenMapMode { view, pick }

/// Controller لشاشة الخريطة بحجم كامل.
/// في وضع [pick] يُحدَّث الموقع من النقر ويُرجع عند التأكيد.
class FullScreenMapController extends GetxController {
  final initialLat = Rxn<double>();
  final initialLng = Rxn<double>();
  final mode = FullScreenMapMode.view.obs;

  /// موقع السائق (لوضع view من تفاصيل الطلب). اختياري.
  final driverLat = Rxn<double>();
  final driverLng = Rxn<double>();
  /// تفاصيل السائق للعرض في وضع التتبع (اسم، هاتف، صورة).
  final driverName = Rxn<String>();
  final driverPhone = Rxn<String>();
  final driverPhoto = Rxn<String>();

  /// مواقع المحلات التي طلب منها (لوضع view). كل عنصر: {lat, lng, name?}.
  final shopLocations = <Map<String, dynamic>>[].obs;

  /// الموقع المُختار (لوضع pick).
  final selectedLat = Rxn<double>();
  final selectedLng = Rxn<double>();

  final isSearching = false.obs;
  final searchError = Rxn<String>();

  final driverIcon = Rxn<BitmapDescriptor>();
  final customerIcon = Rxn<BitmapDescriptor>();
  final shopIcon = Rxn<BitmapDescriptor>();
  final routePoints = <LatLng>[].obs;
  final isLoadingRoute = false.obs;

  /// تأجيل بناء الخريطة حتى بعد رسم الإطار الأول لتجنّب تجميد الواجهة عند الدخول.
  final mapReady = false.obs;

  /// عناوين وعبارات تظهر دائماً تحت كل ماركر (بدون نقر). كل عنصر: {x, y, title, snippet}.
  final labelOverlays = <Map<String, dynamic>>[].obs;

  GoogleMapController? _mapController;
  List<Map<String, dynamic>> _labelsData = [];

  void setMapController(GoogleMapController c) {
    _mapController = c;
    _updateLabelPositions();
  }

  void setLabelsData(List<Map<String, dynamic>> labels) {
    _labelsData = labels;
    _updateLabelPositions();
  }

  void onCameraMoved() {
    _updateLabelPositions();
  }

  Future<void> _updateLabelPositions() async {
    if (_mapController == null || _labelsData.isEmpty) return;
    final list = <Map<String, dynamic>>[];
    const markerLabelOffset = 28.0;
    for (final l in _labelsData) {
      final latLng = l['latLng'] as LatLng?;
      if (latLng == null) continue;
      try {
        final pos = await _mapController!.getScreenCoordinate(latLng);
        list.add({
          'x': pos.x.toDouble(),
          'y': pos.y.toDouble() + markerLabelOffset,
          'title': l['title'] as String? ?? '',
          'snippet': l['snippet'] as String? ?? '',
        });
      } catch (_) {
        // تجاهل إن لم يكن الموقع ضمن الإطار
      }
    }
    labelOverlays.assignAll(list);
  }

  /// بناء قائمة العناوين والعبارات من حالة الـ Controller (للعرض الدائم تحت الماركرات).
  List<Map<String, dynamic>> buildLabelsData() {
    final list = <Map<String, dynamic>>[];
    final dLat = driverLat.value;
    final dLng = driverLng.value;
    if (dLat != null && dLng != null) {
      final name = driverName.value;
      list.add({
        'latLng': LatLng(dLat, dLng),
        'title': name?.isNotEmpty == true ? name! : 'السائق',
        'snippet': 'اضغط للمزيد من التفاصيل',
      });
    }
    final sLat = selectedLat.value;
    final sLng = selectedLng.value;
    if (sLat != null && sLng != null && mode.value == FullScreenMapMode.view) {
      list.add({
        'latLng': LatLng(sLat, sLng),
        'title': 'موقع التوصيل',
        'snippet': 'موقع العميل',
      });
    }
    for (var i = 0; i < shopLocations.length; i++) {
      final shop = shopLocations[i];
      final lat = shop['lat'] is num ? (shop['lat'] as num).toDouble() : null;
      final lng = shop['lng'] is num ? (shop['lng'] as num).toDouble() : null;
      if (lat != null && lng != null) {
        final name = shop['name'] as String?;
        list.add({
          'latLng': LatLng(lat, lng),
          'title': name?.isNotEmpty == true ? name! : 'المحل',
          'snippet': 'موقع المحل الذي طلبت منه',
        });
      }
    }
    return list;
  }

  static const double defaultLat = 33.3152;
  static const double defaultLng = 44.3661;

  static const String _orderSenderIconPath = 'assets/icons/user-hand-up-svgrepo-com.svg';

  final DirectionsService _directionsService = DirectionsService();
  late final DriverTrackingSocketService _trackingService;
  String? _orderId;
  StreamSubscription<DriverLocationUpdate>? _driverLocationSub;
  StreamSubscription<String>? _trackingEndedSub;

  @override
  void onInit() {
    super.onInit();
    _trackingService = Get.find<DriverTrackingSocketService>();
    MapDebugLogger.screenEnter('FullScreenMap');
    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      final lat = args['lat'];
      final lng = args['lng'];
      if (lat is num) initialLat.value = lat.toDouble();
      if (lng is num) initialLng.value = lng.toDouble();
      final dLat = args['driverLat'];
      final dLng = args['driverLng'];
      if (dLat is num) driverLat.value = dLat.toDouble();
      if (dLng is num) driverLng.value = dLng.toDouble();
      final name = args['driverName'];
      final phone = args['driverPhone'];
      final photo = args['driverPhoto'];
      if (name is String) driverName.value = name;
      if (phone is String) driverPhone.value = phone;
      if (photo is String) driverPhoto.value = photo;
      final m = args['mode'];
      if (m == 'pick') mode.value = FullScreenMapMode.pick;
      _orderId = args['orderId'] as String?;
      final shops = args['shopLocations'];
      if (shops is List) {
        for (final e in shops) {
          if (e is Map<String, dynamic>) {
            final lat = e['lat'];
            final lng = e['lng'];
            if (lat is num && lng is num) {
              shopLocations.add({
                'lat': lat.toDouble(),
                'lng': lng.toDouble(),
                'name': e['name'],
              });
            }
          }
        }
      }
    }
    selectedLat.value = initialLat.value ?? defaultLat;
    selectedLng.value = initialLng.value ?? defaultLng;
    _loadMapIcons();
  }

  @override
  void onReady() {
    super.onReady();
    _loadRouteWhenReady();
    // الاشتراك في التتبع عند وجود orderId ووضع العرض فقط — حتى لو لم يكن موقع السائق معروفاً بعد،
    // لنستقبل أول تحديث ونعرض المؤشر ثم نتابع التحديثات عند تحرك السائق.
    if (_orderId != null && _orderId!.isNotEmpty && mode.value == FullScreenMapMode.view) {
      _trackingService.subscribeToOrderTracking(_orderId!);
      _driverLocationSub = _trackingService.driverLocationUpdates.listen(_onDriverLocationUpdate);
      _trackingEndedSub = _trackingService.trackingEnded.listen(_onTrackingEnded);
    }
    // بناء الخريطة بعد رسم الشاشة لتجنّب تجميد الواجهة عند الدخول.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.microtask(() => mapReady.value = true);
    });
  }

  @override
  void onClose() {
    if (_orderId != null) {
      _trackingService.unsubscribeFromOrderTracking(_orderId!);
    }
    _driverLocationSub?.cancel();
    _trackingEndedSub?.cancel();
    super.onClose();
  }

  void _onDriverLocationUpdate(DriverLocationUpdate update) {
    if (update.orderId != _orderId) return;
    driverLat.value = update.lat;
    driverLng.value = update.lng;
    _loadRouteWhenReady();
  }

  void _onTrackingEnded(String orderId) {
    if (orderId != _orderId) return;
    _trackingService.unsubscribeFromOrderTracking(orderId);
    _driverLocationSub?.cancel();
    _trackingEndedSub?.cancel();
    _driverLocationSub = null;
    _trackingEndedSub = null;
  }

  Future<void> _loadMapIcons() async {
    MapDebugLogger.iconsLoadStart();
    final driver = await MapMarkerHelper.getBitmapDescriptorFromIcon(
      Icons.two_wheeler,
      color: AppColors.primaryDark,
      size: 48.w,
      backgroundColor: Colors.white,
      padding: 10.r,
    );
    final customer = await MapMarkerHelper.getBitmapDescriptorFromSvg(
      _orderSenderIconPath,
      width: 48.w,
      height: 48.h,
      addPinPoint: true,
    );
    final shop = await MapMarkerHelper.getBitmapDescriptorFromIcon(
      Icons.store_rounded,
      color: const Color(0xFF00897B),
      size: 44.w,
      backgroundColor: Colors.white,
      padding: 8.r,
    );
    driverIcon.value = driver;
    customerIcon.value = customer;
    shopIcon.value = shop;
    MapDebugLogger.iconsLoadEnd();
  }

  Future<void> _loadRouteWhenReady() async {
    final dLat = driverLat.value;
    final dLng = driverLng.value;
    final sLat = selectedLat.value;
    final sLng = selectedLng.value;
    if (dLat == null || dLng == null || sLat == null || sLng == null) return;
    if (mode.value == FullScreenMapMode.pick) return;
    isLoadingRoute.value = true;
    try {
      final points = await _directionsService.getRouteBetweenPoints(
        origin: LatLng(dLat, dLng),
        destination: LatLng(sLat, sLng),
      );
      routePoints.assignAll(points ?? []);
    } catch (_) {
      routePoints.clear();
    } finally {
      isLoadingRoute.value = false;
    }
  }

  /// هل يوجد موقع سائق للعرض (وضع view)؟
  bool get hasDriverLocation =>
      driverLat.value != null && driverLng.value != null;

  double get centerLat => selectedLat.value ?? initialLat.value ?? defaultLat;
  double get centerLng => selectedLng.value ?? initialLng.value ?? defaultLng;

  bool get isPickMode => mode.value == FullScreenMapMode.pick;

  void setPosition(double lat, double lng) {
    selectedLat.value = lat;
    selectedLng.value = lng;
    searchError.value = null;
  }

  /// البحث عن موقع بعنوان أو اسم مكان وتحديث الخريطة.
  Future<void> searchLocation(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    isSearching.value = true;
    searchError.value = null;
    try {
      final locations = await locationFromAddress(q);
      if (locations.isEmpty) {
        searchError.value = 'لم يُعثر على موقع لهذا البحث';
        Get.snackbar('بحث', searchError.value!, snackPosition: SnackPosition.BOTTOM);
        return;
      }
      final first = locations.first;
      setPosition(first.latitude, first.longitude);
      Get.snackbar('تم', 'تم العثور على الموقع', snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 2));
    } catch (e) {
      searchError.value = 'تعذّر البحث عن الموقع. جرّب عبارة أخرى.';
      Get.snackbar('بحث', searchError.value!, snackPosition: SnackPosition.BOTTOM);
    } finally {
      isSearching.value = false;
    }
  }

  void confirm() {
    if (selectedLat.value == null || selectedLng.value == null) return;
    Get.back(result: LatLng(selectedLat.value!, selectedLng.value!));
  }
}
