import 'dart:math' as math;

import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controller/home_controller.dart';
import '../../utils/app_colors.dart';
import '../../view/search/search_page.dart';
import '../../widget/home/category_chip_widget.dart';
import '../../widget/home/home_banner_carousel.dart';
import '../../widget/home/product_card_widget.dart';
import '../../widget/main_app_bar.dart';
import '../../widget/common/async_state_widgets.dart';
import '../../widget/search_filter_row.dart';
import '../../widget/my_text.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final home = Get.find<HomeController>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: const MainAppBar(title: 'أسم التطبيق'),
        body: Obx(() {
          if (home.isLoading.value && home.products.isEmpty) {
            return const AppLoadingState();
          }

          return CustomMaterialIndicator(
            onRefresh: home.refresh,
            backgroundColor: AppColors.primaryLight,
            indicatorBuilder: (context, controller) {
              return Padding(
                padding: EdgeInsets.all(6.w),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Opacity(
                    opacity: controller.state.isLoading
                        ? 1.0
                        : math.min(controller.value, 1.0),
                    child: Icon(
                      Icons.medical_services_rounded,
                      size: 28.sp,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              );
            },
            child: SingleChildScrollView(
              controller: home.productsScrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 8.h),
                  SearchFilterRow(
                    controller: home.searchController,
                    hintText: 'أبحث عن منتج أو متجر محدد ..',
                    readOnly: true,
                    onTap: SearchPage.open,
                    onFilterTap: SearchPage.open,
                  ),
                  if (home.loadError.value != null) ...[
                    SizedBox(height: 12.h),
                    AppErrorState(
                      message: home.loadError.value!,
                      onRetry: () => home.refresh(),
                      compact: true,
                    ),
                  ],
                  if (home.categories.length > 1) ...[
                    SizedBox(height: 20.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: MyText(
                          'الأقسام الأكثر شهرة',
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    SizedBox(
                      height: 44.h,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        itemCount: home.categories.length,
                        separatorBuilder: (context, index) =>
                            SizedBox(width: 10.w),
                        itemBuilder: (context, index) {
                          return CategoryChipWidget(
                            label: home.categories[index].name,
                            isSelected:
                                home.selectedCategoryIndex.value == index,
                            onTap: () => home.selectCategory(index),
                          );
                        },
                      ),
                    ),
                  ],
                  SizedBox(height: 20.h),
                  const HomeBannerCarousel(),
                  SizedBox(height: 24.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: MyText(
                        'جميع المنتجات',
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  SizedBox(height: 14.h),
                  if (home.isLoading.value || home.isCategoryLoading.value)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 32.h),
                      child: const AppLoadingState(),
                    )
                  else if (home.products.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.h),
                      child: const AppEmptyState(
                        title: 'لا توجد منتجات حالياً',
                      ),
                    )
                  else
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: home.products.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12.w,
                          mainAxisSpacing: 14.h,
                          childAspectRatio: 0.55,
                        ),
                        itemBuilder: (context, index) {
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              return ProductCardWidget(
                                product: home.products[index],
                                maxHeight: constraints.maxHeight,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  AppLoadMoreFooter(
                    isLoading: home.loadingMore.value,
                    hasNextPage: home.hasNextPage.value,
                    onTap: home.loadMoreProducts,
                  ),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
