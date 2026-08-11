import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'app_location_controller.dart';
import 'auth_controller.dart';
import '../utils/location_helper.dart';

/// يطلب صلاحية الموقع ويحدّث موقع المستخدم عند كل فتح للتطبيق وعند العودة من الخلفية.
class LocationOnOpenController extends GetxController with WidgetsBindingObserver {
  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      requestLocationAndUpdateUser();
    }
  }

  @override
  void onReady() {
    super.onReady();
    requestLocationAndUpdateUser();
  }

  /// طلب صلاحية الموقع، حفظه في AppLocationController، وتحديث موقع المستخدم في الـ API إن كان مسجّل الدخول.
  Future<void> requestLocationAndUpdateUser() async {
    final coords = await requestAndGetLocation();
    if (coords == null || coords.length < 2) return;
    final lng = coords[0];
    final lat = coords[1];
    if (Get.isRegistered<AppLocationController>()) {
      Get.find<AppLocationController>().setLocation(lng, lat);
    }
    if (Get.isRegistered<AuthController>()) {
      final auth = Get.find<AuthController>();
      if (auth.isAuthenticated) {
        await auth.updateDeliveryLocation(lat, lng, silent: true);
      }
    }
  }
}
