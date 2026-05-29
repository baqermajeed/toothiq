import 'package:get/get.dart';

import '../controller/order_detail_controller.dart';
import '../model/order_model.dart';

class OrderDetailBinding extends Bindings {
  final OrderModel order;

  OrderDetailBinding({required this.order});

  @override
  void dependencies() {
    Get.lazyPut<OrderDetailController>(
      () => OrderDetailController(order: order),
    );
  }
}
