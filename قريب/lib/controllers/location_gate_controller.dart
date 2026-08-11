import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import '../utils/location_helper.dart';
import '../widgets/dialogs/location_permission_denied_dialog.dart';
import 'app_location_controller.dart';

/// Controller لشاشة بوابة الموقع — تظهر للضيف عند فتح التطبيق.
/// يطلب الموقع ويحفظه في AppLocationController ثم ينتقل إلى MainShell.
class LocationGateController extends GetxController {
  final isLoading = false.obs;
  final Rxn<String> errorMessage = Rxn<String>();

  AppLocationController get appLocation => Get.find<AppLocationController>();

  Future<void> useCurrentLocation() async {
    errorMessage.value = null;
    isLoading.value = true;
    try {
      final coords = await requestAndGetLocation();
      if (coords == null || coords.length < 2) {
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          LocationPermissionDeniedDialog.show();
        } else {
          Get.snackbar(
            'الموقع',
            'لم يتم الحصول على الموقع. تأكد من تفعيل خدمة الموقع.',
          );
        }
        return;
      }
      appLocation.setLocation(coords[0], coords[1]);
      _goToMainShell();
    } catch (_) {
      Get.snackbar('فشل', 'حدث خطأ، حاول مرة أخرى');
    } finally {
      if (Get.isRegistered<LocationGateController>()) {
        isLoading.value = false;
      }
    }
  }

  void skip() {
    _goToMainShell();
  }

  void _goToMainShell() {
    Get.offAllNamed('/home');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<LocationGateController>()) {
        Get.delete<LocationGateController>(force: true);
      }
    });
  }
}
