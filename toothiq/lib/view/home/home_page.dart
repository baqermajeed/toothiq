import 'dart:math' as math;

import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controller/home_controller.dart';
import '../../utils/app_colors.dart';
import '../../view/search/search_page.dart';
import '../../widget/app_bottom_navigation.dart';
import '../../widget/home/category_chip_widget.dart';
import '../../widget/home/home_banner_carousel.dart';
import '../../widget/home/product_card_widget.dart';
import '../../widget/main_app_bar.dart';
import '../../widget/common/async_state_widgets.dart';
import '../../widget/search_filter_row.dart';
import '../../widget/my_text.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final ScrollController _scrollController;
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final offset = _scrollController.offset;
    if ((offset - _scrollOffset).abs() >= 1) {
      setState(() => _scrollOffset = offset);
    }

    if (!Get.isRegistered<HomeController>()) return;
    final home = Get.find<HomeController>();
    if (!home.hasNextPage.value || home.loadingMore.value) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      home.loadMoreProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final home = Get.find<HomeController>();
    final topInset =
        MediaQuery.paddingOf(context).top + MainAppBar.toolbarHeight();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            Obx(() {
              if (home.isLoading.value && home.products.isEmpty) {
                return Padding(
                  padding: EdgeInsets.only(top: topInset),
                  child: const AppLoadingState(),
                );
              }

              return CustomMaterialIndicator(
                onRefresh: home.refresh,
                backgroundColor: AppColors.primaryLight,
                indicatorBuilder: (context, controller) {
                  return Opacity(
                    opacity: controller.state.isLoading
                        ? 1.0
                        : math.min(controller.value, 1.0),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/icon/toothiqlogo.png',
                        fit: BoxFit.fill,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  );
                },
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: topInset + 4.h),
                      SearchFilterRow(
                        controller: home.searchController,
                        hintText: 'أبحث عن منتج أو متجر محدد ..',
                        readOnly: true,
                        onTap: SearchPage.open,
                        onFilterTap: SearchPage.open,
                      ),
                      if (home.loadError.value != null) ...[
                        SizedBox(height: 8.h),
                        AppErrorState(
                          message: home.loadError.value!,
                          onRetry: () => home.refresh(),
                          compact: true,
                        ),
                      ],
                      if (home.categories.length > 1) ...[
                        SizedBox(height: 8.h),
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
                        SizedBox(height: 5.h),
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
                      SizedBox(height: 8.h),
                      const HomeBannerCarousel(),
                      SizedBox(height: 10.h),
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
                      SizedBox(height: 6.h),
                      if ((home.isLoading.value ||
                              home.isCategoryLoading.value) &&
                          home.products.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.h),
                          child: const AppLoadingState(),
                        )
                      else if (home.products.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          child: const AppEmptyState(
                            title: 'لا توجد منتجات حالياً',
                          ),
                        )
                      else
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: GridView.builder(
                            shrinkWrap: true,
                            primary: false,
                            padding: EdgeInsets.zero,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: home.products.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12.w,
                              mainAxisSpacing: 10.h,
                              mainAxisExtent: ProductCardWidget.cardHeight,
                            ),
                            itemBuilder: (context, index) {
                              return ProductCardWidget(
                                product: home.products[index],
                              );
                            },
                          ),
                        ),
                      AppLoadMoreFooter(
                        isLoading: home.loadingMore.value,
                        hasNextPage: home.hasNextPage.value,
                        onTap: home.loadMoreProducts,
                      ),
                      SizedBox(
                        height:
                            AppBottomNavMetrics.floatingBarReservedHeight.h,
                      ),
                    ],
                  ),
                ),
              );
            }),
            MainGlassHeaderOverlay(scrollOffset: _scrollOffset),
          ],
        ),
      ),
    );
  }
}
