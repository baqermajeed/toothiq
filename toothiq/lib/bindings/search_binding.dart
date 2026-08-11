import 'package:get/get.dart';

import '../controller/search_controller.dart';

class SearchBinding extends Bindings {
  @override
  void dependencies() {
    if (Get.isRegistered<SearchProductsController>()) {
      Get.delete<SearchProductsController>(force: true);
    }
    Get.put(SearchProductsController());
  }
}
