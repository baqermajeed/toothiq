import 'dart:math' as math;

import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../bindings/store_detail_binding.dart';
import '../../controller/store_detail_controller.dart';
import '../../model/store_model.dart';
import '../../utils/app_colors.dart';
import '../../widget/common/async_state_widgets.dart';
import '../../widget/common/skeleton.dart';
import '../../widget/app_back_button.dart';
import '../../widget/categories/category_card_widget.dart';
import '../../widget/home/product_cards_strip.dart';
import '../../widget/home/products_grid_widget.dart';
import '../../widget/my_text.dart';
import '../../widget/stores/store_about_tab_content.dart';
import '../../widget/stores/store_compact_header_overlay.dart';
import '../../widget/stores/store_cover_header.dart';
import '../../widget/stores/store_review_card_widget.dart';
import '../../widget/stores/store_review_input_bar.dart';
import '../../widget/stores/store_scroll_metrics.dart';

class StoreDetailPage extends StatefulWidget {
  const StoreDetailPage({super.key});

  static void open(StoreModel store) {
    Get.to(
      () => const StoreDetailPage(),
      binding: StoreDetailBinding(store: store),
    );
  }

  @override
  State<StoreDetailPage> createState() => _StoreDetailPageState();
}

class _StoreDetailPageState extends State<StoreDetailPage> {
  late final ScrollController _scrollController;
  final _scrollOffset = ValueNotifier<double>(0);
  bool _coverFullyHidden = false;

  StoreDetailController get controller => Get.find<StoreDetailController>();

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
    _scrollOffset.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted || !_scrollController.hasClients) return;
    final offset = _scrollController.offset;
    final topInset = MediaQuery.paddingOf(context).top;
    final hideEnd = StoreScrollMetrics.hideStartOffset(topInset) +
        StoreScrollMetrics.hideAnimationRange();

    if (offset >= hideEnd) {
      if (!_coverFullyHidden) {
        _coverFullyHidden = true;
        _scrollOffset.value = hideEnd;
      }
    } else {
      _coverFullyHidden = false;
      if ((offset - _scrollOffset.value).abs() >= 1) {
        _scrollOffset.value = offset;
      }
    }

    if (controller.selectedTabIndex.value != 0) return;
    if (controller.loadingMoreProducts.value ||
        !controller.hasNextProductsPage.value) {
      return;
    }
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      controller.loadMoreProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: AppColors.background,
          resizeToAvoidBottomInset: true,
          body: Stack(
            children: [
              Obx(() {
                final tab = controller.selectedTabIndex.value;
                final showReviews = tab == 2;
                final store = controller.currentStore.value;
                final error = controller.loadError.value;

                if (store == null) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: topInset),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.w),
                          child: const AppBackButton(),
                        ),
                      ),
                      Expanded(
                        child: error != null
                            ? AppErrorState(
                                message: error,
                                onRetry: () => controller.refresh(),
                              )
                            : const StoreDetailSkeleton(),
                      ),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: CustomMaterialIndicator(
                        onRefresh: () async {
                          if (_scrollController.hasClients) {
                            _scrollController.jumpTo(0);
                          }
                          await controller.refresh();
                        },
                        useMaterialContainer: false,
                        elevation: 0,
                        edgeOffset: topInset,
                        displacement: 16,
                        indicatorBuilder: (context, ctrl) {
                          return Opacity(
                            opacity: ctrl.state.isLoading
                                ? 1.0
                                : math.min(ctrl.value, 1.0),
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
                            parent: ClampingScrollPhysics(),
                          ),
                          padding: EdgeInsets.only(bottom: 24.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            StoreCoverHeader(
                              store: store,
                              searchController: controller.searchController,
                              topInset: topInset,
                              selectedTabIndex: tab,
                              onTabSelected: controller.selectTab,
                            ),
                            Transform.translate(
                              offset: Offset(
                                0,
                                -StoreCoverHeader.overlayOverlap(),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (controller.loadError.value != null)
                                    Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        16.w,
                                        10.h,
                                        16.w,
                                        0,
                                      ),
                                      child: AppErrorState(
                                        message: controller.loadError.value!,
                                        onRetry: () => controller.refresh(),
                                        compact: true,
                                      ),
                                    ),
                                  _StoreTabContent(
                                    tab: tab,
                                    controller: controller,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                    if (showReviews)
                      StoreReviewInputBar(
                        controller: controller.reviewController,
                        onSend: controller.submitReview,
                      ),
                  ],
                );
              }),
              StoreCompactHeaderOverlay(
                scrollOffsetListenable: _scrollOffset,
                searchController: controller.searchController,
                hideStartOffset: StoreScrollMetrics.hideStartOffset(topInset),
              ),
            ],
          ),
        ),
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
        return _ReviewsTabContent(controller: controller);
      case 3:
        return StoreAboutTabContent(
          controller: controller,
          embedInParentScroll: true,
        );
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
      final popularProducts = controller.popularProducts.toList(growable: false);
      final offerProducts = controller.offerProducts.toList(growable: false);
      if (products.isEmpty) {
        if (controller.isLoading.value) {
          return const Padding(
            padding: EdgeInsets.only(top: 8),
            child: ProductGridSkeleton(itemCount: 4, shrinkWrap: true),
          );
        }
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 48.h, horizontal: 24.w),
          child: MyText(
            'لا توجد منتجات في هذا المتجر حالياً',
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            textAlign: TextAlign.center,
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (offerProducts.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Align(
                alignment: Alignment.centerRight,
                child: MyText(
                  'العروض',
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.productTitle,
                ),
              ),
            ),
            SizedBox(height: 14.h),
            ProductCardsStrip(products: offerProducts),
            SizedBox(height: 10.h),
          ],
          if (popularProducts.isNotEmpty) ...[
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
            ProductCardsStrip(
              products: popularProducts,
              showPopularBadge: true,
            ),
            SizedBox(height: 10.h),
          ],
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
        if (controller.isLoading.value) {
          return Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
            child: const CategoriesGridSkeleton(
              itemCount: 8,
              shrinkWrap: true,
            ),
          );
        }
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 48.h, horizontal: 24.w),
          child: MyText(
            'لا توجد أقسام متاحة',
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            textAlign: TextAlign.center,
          ),
        );
      }

      return Padding(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
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
        Obx(() {
          if (controller.reviews.isEmpty) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 32.h),
              child: const AppEmptyState(title: 'لا توجد تقييمات حالياً'),
            );
          }
          return ListView.separated(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
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
      ],
    );
  }
}
