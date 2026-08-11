import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../bindings/search_binding.dart';
import '../../controller/search_controller.dart';
import '../../model/search_filter_model.dart';
import '../../utils/app_colors.dart';
import '../../view/search/search_filter_page.dart';
import '../../view/stores/store_detail_page.dart';
import '../../widget/common/async_state_widgets.dart';
import '../../widget/home/product_card_widget.dart';
import '../../widget/my_text.dart';
import '../../widget/search/search_results_bar.dart';
import '../../widget/stores/store_card_widget.dart';

class SearchResultsPage extends StatefulWidget {
  const SearchResultsPage({super.key});

  static void open({
    String? query,
    SearchFilterModel? filter,
    bool replace = false,
  }) {
    if (Get.isRegistered<SearchProductsController>()) {
      Get.delete<SearchProductsController>(force: true);
    }
    final binding = SearchBinding();
    final arguments = {'query': query, 'filter': filter};
    const transition = Transition.cupertino;
    const duration = Duration(milliseconds: 250);

    if (replace) {
      Get.off(
        () => const SearchResultsPage(),
        binding: binding,
        arguments: arguments,
        transition: transition,
        duration: duration,
      );
    } else {
      Get.to(
        () => const SearchResultsPage(),
        binding: binding,
        arguments: arguments,
        transition: transition,
        duration: duration,
      )?.then((_) {
        if (Get.isRegistered<SearchProductsController>()) {
          Get.delete<SearchProductsController>(force: true);
        }
      });
    }
  }

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  @override
  Widget build(BuildContext context) {
    final search = Get.find<SearchProductsController>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 8.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: MyText(
                  'البحث',
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.productTitle,
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 16.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Obx(() {
                  final filter = search.filter.value;
                  return SearchResultsBar(
                    controller: search.searchFieldController,
                    hintText: 'أبحث عن منتج أو متجر محدد ..',
                    onSubmitted: (_) => search.search(),
                    onFilterTap: () => _openFilter(search),
                    onCancel: () => Get.back(),
                    subtitle: filter.hasActiveFilters
                        ? _ActiveFiltersRow(filter: filter)
                        : MyText(
                            'نتائج البحث',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.productTitle,
                            textAlign: TextAlign.right,
                          ),
                  );
                }),
              ),
              SizedBox(height: 14.h),
              Expanded(
                child: Obx(() {
                  if (search.loading.value) {
                    return const AppLoadingState();
                  }

                  if (search.loadError.value != null &&
                      search.products.isEmpty &&
                      search.stores.isEmpty) {
                    return AppErrorState(
                      message: search.loadError.value!,
                      onRetry: () => search.search(),
                    );
                  }

                  if (!search.hasSearched.value) {
                    return const AppEmptyState(
                      title: 'لا توجد نتائج',
                      subtitle: 'جرّب كلمات أخرى أو عدّل الفلتر',
                    );
                  }

                  if (search.products.isEmpty && search.stores.isEmpty) {
                    return const AppEmptyState(
                      title: 'لا توجد نتائج',
                      subtitle: 'جرّب كلمات أخرى أو عدّل الفلتر',
                    );
                  }

                  return _SearchResultsBody(search: search);
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openFilter(SearchProductsController search) async {
    final result = await SearchFilterPage.open(
      initialFilter: search.filter.value,
      searchQuery: search.searchFieldController.text.trim(),
    );
    if (result == null) return;
    search.applyFilter(result);
    if (search.query.value.isNotEmpty || result.hasActiveFilters) {
      await search.search();
    }
  }
}

class _ActiveFiltersRow extends StatelessWidget {
  final SearchFilterModel filter;

  const _ActiveFiltersRow({required this.filter});

  @override
  Widget build(BuildContext context) {
    final labels = filter.activeFilterLabels;

    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.start,
      textDirection: TextDirection.rtl,
      children: [
        MyText(
          'تصفية حسب :',
          fontSize: 15.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.productTitle,
        ),
        ...labels.map((label) => _FilterResultChip(label: label)),
      ],
    );
  }
}

class _FilterResultChip extends StatelessWidget {
  final String label;

  const _FilterResultChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.filterPageBackground,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.searchBorder),
      ),
      child: MyText(
        label,
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.productTitle,
      ),
    );
  }
}

class _SearchResultsBody extends StatelessWidget {
  final SearchProductsController search;

  const _SearchResultsBody({required this.search});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: search.scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        if (search.stores.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
              child: MyText(
                'المتاجر',
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.productTitle,
                textAlign: TextAlign.right,
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
            sliver: SliverList.separated(
              itemCount: search.stores.length,
              separatorBuilder: (_, _) => SizedBox(height: 12.h),
              itemBuilder: (context, index) {
                final store = search.stores[index];
                return StoreCardWidget(
                  store: store,
                  onViewStore: () => StoreDetailPage.open(store),
                );
              },
            ),
          ),
        ],
        if (search.products.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
              child: MyText(
                'المنتجات',
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.productTitle,
                textAlign: TextAlign.right,
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12.w,
                mainAxisSpacing: 14.h,
                childAspectRatio: 0.55,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index >= search.products.length) {
                    if (search.loadingMore.value) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return Center(
                      child: TextButton(
                        onPressed: search.loadMore,
                        child: const Text('تحميل المزيد'),
                      ),
                    );
                  }
                  return ProductCardWidget(product: search.products[index]);
                },
                childCount:
                    search.products.length +
                    ((search.loadingMore.value || search.hasNextPage.value)
                        ? 1
                        : 0),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
