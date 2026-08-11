import 'package:get/get.dart';

import '../controller/cart_controller.dart';
import '../controller/categories_controller.dart';
import '../controller/home_controller.dart';
import '../controller/main_controller.dart';
import '../controller/orders_controller.dart';
import '../controller/settings_controller.dart';
import '../controller/stores_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<MainController>()) {
      Get.put(MainController(), permanent: true);
    }
    if (!Get.isRegistered<HomeController>()) {
      Get.put(HomeController(), permanent: true);
    }
    if (!Get.isRegistered<CartController>()) {
      Get.put(CartController(), permanent: true);
    }
    if (!Get.isRegistered<StoresController>()) {
      Get.put(StoresController(), permanent: true);
    }
    if (!Get.isRegistered<CategoriesController>()) {
      Get.put(CategoriesController(), permanent: true);
    }
    if (!Get.isRegistered<OrdersController>()) {
      Get.put(OrdersController(), permanent: true);
    }
    if (!Get.isRegistered<SettingsController>()) {
      Get.put(SettingsController(), permanent: true);
    }
  }
}
