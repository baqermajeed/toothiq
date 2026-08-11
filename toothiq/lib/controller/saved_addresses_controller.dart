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
  String? _userId;

  @override
  void onInit() {
    super.onInit();
    _ensureBoundToCurrentUser();
  }

  Future<void> _ensureBoundToCurrentUser() async {
    if ((_userId ?? '').trim().isNotEmpty) return;
    if (!Get.isRegistered<SessionController>()) return;
    final sessionUser = Get.find<SessionController>().user.value;
    final sessionUserId = sessionUser?.id.trim() ?? '';
    if (sessionUserId.isEmpty) return;
    await bindToUser(sessionUserId);
  }

  Future<void> bindToUser(String? userId) async {
    _userId = userId?.trim().isEmpty == true ? null : userId?.trim();
    addresses.clear();

    if (_userId == null) return;

    final raw = _prefs.getJsonList(StorageKeys.savedAddressesFor(_userId!));
    if (raw == null || raw.isEmpty) return;

    final loaded = raw
        .map(DeliveryAddressModel.fromJson)
        .where((address) => address.id.isNotEmpty)
        .toList(growable: false);

    if (loaded.isEmpty) return;

    if (!loaded.any((address) => address.isCurrent)) {
      loaded[0] = loaded.first.copyWith(isCurrent: true);
    }

    addresses.assignAll(loaded);
  }

  Future<void> _persistAddresses() async {
    if (_userId == null) return;
    await _prefs.setJsonList(
      StorageKeys.savedAddressesFor(_userId!),
      addresses.map((address) => address.toJson()).toList(growable: false),
    );
  }

  Future<void> setCurrentAddress(String id) async {
    await _ensureBoundToCurrentUser();
    if (_userId == null) return;

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
    await _ensureBoundToCurrentUser();
    if (_userId == null) return;

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
    await _ensureBoundToCurrentUser();
    if (_userId == null) return;

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
    await _ensureBoundToCurrentUser();
    if (_userId == null) return;

    final existing = addresses.firstWhereOrNull((a) => a.id == id);
    if (existing == null) return;
    final wasCurrent = existing.isCurrent;
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
