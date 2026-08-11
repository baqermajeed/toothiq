import 'package:get/get.dart';

import '../controller/search_page_controller.dart';

class SearchPageBinding extends Bindings {
  @override
  void dependencies() {
    if (Get.isRegistered<SearchPageController>()) {
      Get.delete<SearchPageController>(force: true);
    }
    Get.put(SearchPageController());
  }
}
