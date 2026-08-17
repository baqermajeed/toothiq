import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../controller/store_detail_controller.dart';
import '../../model/store_model.dart';
import '../../utils/app_colors.dart';
import '../app_back_button.dart';
import '../app_image.dart';
import '../my_text.dart';
import '../search_filter_row.dart';
import 'store_detail_app_bar.dart';
import 'store_tab_chip.dart';

class StoreCoverHeader extends StatelessWidget {
  final StoreModel store;
  final TextEditingController searchController;
  final double topInset;
  final int selectedTabIndex;
  final ValueChanged<int> onTabSelected;

  const StoreCoverHeader({
    super.key,
    required this.store,
    required this.searchController,
    required this.topInset,
    required this.selectedTabIndex,
    required this.onTabSelected,
  });

  static double extraImageHeight() => 128.h;
  static double overlayOverlap() => 28.h;
  static double infoCardApproxHeight() => 114.h;

  static double imageHeightFor(double topInset) =>
      topInset + StoreDetailAppBar.toolbarHeight() + extraImageHeight();

  static double heightFor(double topInset) =>
      imageHeightFor(topInset) + infoCardApproxHeight() - overlayOverlap();

  @override
  Widget build(BuildContext context) {
    final toolbar = StoreDetailAppBar.toolbarHeight();
    final imageHeight = imageHeightFor(topInset);
    final overlap = overlayOverlap();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: imageHeight,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AppImage(
                source: store.logoAsset,
                width: double.infinity,
                height: imageHeight,
                fit: BoxFit.cover,
                errorIcon: Icons.medical_services_rounded,
                fallback: StoreModel.defaultLogoAsset,
                placeholderColor: const Color(0xFF1A3033),
                showLoadingIndicator: false,
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x61000000),
                      Color(0x14000000),
                      Color(0x00000000),
                    ],
                    stops: [0, 0.28, 0.62],
                  ),
                ),
              ),
              Positioned(
                top: topInset,
                left: 8.w,
                right: 8.w,
                height: toolbar,
                child: Row(
                  children: [
                    if (store.rating > 0) ...[
                      StoreRatingBadge(rating: store.rating),
                      SizedBox(width: 8.w),
                    ],
                    Expanded(
                      child: SearchFilterRow(
                        controller: searchController,
                        hintText: 'أبحث عن منتج ..',
                        showFilter: false,
                        frosted: true,
                        centerTextVertically: true,
                        height: 36.h,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    const AppBackButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
        Transform.translate(
          offset: Offset(0, -overlap),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
            child: _StoreInfoOverlayCard(
              store: store,
              selectedTabIndex: selectedTabIndex,
              onTabSelected: onTabSelected,
            ),
          ),
        ),
      ],
    );
  }
}

class _StoreInfoOverlayCard extends StatelessWidget {
  final StoreModel store;
  final int selectedTabIndex;
  final ValueChanged<int> onTabSelected;

  const _StoreInfoOverlayCard({
    required this.store,
    required this.selectedTabIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14.r),
                child: AppImage(
                  source: store.logoAsset,
                  width: 44.w,
                  height: 44.w,
                  fit: BoxFit.cover,
                  errorIcon: Icons.storefront_rounded,
                  fallback: StoreModel.defaultLogoAsset,
                  showLoadingIndicator: false,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MyText(
                      store.name,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.productTitle,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 3.h),
                    if (store.governorateDisplay.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 13.sp,
                            color: AppColors.productStore,
                          ),
                          SizedBox(width: 3.w),
                          Flexible(
                            child: MyText(
                              store.governorateDisplay,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                              textAlign: TextAlign.right,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          SizedBox(
            height: 32.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: StoreDetailController.tabs.length,
              separatorBuilder: (_, index) => SizedBox(width: 8.w),
              itemBuilder: (context, index) {
                return StoreTabChip(
                  label: StoreDetailController.tabs[index],
                  isSelected: selectedTabIndex == index,
                  onTap: () => onTabSelected(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
