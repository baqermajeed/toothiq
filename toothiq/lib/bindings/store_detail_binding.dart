import 'package:get/get.dart';

import '../controller/home_controller.dart';
import '../controller/store_detail_controller.dart';
import '../model/store_model.dart';

class StoreDetailBinding extends Bindings {
  final StoreModel store;

  StoreDetailBinding({required this.store});

  @override
  void dependencies() {
    if (!Get.isRegistered<HomeController>()) {
      Get.put(HomeController(), permanent: true);
    }
    Get.lazyPut<StoreDetailController>(
      () => StoreDetailController(store: store),
    );
  }
}
