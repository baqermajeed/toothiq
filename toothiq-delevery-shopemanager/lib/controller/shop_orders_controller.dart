import 'package:get/get.dart';

import '../bindings/app_binding.dart';
import '../controller/session_controller.dart';
import '../model/partner_order.dart';
import '../service_layer/services/order_service.dart';

class ShopOrdersController extends GetxController {
  ShopOrdersController({
    required OrderService orderService,
    required SessionController session,
  }) : _orderService = orderService,
       _session = session;

  final OrderService _orderService;
  final SessionController _session;

  final orders = <PartnerOrder>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadOrders();
  }

  Future<void> loadOrders() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final list = await _orderService.fetchOrders();
      final shopId = _session.shopId.value;
      if (shopId.isNotEmpty) {
        orders.assignAll(
          list.where((o) => o.shopId == null || o.shopId == shopId),
        );
      } else {
        orders.assignAll(list);
      }
    } catch (error) {
      errorMessage.value = apiErrorMessage(error);
    } finally {
      isLoading.value = false;
    }
  }

  int get pendingCount =>
      orders.where((o) => o.status == PartnerOrderStatus.pending).length;

  int get preparingCount => orders
      .where(
        (o) =>
            o.status == PartnerOrderStatus.accepted ||
            o.status == PartnerOrderStatus.preparing,
      )
      .length;

  Future<void> acceptOrder(String id) async {
    try {
      final updated = await _orderService.updateStatus(
        orderId: id,
        status: PartnerOrderStatus.accepted.apiValue,
      );
      _replaceOrder(updated.copyWith(status: PartnerOrderStatus.preparing));
    } catch (error) {
      Get.snackbar('خطأ', apiErrorMessage(error));
    }
  }

  Future<void> rejectOrder(String id) async {
    try {
      final updated = await _orderService.updateStatus(
        orderId: id,
        status: PartnerOrderStatus.canceled.apiValue,
      );
      _replaceOrder(updated);
    } catch (error) {
      Get.snackbar('خطأ', apiErrorMessage(error));
    }
  }

  Future<void> markReadyForDelivery(String id) async {
    try {
      final updated = await _orderService.updateStatus(
        orderId: id,
        status: PartnerOrderStatus.onTheWay.apiValue,
      );
      _replaceOrder(updated);
    } catch (error) {
      Get.snackbar('خطأ', apiErrorMessage(error));
    }
  }

  void _replaceOrder(PartnerOrder order) {
    final index = orders.indexWhere((o) => o.id == order.id);
    if (index >= 0) {
      orders[index] = order;
      orders.refresh();
    } else {
      orders.insert(0, order);
    }
  }
}
