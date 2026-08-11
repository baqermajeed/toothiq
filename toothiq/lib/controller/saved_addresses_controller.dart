import 'package:get/get.dart';

import '../core/api/api_exception.dart';
import '../model/delivery_address_model.dart';
import '../service_layer/services/preferences_storage.dart';
import '../service_layer/services/user_service.dart';
import '../utils/storage_keys.dart';
import 'session_controller.dart';

class SavedAddressesController extends GetxController {
  final _prefs = PreferencesStorage.instance;

  final addresses = <DeliveryAddressModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadAddresses();
  }

  void _loadAddresses() {
    final raw = _prefs.getJsonList(StorageKeys.savedAddresses);
    if (raw == null || raw.isEmpty) {
      addresses.clear();
      return;
    }

    final loaded = raw
        .map(DeliveryAddressModel.fromJson)
        .toList(growable: false);

    if (!loaded.any((address) => address.isCurrent) && loaded.isNotEmpty) {
      loaded[0] = loaded.first.copyWith(isCurrent: true);
    }

    addresses.assignAll(loaded);
  }

  Future<void> _persistAddresses() async {
    await _prefs.setJsonList(
      StorageKeys.savedAddresses,
      addresses.map((address) => address.toJson()).toList(growable: false),
    );
  }

  Future<void> setCurrentAddress(String id) async {
    addresses.assignAll(
      addresses
          .map((address) => address.copyWith(isCurrent: address.id == id))
          .toList(),
    );
    await _persistAddresses();
    final current = addresses.firstWhereOrNull((a) => a.id == id);
    if (current != null) {
      await _syncCurrentLocationToApi(current.lat, current.lng);
    }
  }

  Future<void> addAddress({
    required String governorate,
    required String area,
    required String landmark,
    double? lat,
    double? lng,
    bool setAsCurrent = false,
  }) async {
    final id = 'address_${DateTime.now().millisecondsSinceEpoch}';
    final shouldBeCurrent = setAsCurrent || addresses.isEmpty;

    if (shouldBeCurrent) {
      addresses.assignAll(
        addresses.map((address) => address.copyWith(isCurrent: false)).toList(),
      );
    }

    addresses.add(
      DeliveryAddressModel(
        id: id,
        governorate: governorate.trim(),
        area: area.trim(),
        landmark: landmark.trim(),
        isCurrent: shouldBeCurrent,
        lat: lat,
        lng: lng,
      ),
    );
    await _persistAddresses();
    if (shouldBeCurrent) {
      await _syncCurrentLocationToApi(lat, lng);
    }
  }

  Future<void> updateAddress({
    required String id,
    required String governorate,
    required String area,
    required String landmark,
    double? lat,
    double? lng,
  }) async {
    final index = addresses.indexWhere((address) => address.id == id);
    if (index == -1) return;

    final wasCurrent = addresses[index].isCurrent;
    addresses[index] = addresses[index].copyWith(
      governorate: governorate.trim(),
      area: area.trim(),
      landmark: landmark.trim(),
      lat: lat,
      lng: lng,
    );
    addresses.refresh();
    await _persistAddresses();
    if (wasCurrent) {
      await _syncCurrentLocationToApi(lat, lng);
    }
  }

  Future<void> deleteAddress(String id) async {
    final wasCurrent = addresses.firstWhere((a) => a.id == id).isCurrent;
    addresses.removeWhere((address) => address.id == id);

    if (addresses.isEmpty) {
      await _persistAddresses();
      return;
    }

    if (wasCurrent) {
      addresses[0] = addresses.first.copyWith(isCurrent: true);
    }

    addresses.refresh();
    await _persistAddresses();
  }

  Future<void> _syncCurrentLocationToApi(double? lat, double? lng) async {
    if (lat == null || lng == null) return;
    if (!Get.isRegistered<SessionController>()) return;
    final session = Get.find<SessionController>();
    if (!session.isAuthenticated) return;
    if (!Get.isRegistered<UserService>()) return;

    try {
      final user = await Get.find<UserService>().updateLocation(lat, lng);
      session.user.value = user;
    } on ApiException {
      // يبقى العنوان محلياً حتى لو فشلت المزامنة
    }
  }
}
