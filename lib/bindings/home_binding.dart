import 'package:get/get.dart';

import '../controller/categories_controller.dart';
import '../controller/home_controller.dart';
import '../controller/main_controller.dart';
import '../controller/stores_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<MainController>()) {
      Get.put(MainController(), permanent: true);
    }
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<StoresController>(() => StoresController());
    Get.lazyPut<CategoriesController>(() => CategoriesController());
  }
}
