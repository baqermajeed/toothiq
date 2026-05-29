import 'package:get/get.dart';

import '../model/cart_item_model.dart';
import '../model/product_model.dart';

class CartController extends GetxController {
  final items = <CartItemModel>[].obs;

  bool get isEmpty => items.isEmpty;

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  int get orderSubtotal =>
      items.fold(0, (sum, item) => sum + item.lineTotal);

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
    // TODO: إكمال الشراء عبر API
  }
}
