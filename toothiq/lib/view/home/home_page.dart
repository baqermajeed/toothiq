import 'dart:math' as math;

import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controller/home_controller.dart';
import '../../model/home_feed_tab.dart';
import '../../utils/app_colors.dart';
import '../../view/search/search_page.dart';
import '../../view/stores/store_detail_page.dart';
import '../../widget/app_bottom_navigation.dart';
import '../../widget/home/home_banner_carousel.dart';
import '../../widget/home/home_catalog_strips.dart';
import '../../widget/home/home_feed_chips.dart';
import '../../widget/home/home_compact_header_overlay.dart';
import '../../widget/home/home_scroll_metrics.dart';
import '../../widget/home/products_grid_widget.dart';
import '../../widget/main_app_bar.dart';
import '../../widget/common/async_state_widgets.dart';
import '../../widget/common/skeleton.dart';
import '../../widget/search_filter_row.dart';
import '../../widget/stores/store_card_widget.dart';
import '../../widget/my_text.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final ScrollController _scrollController;
  final _scrollOffset = ValueNotifier<double>(0);
  bool _logoFullyHidden = false;

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
    if (!_scrollController.hasClients) return;
    final offset = _scrollController.offset;

    final hideEnd = HomeScrollMetrics.logoHideStartOffset() +
        HomeScrollMetrics.logoHideAnimationRange();

    if (offset >= hideEnd) {
      if (!_logoFullyHidden) {
        _logoFullyHidden = true;
        _scrollOffset.value = hideEnd;
      }
    } else {
      _logoFullyHidden = false;
      if ((offset - _scrollOffset.value).abs() >= 1) {
        _scrollOffset.value = offset;
      }
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
                  child: const HomePageSkeleton(),
                );
              }

              return CustomMaterialIndicator(
                onRefresh: () async {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(0);
                  }
                  await home.refresh();
                },
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
                      SizedBox(height: 8.h),
                      const HomeBannerCarousel(),
                      HomeCatalogStrips(
                        categories: home.categories.toList(growable: false),
                        brands: home.brands.toList(growable: false),
                      ),
                      SizedBox(height: 10.h),
                      HomeFeedChips(
                        selected: home.selectedFeed.value,
                        onSelected: home.selectFeed,
                      ),
                      SizedBox(height: 10.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: MyText(
                            home.selectedFeed.value.gridTitle,
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      if (home.feedLoading.value &&
                          home.products.isEmpty &&
                          home.shops.isEmpty)
                        HomeFeedSkeleton(
                          showStores: home.selectedFeed.value.showsShops,
                        )
                      else if (home.selectedFeed.value.showsShops)
                        home.shops.isEmpty
                            ? Padding(
                                padding: EdgeInsets.symmetric(vertical: 14.h),
                                child: AppEmptyState(
                                  title: home.selectedFeed.value.emptyTitle,
                                ),
                              )
                            : Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.w),
                                child: Column(
                                  children: [
                                    for (final store in home.shops) ...[
                                      StoreCardWidget(
                                        store: store,
                                        onViewStore: () =>
                                            StoreDetailPage.open(store),
                                      ),
                                      SizedBox(height: 14.h),
                                    ],
                                  ],
                                ),
                              )
                      else if (home.products.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          child: AppEmptyState(
                            title: home.selectedFeed.value.emptyTitle,
                          ),
                        )
                      else
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: ProductsGridWidget(
                            products: home.products.toList(growable: false),
                            shrinkWrap: true,
                          ),
                        ),
                      AppLoadMoreFooter(
                        isLoading: home.loadingMore.value,
                        hasNextPage: home.hasNextPage.value,
                        onTap: home.loadMoreProducts,
                      ),
                      SizedBox(
                        height: AppBottomNavMetrics.contentBottomPadding(context),
                      ),
                    ],
                  ),
                ),
              );
            }),
            MainGlassHeaderOverlay(
              scrollOffsetListenable: _scrollOffset,
            ),
            HomeCompactHeaderOverlay(
              scrollOffsetListenable: _scrollOffset,
              searchController: home.searchController,
            ),
          ],
        ),
      ),
    );
  }
}
