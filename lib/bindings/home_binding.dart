import 'package:get/get.dart';

import '../controller/cart_controller.dart';
import '../controller/categories_controller.dart';
import '../controller/home_controller.dart';
import '../controller/main_controller.dart';
import '../controller/notifications_controller.dart';
import '../controller/orders_controller.dart';
import '../controller/settings_controller.dart';
import '../controller/stores_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<MainController>()) {
      Get.put(MainController(), permanent: true);
    }
    Get.lazyPut<HomeController>(() => HomeController());
    if (!Get.isRegistered<CartController>()) {
      Get.put(CartController(), permanent: true);
    }
    Get.lazyPut<NotificationsController>(() => NotificationsController());
    Get.lazyPut<StoresController>(() => StoresController());
    Get.lazyPut<CategoriesController>(() => CategoriesController());
    Get.lazyPut<OrdersController>(() => OrdersController());
    if (!Get.isRegistered<SettingsController>()) {
      Get.put(SettingsController(), permanent: true);
    }
  }
}
