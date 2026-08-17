import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/driver_orders_controller.dart';
import '../../controller/session_controller.dart';
import '../../controller/shop_orders_controller.dart';
import '../../model/user_role.dart';
import '../../service_layer/services/order_service.dart';
import '../../view/driver/driver_orders_page.dart';
import '../../view/shop/shop_order_detail_page.dart';

class PartnerNotificationRouter {
  static Map<String, String?>? _pending;

  static void handle(Map<String, String?> data) {
    if (!Get.isRegistered<SessionController>()) {
      _pending = data;
      return;
    }
    final session = Get.find<SessionController>();
    if (!session.isAuthenticated.value || session.role.value == null) {
      _pending = data;
      return;
    }
    _open(data, session.role.value);
  }

  static void consumePending() {
    final data = _pending;
    if (data == null) return;
    _pending = null;
    handle(data);
  }

  static void _open(Map<String, String?> data, AppUserRole? role) {
    final orderId = data['orderId']?.trim();
    if (orderId == null || orderId.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (role == AppUserRole.driver) {
        _openDriverOrder(orderId);
      } else {
        _openShopOrder(orderId);
      }
    });
  }

  static Future<void> _openShopOrder(String orderId) async {
    try {
      if (Get.isRegistered<ShopOrdersController>()) {
        await Get.find<ShopOrdersController>().loadOrders(silent: true);
      }
      final order = await Get.find<OrderService>().fetchOrder(orderId);
      Get.to(() => ShopOrderDetailPage(order: order));
    } catch (_) {}
  }

  static Future<void> _openDriverOrder(String orderId) async {
    try {
      if (Get.isRegistered<DriverOrdersController>()) {
        await Get.find<DriverOrdersController>().loadOrders(silent: true);
      }
      final order = await Get.find<OrderService>().fetchDriverOrder(orderId);
      showDriverOrderDetailSheet(order);
    } catch (_) {}
  }
}
