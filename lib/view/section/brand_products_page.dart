import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/home_controller.dart';
import '../../model/brand_model.dart';
import '../../model/product_model.dart';
import '../../utils/app_colors.dart';
import '../../widget/section/section_app_bar.dart';
import '../../widget/section/section_products_grid.dart';

class BrandProductsPage extends StatelessWidget {
  final BrandModel brand;
  final List<ProductModel> products;

  const BrandProductsPage({
    super.key,
    required this.brand,
    required this.products,
  });

  static void open(BrandModel brand) {
    final home = Get.find<HomeController>();
    final products = List<ProductModel>.from(home.products);
    Get.to(
      () => BrandProductsPage(brand: brand, products: products),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: SectionAppBar(title: brand.name),
        body: SectionProductsGrid(products: products),
      ),
    );
  }
}
