import 'package:get/get.dart';

import '../controller/brand_products_controller.dart';
import '../model/brand_model.dart';
import '../model/product_model.dart';

class BrandProductsBinding extends Bindings {
  final BrandModel brand;
  final List<ProductModel> initialProducts;
  final String? categoryId;

  BrandProductsBinding({
    required this.brand,
    required this.initialProducts,
    this.categoryId,
  });

  @override
  void dependencies() {
    Get.lazyPut<BrandProductsController>(
      () => BrandProductsController(
        brand: brand,
        initialProducts: initialProducts,
        categoryId: categoryId,
      ),
    );
  }
}
