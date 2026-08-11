import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../controller/session_controller.dart';
import '../utils/location_helper.dart';
import '../widget/common/app_toast.dart';
import '../widget/dialogs/location_permission_denied_dialog.dart';

class MapPickController extends GetxController {
  static const double defaultLat = 33.3152;
  static const double defaultLng = 44.3661;
  static const double _defaultZoom = 15;

  final selectedLat = Rxn<double>();
  final selectedLng = Rxn<double>();
  final isSearching = false.obs;
  final isLocating = false.obs;
  final searchError = RxnString();
  final mapReady = false.obs;
  final markers = <Marker>{}.obs;

  GoogleMapController? _mapController;
  bool _hasInitialCoords = false;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      final lat = args['lat'];
      final lng = args['lng'];
      if (lat is num) {
        selectedLat.value = lat.toDouble();
        _hasInitialCoords = true;
      }
      if (lng is num) {
        selectedLng.value = lng.toDouble();
        _hasInitialCoords = true;
      }
    }

    if (!_hasInitialCoords && Get.isRegistered<SessionController>()) {
      final user = Get.find<SessionController>().user.value;
      if (user != null && user.hasLocation) {
        selectedLat.value = user.locationLat;
        selectedLng.value = user.locationLng;
        _hasInitialCoords = true;
      }
    }

    selectedLat.value ??= defaultLat;
    selectedLng.value ??= defaultLng;
    _syncMarker();
    Future.microtask(() => mapReady.value = true);
  }

  @override
  void onClose() {
    _mapController?.dispose();
    super.onClose();
  }

  double get centerLat => selectedLat.value ?? defaultLat;
  double get centerLng => selectedLng.value ?? defaultLng;

  CameraPosition get initialCamera => CameraPosition(
    target: LatLng(centerLat, centerLng),
    zoom: _defaultZoom,
  );

  void onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> setPosition(
    double lat,
    double lng, {
    bool animate = true,
  }) async {
    selectedLat.value = lat;
    selectedLng.value = lng;
    searchError.value = null;
    _syncMarker();

    if (!animate) return;
    await _animateTo(lat, lng);
  }

  Future<void> useCurrentLocation() async {
    if (isLocating.value) return;
    isLocating.value = true;
    try {
      final coords = await requestAndGetLocation();
      if (coords == null || coords.length < 2) {
        LocationPermissionDeniedDialog.show();
        return;
      }

      final lat = coords[1];
      final lng = coords[0];
      if (!IraqLocationBounds.contains(lat, lng)) {
        AppToast.show(
          'موقع غير متوقع',
          'الموقع المستلم يبدو خارج العراق. إذا كنت على محاكي، حدّد الموقع من الخريطة أو ابحث عن مدينتك.',
          type: ToastType.warning,
        );
        return;
      }

      await setPosition(lat, lng);
      AppToast.show(
        'تم',
        'تم تحديد موقعك الحالي',
        type: ToastType.success,
      );
    } finally {
      isLocating.value = false;
    }
  }

  Future<void> searchLocation(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    isSearching.value = true;
    searchError.value = null;
    try {
      final locations = await locationFromAddress(q);
      if (locations.isEmpty) {
        searchError.value = 'لم يُعثر على موقع لهذا البحث';
        AppToast.show('بحث', searchError.value!, type: ToastType.warning);
        return;
      }
      final first = locations.first;
      await setPosition(first.latitude, first.longitude);
      AppToast.show('تم', 'تم العثور على الموقع', type: ToastType.success);
    } catch (_) {
      searchError.value = 'تعذّر البحث عن الموقع';
      AppToast.show('بحث', searchError.value!, type: ToastType.error);
    } finally {
      isSearching.value = false;
    }
  }

  void confirm() {
    final lat = selectedLat.value;
    final lng = selectedLng.value;
    if (lat == null || lng == null) return;
    Get.back(result: LatLng(lat, lng));
  }

  void _syncMarker() {
    markers.assignAll({
      Marker(
        markerId: const MarkerId('selected'),
        position: LatLng(centerLat, centerLng),
      ),
    });
  }

  Future<void> _animateTo(double lat, double lng) async {
    final map = _mapController;
    if (map == null) return;
    await map.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(lat, lng), _defaultZoom),
    );
  }
}
