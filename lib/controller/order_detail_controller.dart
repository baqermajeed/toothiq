import 'package:get/get.dart';

import '../model/order_detail_model.dart';
import '../model/order_model.dart';

class OrderDetailController extends GetxController {
  final OrderDetailModel detail;

  OrderDetailController({required OrderModel order})
      : detail = OrderDetailModel.fromOrder(order);

  void onReorder() {
    // TODO: إعادة الطلب عبر API
  }

  void onViewStore() {
    // TODO: التنقل لصفحة المتجر
  }
}
