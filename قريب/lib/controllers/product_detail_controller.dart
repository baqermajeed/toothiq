import 'package:get/get.dart';

import '../models/product.dart';

/// تحكم شاشة تفاصيل المنتج — الكمية والمنتج من Get.arguments.
class ProductDetailController extends GetxController {
  final RxInt quantity = 1.obs;
  late final Product product;

  static Product _productFromArguments(dynamic arguments) {
    if (arguments == null) {
      return const Product(name: 'منتج', price: 0);
    }
    if (arguments is Product) return arguments;
    if (arguments is Map<String, dynamic>) {
      return Product.fromMap(arguments);
    }
    final map = Map<String, dynamic>.from(arguments as Map);
    return Product.fromMap(map);
  }

  @override
  void onInit() {
    super.onInit();
    product = _productFromArguments(Get.arguments);
  }

  void incrementQuantity() => quantity.value = quantity.value + 1;

  void decrementQuantity() {
    if (quantity.value > 1) quantity.value = quantity.value - 1;
  }
}
