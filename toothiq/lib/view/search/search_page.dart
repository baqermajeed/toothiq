import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../bindings/search_binding.dart';
import '../../bindings/search_page_binding.dart';
import '../../controller/search_page_controller.dart';
import '../../model/store_model.dart';
import '../../utils/app_colors.dart';
import '../../view/search/search_results_page.dart';
import '../../view/stores/store_detail_page.dart';
import '../../widget/my_text.dart';
import '../../widget/search/search_inline_bar.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  static void open() {
    Get.to(
      () => const SearchPage(),
      binding: SearchPageBinding(),
      transition: Transition.downToUp,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final TextEditingController _searchController;
  late final FocusNode _focusNode;
  late final SearchPageController _controller;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _focusNode = FocusNode();
    _controller = Get.find<SearchPageController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _focusNode.canRequestFocus) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    if (Get.isRegistered<SearchPageController>()) {
      Get.delete<SearchPageController>(force: true);
    }
    super.dispose();
  }

  void _submitSearch([String? value]) {
    final query = (value ?? _searchController.text).trim();
    if (query.isEmpty) return;

    _controller.addToHistory(query);
    FocusManager.instance.primaryFocus?.unfocus();

    Get.off(
      () => const SearchResultsPage(),
      binding: SearchBinding(),
      arguments: {
        'query': query,
        'filter': _controller.filter.value,
      },
      transition: Transition.cupertino,
      duration: const Duration(milliseconds: 250),
    );
  }

  void _openFilter() {
    _controller.openFilter(_searchController.text.trim());
  }

  void _cancel() => Get.back();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        resizeToAvoidBottomInset: true,
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
                child: Row(
                  children: [
                    Expanded(
                      child: SearchInlineBar(
                        controller: _searchController,
                        focusNode: _focusNode,
                        hintText: 'أبحث عن منتج أو متجر محدد ..',
                        onSubmitted: _submitSearch,
                        onFilterTap: _openFilter,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    GestureDetector(
                      onTap: _cancel,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                        child: MyText(
                          'الغاء',
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SearchHistorySection(
                        controller: _controller,
                        onItemTap: (item) {
                          _searchController.text = item;
                          _submitSearch(item);
                        },
                      ),
                      SizedBox(height: 20.h),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.searchBorder,
                      ),
                      SizedBox(height: 20.h),
                      _RecentStoresSection(controller: _controller),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchHistorySection extends StatelessWidget {
  final SearchPageController controller;
  final ValueChanged<String> onItemTap;

  const _SearchHistorySection({
    required this.controller,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final history = controller.searchHistory;
      if (history.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: MyText(
                  'سجل البحث',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.productTitle,
                  textAlign: TextAlign.right,
                ),
              ),
              GestureDetector(
                onTap: controller.clearHistory,
                behavior: HitTestBehavior.opaque,
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.settingsDelete,
                  size: 22.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          ...history.map(
            (item) => _SearchHistoryItem(
              label: item,
              onTap: () => onItemTap(item),
              onRemove: () => controller.removeHistoryItem(item),
            ),
          ),
        ],
      );
    });
  }
}

class _SearchHistoryItem extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _SearchHistoryItem({
    required this.label,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: MyText(
                label,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                textAlign: TextAlign.right,
              ),
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
              child: Icon(
                Icons.close,
                size: 18.sp,
                color: AppColors.textLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentStoresSection extends StatelessWidget {
  final SearchPageController controller;

  const _RecentStoresSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final stores = controller.recentStores;
      if (stores.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MyText(
            'متاجر تمت زيارتها مؤخرًا',
            fontSize: 16.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.productTitle,
            textAlign: TextAlign.right,
          ),
          SizedBox(height: 14.h),
          ...stores.map(
            (store) => Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: _RecentStoreCard(
                store: store,
                onTap: () => StoreDetailPage.open(store),
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _RecentStoreCard extends StatelessWidget {
  final StoreModel store;
  final VoidCallback onTap;

  const _RecentStoreCard({
    required this.store,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20.r),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: AppColors.cardBorder),
          ),
          padding: EdgeInsets.all(14.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12.r),
                          child: Image.asset(
                            store.logoAsset,
                            width: 48.w,
                            height: 48.w,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              width: 48.w,
                              height: 48.w,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Icon(
                                Icons.medical_services_rounded,
                                color: AppColors.productStore,
                                size: 26.sp,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: MyText(
                            store.name,
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.productStore,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12.w),
                  _RatingBadge(rating: store.rating),
                ],
              ),
              SizedBox(height: 12.h),
              Text(
                store.description,
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Expo Arabic',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.productDescription,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  final double rating;

  const _RatingBadge({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: AppColors.ratingBackground,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontFamily: 'Expo Arabic',
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.productTitle,
            ),
          ),
          SizedBox(width: 4.w),
          Icon(
            Icons.star_rounded,
            color: AppColors.ratingStar,
            size: 18.sp,
          ),
        ],
      ),
    );
  }
}
