import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../bindings/section_detail_binding.dart';
import '../../controller/section_detail_controller.dart';
import '../../model/category_model.dart';
import '../../utils/app_colors.dart';
import '../../widget/common/async_state_widgets.dart';
import '../../widget/home/category_chip_widget.dart';
import '../../widget/search_filter_row.dart';
import '../../widget/section/brand_card_widget.dart';
import '../../widget/section/section_app_bar.dart';
import '../../widget/section/section_products_grid.dart';
import 'brand_products_page.dart';

class SectionDetailPage extends StatelessWidget {
  final CategoryModel category;

  const SectionDetailPage({super.key, required this.category});

  static void open(CategoryModel category) {
    Get.to(
      () => SectionDetailPage(category: category),
      binding: SectionDetailBinding(category: category),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<SectionDetailController>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: SectionAppBar(title: category.name),
        body: Obx(() {
          if (ctrl.showFullScreenLoading) {
            return const AppLoadingState();
          }

          if (ctrl.loadError.value != null && ctrl.sectionProducts.isEmpty) {
            return AppErrorState(
              message: ctrl.loadError.value!,
              onRetry: () => ctrl.loadSectionData(),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 8.h),
              _SectionFilterTabs(controller: ctrl),
              SizedBox(height: 12.h),
              Expanded(
                child: ctrl.isBrandsTab
                    ? _BrandsTabContent(controller: ctrl)
                    : _ProductsTabContent(controller: ctrl),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _SectionFilterTabs extends StatelessWidget {
  final SectionDetailController controller;

  const _SectionFilterTabs({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44.h,
      child: Obx(() {
        final tabs = controller.tabLabels;
        final selectedIndex = controller.selectedTabIndex.value;
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          itemCount: tabs.length,
          separatorBuilder: (context, index) => SizedBox(width: 10.w),
          itemBuilder: (context, index) {
            return CategoryChipWidget(
              label: tabs[index],
              isSelected: selectedIndex == index,
              onTap: () => controller.selectTab(index),
            );
          },
        );
      }),
    );
  }
}

class _ProductsTabContent extends StatelessWidget {
  final SectionDetailController controller;

  const _ProductsTabContent({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Obx(
          () => SearchFilterRow(
            controller: controller.searchController,
            hintText: controller.searchHintText,
            showFilter: false,
          ),
        ),
        SizedBox(height: 14.h),
        Expanded(
          child: Obx(() {
            final products = controller.filteredProducts;
            if (products.isEmpty) {
              final hasSearch =
                  controller.searchController.text.trim().isNotEmpty;
              return AppEmptyState(
                title: hasSearch
                    ? 'لا توجد نتائج مطابقة للبحث'
                    : 'لا توجد منتجات في هذا القسم',
              );
            }

            return Column(
              children: [
                Expanded(child: SectionProductsGrid(products: products)),
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
    );
  }
}

class _BrandsTabContent extends StatelessWidget {
  final SectionDetailController controller;

  const _BrandsTabContent({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Obx(
          () => SearchFilterRow(
            controller: controller.searchController,
            hintText: controller.searchHintText,
            showFilter: false,
          ),
        ),
        SizedBox(height: 14.h),
        Expanded(
          child: Obx(() {
            if (controller.filteredBrands.isEmpty) {
              final hasSearch =
                  controller.searchController.text.trim().isNotEmpty;
              return AppEmptyState(
                title: hasSearch
                    ? 'لا توجد براندات مطابقة للبحث'
                    : 'لا توجد براندات متاحة',
              );
            }
            return GridView.builder(
              clipBehavior: Clip.none,
              padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 16.h),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12.w,
                mainAxisSpacing: 12.h,
                childAspectRatio: 1.11,
              ),
              itemCount: controller.filteredBrands.length,
              itemBuilder: (context, index) {
                final brand = controller.filteredBrands[index];
                return BrandCardWidget(
                  brand: brand,
                  onTap: () => BrandProductsPage.open(
                    brand: brand,
                    initialProducts: controller.sectionProducts,
                    categoryId: controller.category.id,
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }
}
