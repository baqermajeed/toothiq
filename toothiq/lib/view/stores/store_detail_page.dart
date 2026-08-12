import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../bindings/store_detail_binding.dart';
import '../../controller/store_detail_controller.dart';
import '../../model/store_model.dart';
import '../../utils/app_colors.dart';
import '../../widget/common/async_state_widgets.dart';
import '../../widget/categories/category_card_widget.dart';
import '../../widget/home/product_card_widget.dart';
import '../../widget/home/products_grid_widget.dart';
import '../../widget/my_text.dart';
import '../../widget/search_filter_row.dart';
import '../../widget/section/brand_card_widget.dart';
import '../../widget/app_image.dart';
import '../../widget/stores/store_about_tab_content.dart';
import '../../widget/stores/store_detail_app_bar.dart';
import '../../widget/stores/store_review_card_widget.dart';
import '../../widget/stores/store_review_input_bar.dart';
import '../../widget/stores/store_tab_chip.dart';

class StoreDetailPage extends GetView<StoreDetailController> {
  const StoreDetailPage({super.key});

  static void open(StoreModel store) {
    Get.to(
      () => const StoreDetailPage(),
      binding: StoreDetailBinding(store: store),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(56.h),
          child: Obx(
            () => StoreDetailAppBar(rating: controller.viewStore.rating),
          ),
        ),
        resizeToAvoidBottomInset: true,
        body: Obx(() {
          final tab = controller.selectedTabIndex.value;
          final showReviews = tab == 3;
          final store = controller.viewStore;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (controller.loadError.value != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
                  child: AppErrorState(
                    message: controller.loadError.value!,
                    onRetry: () => controller.refresh(),
                    compact: true,
                  ),
                ),
              SizedBox(height: 8.h),
              _StoreHeader(store: store),
              SizedBox(height: 20.h),
              SizedBox(
                height: 44.h,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: StoreDetailController.tabs.length,
                  separatorBuilder: (_, index) => SizedBox(width: 10.w),
                  itemBuilder: (context, index) {
                    return StoreTabChip(
                      label: StoreDetailController.tabs[index],
                      isSelected: tab == index,
                      onTap: () => controller.selectTab(index),
                    );
                  },
                ),
              ),
              Expanded(
                child: controller.isLoading.value && controller.products.isEmpty
                    ? const AppLoadingState()
                    : _StoreTabContent(tab: tab, controller: controller),
              ),
              if (showReviews)
                StoreReviewInputBar(
                  controller: controller.reviewController,
                  onSend: controller.submitReview,
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _StoreTabContent extends StatelessWidget {
  final int tab;
  final StoreDetailController controller;

  const _StoreTabContent({required this.tab, required this.controller});

  @override
  Widget build(BuildContext context) {
    switch (tab) {
      case 0:
        return _ProductsTabContent(controller: controller);
      case 1:
        return _SectionsTabContent(controller: controller);
      case 2:
        return _BrandsTabContent(controller: controller);
      case 3:
        return _ReviewsTabContent(controller: controller);
      case 4:
        return StoreAboutTabContent(controller: controller);
      default:
        return const SizedBox.shrink();
    }
  }
}

class _ProductsTabContent extends StatelessWidget {
  final StoreDetailController controller;

  const _ProductsTabContent({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final products = controller.filteredProducts;
      final popularProducts = controller.popularProducts;
      if (products.isEmpty) {
        return Center(
          child: MyText(
            'لا توجد منتجات في هذا المتجر حالياً',
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            textAlign: TextAlign.center,
          ),
        );
      }

      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(bottom: 24.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 16.h),
            SearchFilterRow(
              controller: controller.searchController,
              hintText: 'أبحث عن منتج أو متجر محدد ..',
              onFilterTap: () {},
            ),
            SizedBox(height: 20.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Align(
                alignment: Alignment.centerRight,
                child: MyText(
                  'أشهر المنتجات',
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.productTitle,
                ),
              ),
            ),
            SizedBox(height: 14.h),
            SizedBox(
              height: 290.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: popularProducts.length,
                separatorBuilder: (_, index) => SizedBox(width: 12.w),
                itemBuilder: (context, index) {
                  final product = popularProducts[index];
                  return SizedBox(
                    width: 168.w,
                    child: ProductCardWidget(product: product),
                  );
                },
              ),
            ),
            SizedBox(height: 24.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Align(
                alignment: Alignment.centerRight,
                child: MyText(
                  'جميع المنتجات',
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.productTitle,
                ),
              ),
            ),
            SizedBox(height: 14.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: ProductsGridWidget(
                products: products,
                shrinkWrap: true,
              ),
            ),
            AppLoadMoreFooter(
              isLoading: controller.loadingMoreProducts.value,
              hasNextPage: controller.hasNextProductsPage.value,
              onTap: controller.loadMoreProducts,
            ),
          ],
        ),
      );
    });
  }
}

class _SectionsTabContent extends StatelessWidget {
  final StoreDetailController controller;

  const _SectionsTabContent({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final categories = controller.filteredCategories;
      if (categories.isEmpty) {
        return Center(
          child: MyText(
            'لا توجد أقسام متاحة',
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            textAlign: TextAlign.center,
          ),
        );
      }

      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(bottom: 24.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 16.h),
            SearchFilterRow(
              controller: controller.searchController,
              hintText: 'أبحث عن قسم ..',
              onFilterTap: () {},
            ),
            SizedBox(height: 16.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: GridView.builder(
                clipBehavior: Clip.none,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12.w,
                  mainAxisSpacing: 12.h,
                  childAspectRatio: 1.11,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return CategoryCardWidget(
                    category: category,
                    onTap: () => controller.onCategoryTap(category),
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _BrandsTabContent extends StatelessWidget {
  final StoreDetailController controller;

  const _BrandsTabContent({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final brands = controller.filteredBrands;
      if (brands.isEmpty) {
        return Center(
          child: MyText(
            'لا توجد براندات متاحة',
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            textAlign: TextAlign.center,
          ),
        );
      }

      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(bottom: 24.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 16.h),
            SearchFilterRow(
              controller: controller.searchController,
              hintText: 'أبحث عن براند محدد ..',
              onFilterTap: () {},
            ),
            SizedBox(height: 16.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: GridView.builder(
                clipBehavior: Clip.none,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12.w,
                  mainAxisSpacing: 12.h,
                  childAspectRatio: 1.11,
                ),
                itemCount: brands.length,
                itemBuilder: (context, index) {
                  final brand = brands[index];
                  return BrandCardWidget(
                    brand: brand,
                    onTap: () => controller.onBrandTap(brand),
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _ReviewsTabContent extends StatelessWidget {
  final StoreDetailController controller;

  const _ReviewsTabContent({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 20.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Align(
            alignment: Alignment.centerRight,
            child: MyText(
              'آراء الزبائن',
              fontSize: 17.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.productTitle,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        Expanded(
          child: Obx(() {
            if (controller.reviews.isEmpty) {
              return const AppEmptyState(title: 'لا توجد تقييمات حالياً');
            }
            return ListView.separated(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
              physics: const BouncingScrollPhysics(),
              itemCount: controller.reviews.length,
              separatorBuilder: (_, index) => Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.orderCardDivider.withValues(alpha: 0.7),
                ),
              ),
              itemBuilder: (context, index) {
                return StoreReviewCardWidget(review: controller.reviews[index]);
              },
            );
          }),
        ),
      ],
    );
  }
}

class _StoreHeader extends StatelessWidget {
  final StoreModel store;

  const _StoreHeader({required this.store});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppImage(
          source: store.logoAsset,
          width: 88.w,
          height: 88.w,
          fit: BoxFit.contain,
          errorIcon: Icons.medical_services_rounded,
        ),
        SizedBox(height: 14.h),
        MyText(
          store.name,
          fontSize: 20.sp,
          fontWeight: FontWeight.w800,
          color: AppColors.productTitle,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 6.h),
        MyText(
          store.address,
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
