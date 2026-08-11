import '../../bindings/cart_binding.dart';
import '../basket/basket_page.dart';

/// نقطة دخول السلة — تفتح واجهة [BasketPage]
class CartPage {
  CartPage._();

  static void open() {
    CartBinding().dependencies();
    BasketPage.open();
  }
}
