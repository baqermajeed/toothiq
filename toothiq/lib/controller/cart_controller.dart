import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../core/api/api_exception.dart';
import '../model/cart_item_model.dart';
import '../model/product_model.dart';
import '../service_layer/services/order_service.dart';
import 'session_controller.dart';

class CartController extends GetxController {
  final items = <CartItemModel>[].obs;

  bool get isEmpty => items.isEmpty;

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  int get orderSubtotal => items.fold(0, (sum, item) => sum + item.lineTotal);

  String formatPrice(int amount) {
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$formatted د.ع';
  }

  String get formattedOrderPrice => formatPrice(orderSubtotal);
  String get formattedTotalPrice => formattedOrderPrice;

  void addProduct(ProductModel product, {int quantity = 1}) {
    final index = items.indexWhere((e) => e.product.id == product.id);
    if (index >= 0) {
      items[index].quantity += quantity;
    } else {
      items.add(CartItemModel(product: product, quantity: quantity));
    }
    items.refresh();
  }

  void incrementQuantity(String productId) {
    final index = items.indexWhere((e) => e.product.id == productId);
    if (index == -1) return;
    items[index].quantity++;
    items.refresh();
  }

  void decrementQuantity(String productId) {
    final index = items.indexWhere((e) => e.product.id == productId);
    if (index == -1) return;
    if (items[index].quantity > 1) {
      items[index].quantity--;
      items.refresh();
    }
  }

  void removeItem(String productId) {
    items.removeWhere((e) => e.product.id == productId);
    items.refresh();
  }

  void clearCart() {
    if (items.isEmpty) return;
    items.clear();
    items.refresh();
  }

  void completePurchase() {
    if (isEmpty) return;
    // يُستدعى من BasketPage عبر CheckoutController.startCheckout()
  }

  bool get hasDeliveryCoordinates {
    final user = Get.find<SessionController>().user.value;
    return user != null && user.hasLocation;
  }

  /// نفس نهج قريب: فحص الجلسة والموقع ثم إرسال الطلب.
  Future<String> completeOrderFromCart({
    required String deliveryAddress,
    String? notes,
    double? lng,
    double? lat,
  }) async {
    if (!Get.find<SessionController>().isAuthenticated) {
      throw const ApiException('يرجى تسجيل الدخول لإتمام الطلب');
    }
    if (items.isEmpty) {
      throw const ApiException('السلة فارغة');
    }

    final address = deliveryAddress.trim();
    if (address.isEmpty) {
      throw const ApiException('يرجى تحديد عنوان التوصيل');
    }

    if (lng == null || lat == null) {
      final user = Get.find<SessionController>().user.value;
      if (user != null && user.hasLocation) {
        lng = user.locationLng;
        lat = user.locationLat;
      }
    }
    if (lng == null || lat == null) {
      throw const ApiException('يرجى تحديد موقع التوصيل على الخريطة');
    }

    try {
      final orderId = await Get.find<OrderService>().createOrderFromCart(
        items: items.toList(growable: false),
        deliveryAddress: address,
        deliveryCoordinates: [lng, lat],
        notes: notes,
      );
      if (orderId == null || orderId.isEmpty) {
        throw const ApiException('تعذر إنشاء الطلب');
      }
      items.clear();
      return orderId;
    } on ApiException {
      rethrow;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('[CompleteOrder] خطأ: $error');
        debugPrint('[CompleteOrder] stackTrace: $stackTrace');
      }
      throw const ApiException('حدث خطأ، حاول مرة أخرى');
    }
  }
}
