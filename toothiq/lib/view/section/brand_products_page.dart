import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../bindings/brand_products_binding.dart';
import '../../controller/brand_products_controller.dart';
import '../../controller/home_controller.dart';
import '../../model/brand_model.dart';
import '../../model/product_model.dart';
import '../../utils/app_colors.dart';
import '../../widget/common/async_state_widgets.dart';
import '../../widget/section/section_app_bar.dart';
import '../../widget/section/section_products_grid.dart';

class BrandProductsPage extends GetView<BrandProductsController> {
  const BrandProductsPage({super.key});

  static void open({
    required BrandModel brand,
    required List<ProductModel> initialProducts,
    String? categoryId,
  }) {
    Get.to(
      () => const BrandProductsPage(),
      binding: BrandProductsBinding(
        brand: brand,
        initialProducts: initialProducts,
        categoryId: categoryId,
      ),
    );
  }

  static void openFromHome(BrandModel brand) {
    final home = Get.find<HomeController>();
    open(brand: brand, initialProducts: List<ProductModel>.from(home.products));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: SectionAppBar(title: controller.brand.name),
        body: Obx(() {
          if (controller.isLoading.value && controller.products.isEmpty) {
            return const AppLoadingState();
          }

          if (controller.loadError.value != null &&
              controller.products.isEmpty) {
            return AppErrorState(
              message: controller.loadError.value!,
              onRetry: () => controller.loadProducts(),
            );
          }

          if (controller.products.isEmpty) {
            return const AppEmptyState(title: 'لا توجد منتجات لهذا البراند');
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: controller.refresh,
            child: Column(
              children: [
                if (controller.loadError.value != null)
                  AppErrorState(
                    message: controller.loadError.value!,
                    onRetry: () => controller.loadProducts(),
                    compact: true,
                  ),
                Expanded(
                  child: SectionProductsGrid(
                    products: controller.products,
                    scrollController: controller.scrollController,
                    emptyTitle: 'لا توجد منتجات لهذا البراند',
                  ),
                ),
                AppLoadMoreFooter(
                  isLoading: controller.loadingMore.value,
                  hasNextPage: controller.hasNextPage.value,
                  onTap: controller.loadMore,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
