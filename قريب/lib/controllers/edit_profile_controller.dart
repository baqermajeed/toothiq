import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import 'auth_controller.dart';
import 'home_products_controller.dart';
import 'home_shops_controller.dart';
import 'categories_controller.dart';
import '../core/errors/api_exception.dart';
import '../models/user.dart';
import '../widgets/common/app_toast.dart';
import '../widgets/dialogs/location_permission_denied_dialog.dart';

/// تحكم شاشة تعديل المعلومات الشخصية — الاسم، البريد، عنوان التوصيل (الموقع).
class EditProfileController extends GetxController {
  final nameController = TextEditingController();

  /// إحداثيات عنوان التوصيل المُختار (للعرض على الخريطة والحفظ).
  final selectedLat = Rxn<double>();
  final selectedLng = Rxn<double>();

  final isGettingLocation = false.obs;
  final isSaving = false.obs;

  /// تأجيل بناء الخريطة حتى بعد رسم الإطار الأول لتجنّب تجميد الواجهة.
  final mapReady = false.obs;

  @override
  void onInit() {
    super.onInit();
    final user = Get.find<AuthController>().user.value;
    if (user != null) {
      nameController.text = user.name;
      _loadUserLocation(user);
    }
  }

  void _loadUserLocation(User user) {
    final loc = user.location;
    if (loc is Map<String, dynamic> && loc['coordinates'] is List) {
      final coords = loc['coordinates'] as List;
      if (coords.length >= 2) {
        final lng = (coords[0] is num) ? (coords[0] as num).toDouble() : null;
        final lat = (coords[1] is num) ? (coords[1] as num).toDouble() : null;
        if (lat != null && lng != null) {
          selectedLat.value = lat;
          selectedLng.value = lng;
        }
      }
    }
  }

  @override
  void onReady() {
    super.onReady();
    // بناء الخريطة بعد رسم الشاشة لتجنّب تجميد الواجهة عند الدخول.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.microtask(() => mapReady.value = true);
    });
  }

  @override
  void onClose() {
    nameController.dispose();
    super.onClose();
  }

  /// تعيين الموقع من نقرة على الخريطة مع حفظ تلقائي وتحديث بيانات التطبيق.
  Future<void> setLocationFromMap(double lat, double lng) async {
    selectedLat.value = lat;
    selectedLng.value = lng;
    await _saveLocationAndRefresh();
  }

  /// الحصول على الموقع الحالي عبر GPS وحفظه كعنوان توصيل.
  Future<void> getCurrentLocation() async {
    isGettingLocation.value = true;
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppToast.show('الموقع', 'تفعيل خدمة الموقع في إعدادات الجهاز', type: ToastType.warning);
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        LocationPermissionDeniedDialog.show();
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      selectedLat.value = position.latitude;
      selectedLng.value = position.longitude;
      await _saveLocationAndRefresh();
    } catch (e) {
      Get.snackbar('خطأ', 'تعذّر الحصول على الموقع. تأكد من تفعيل الموقع وحاول مرة أخرى.');
    } finally {
      isGettingLocation.value = false;
    }
  }

  /// حفظ الموقع فوراً عبر الـ API وتحديث قوائم المحلات والمنتجات دون الحاجة للنقر على «حفظ».
  Future<void> _saveLocationAndRefresh() async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      Get.snackbar('تنبيه', 'أدخل الاسم أولاً');
      return;
    }
    if (selectedLat.value == null || selectedLng.value == null) return;
    final auth = Get.find<AuthController>();
    if (auth.user.value == null || !auth.isAuthenticated) return;
    isSaving.value = true;
    try {
      final location = [selectedLng.value!, selectedLat.value!];
      final updated = await auth.apiClient.updateMe(
        name: name,
        location: location,
      );
      auth.user.value = updated;
      await _refreshLocationDependentData();
    } on ApiException catch (e) {
      Get.snackbar('فشل الحفظ', e.message, snackPosition: SnackPosition.BOTTOM);
    } catch (_) {
      Get.snackbar('فشل الحفظ', 'حدث خطأ، حاول مرة أخرى', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isSaving.value = false;
    }
  }

  /// إعادة تحميل المحلات والمنتجات حسب الموقع الجديد.
  Future<void> _refreshLocationDependentData() async {
    if (Get.isRegistered<HomeShopsController>()) {
      await Get.find<HomeShopsController>().loadShops();
    }
    if (Get.isRegistered<HomeProductsController>()) {
      await Get.find<HomeProductsController>().loadProducts();
    }
    if (Get.isRegistered<CategoriesController>()) {
      await Get.find<CategoriesController>().loadShopsBySelectedCategory();
    }
  }

  /// حفظ التعديلات (الاسم، البريد، العنوان) عبر الـ API.
  Future<void> save() async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      Get.snackbar('تنبيه', 'أدخل الاسم');
      return;
    }
    final auth = Get.find<AuthController>();
    final current = auth.user.value;
    if (current == null || !auth.isAuthenticated) {
      Get.back();
      return;
    }
    isSaving.value = true;
    try {
      List<double>? location;
      if (selectedLat.value != null && selectedLng.value != null) {
        location = [selectedLng.value!, selectedLat.value!];
      }
      final updated = await auth.apiClient.updateMe(
        name: name,
        location: location,
      );
      auth.user.value = updated;
      await _refreshLocationDependentData();
      Get.back();
    } on ApiException catch (e) {
      Get.snackbar('فشل الحفظ', e.message);
    } catch (_) {
      Get.snackbar('فشل الحفظ', 'حدث خطأ، حاول مرة أخرى');
    } finally {
      isSaving.value = false;
    }
  }

  /// هل تم تعيين موقع للتوصيل؟
  bool get hasLocation => selectedLat.value != null && selectedLng.value != null;
}
