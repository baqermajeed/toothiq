import 'package:get/get.dart';

import '../../controller/categories_controller.dart';
import '../../controller/home_controller.dart';
import '../../controller/orders_controller.dart';
import '../../controller/settings_controller.dart';
import '../../controller/stores_controller.dart';

/// تنسيق إعادة تحميل البيانات المعتمدة على المستخدم (مثل قريب).
class AppDataRefreshService {
  AppDataRefreshService._();

  /// إعادة تحميل القوائم الرئيسية بعد تغيير الموقع/الملف أو تسجيل الدخول.
  static Future<void> refreshUserDependentData() async {
    if (Get.isRegistered<StoresController>()) {
      await Get.find<StoresController>().refresh();
    }
    if (Get.isRegistered<HomeController>()) {
      await Get.find<HomeController>().refresh();
    }
    if (Get.isRegistered<CategoriesController>()) {
      await Get.find<CategoriesController>().refresh();
    }
  }

  /// بعد تسجيل الدخول أو استعادة الجلسة.
  static void refreshAfterAuth() {
    refreshUserDependentData();
    if (Get.isRegistered<OrdersController>()) {
      Get.find<OrdersController>().loadOrders();
    }
    if (Get.isRegistered<SettingsController>()) {
      Get.find<SettingsController>().syncProfileFromApi();
    }
  }

  /// بعد تحديث الملف الشخصي من الإعدادات.
  static Future<void> refreshAfterProfileUpdate() async {
    await refreshUserDependentData();
    if (Get.isRegistered<SettingsController>()) {
      await Get.find<SettingsController>().syncProfileFromApi();
    }
  }
}
