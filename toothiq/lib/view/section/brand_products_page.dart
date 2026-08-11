import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../bindings/brand_products_binding.dart';
import '../../controller/brand_products_controller.dart';
import '../../controller/home_controller.dart';
import '../../model/brand_model.dart';
import '../../model/product_model.dart';
import '../../utils/app_colors.dart';
import '../../widget/common/async_state_widgets.dart';
import '../../widget/search_filter_row.dart';
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
          if (controller.isLoading.value && controller.allProducts.isEmpty) {
            return const AppLoadingState();
          }

          if (controller.loadError.value != null &&
              controller.allProducts.isEmpty) {
            return AppErrorState(
              message: controller.loadError.value!,
              onRetry: () => controller.loadProducts(),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: controller.refresh,
            child: Column(
              children: [
                SizedBox(height: 12.h),
                SearchFilterRow(
                  controller: controller.searchController,
                  hintText: 'أبحث في منتجات ${controller.brand.name} ..',
                  showFilter: false,
                ),
                SizedBox(height: 14.h),
                if (controller.loadError.value != null)
                  AppErrorState(
                    message: controller.loadError.value!,
                    onRetry: () => controller.loadProducts(),
                    compact: true,
                  ),
                Expanded(
                  child: Obx(() {
                    final products = controller.filteredProducts;
                    if (products.isEmpty) {
                      final hasSearch =
                          controller.searchController.text.trim().isNotEmpty;
                      return AppEmptyState(
                        title: hasSearch
                            ? 'لا توجد نتائج مطابقة للبحث'
                            : 'لا توجد منتجات لهذا البراند',
                      );
                    }

                    return Column(
                      children: [
                        Expanded(
                          child: SectionProductsGrid(
                            products: products,
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
                    );
                  }),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
