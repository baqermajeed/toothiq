import 'package:get/get.dart';

import '../controller/product_details_controller.dart';
import '../model/product_model.dart';

class ProductDetailsBinding extends Bindings {
  final ProductModel product;

  ProductDetailsBinding({required this.product});

  @override
  void dependencies() {
    Get.delete<ProductDetailsController>(force: true);
    Get.put<ProductDetailsController>(
      ProductDetailsController(product: product),
    );
  }
}
