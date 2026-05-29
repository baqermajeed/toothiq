import 'package:get/get.dart';

import '../model/product_model.dart';
import 'cart_controller.dart';

class ProductDetailsController extends GetxController {
  final ProductModel product;

  ProductDetailsController({required this.product});

  final quantity = 1.obs;
  final selectedImageIndex = 0.obs;
  late final RxBool isFavorite;

  @override
  void onInit() {
    super.onInit();
    isFavorite = product.isFavorite.obs;
  }

  void selectImage(int index) {
    selectedImageIndex.value = index;
  }

  void incrementQuantity() {
    quantity.value++;
  }

  void decrementQuantity() {
    if (quantity.value > 1) quantity.value--;
  }

  void toggleFavorite() {
    isFavorite.value = !isFavorite.value;
  }

  void addToCart() {
    final cart = Get.isRegistered<CartController>()
        ? Get.find<CartController>()
        : Get.put(CartController(), permanent: true);
    cart.addProduct(product, quantity: quantity.value);
  }

  void buyNow() {
    // TODO: شراء مباشر
  }
}
