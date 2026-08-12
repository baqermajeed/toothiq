import 'package:get/get.dart';

import 'orders_controller.dart';

class MainController extends GetxController {
  final currentIndex = 2.obs;

  void changeTab(int index) {
    currentIndex.value = index;
    if (index == OrdersController.ordersTabIndex &&
        Get.isRegistered<OrdersController>()) {
      Get.find<OrdersController>().refreshSilently();
    }
  }
}
