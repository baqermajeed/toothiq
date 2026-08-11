import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controllers/all_shops_controller.dart';
import '../../core/config/api_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/shop.dart';
import '../../widgets/common/app_spacing.dart';
import '../../widgets/common/load_more_footer.dart';
import '../../widgets/common/loading/shimmer_box.dart';

/// صفحة «كل المحلات» — شبكة محلات مع pagination وجلب المزيد عند التمرير.
class AllShopsScreen extends GetView<AllShopsController> {
  const AllShopsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20.sp,
            color: colorScheme.onSurface,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'كل المحلات',
          style: TextStyle(
            fontFamily: kFontFamilyCairo,
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return _buildLoadingShimmer(context);
        }
        if (controller.error.value != null && controller.shops.isEmpty) {
          return _buildErrorState(context, controller.error.value!);
        }
        if (controller.shops.isEmpty) {
          return _buildEmptyState(context);
        }
        return _buildShopsGrid(context);
      }),
    );
  }

  Widget _buildLoadingShimmer(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: GridView.builder(
        padding: EdgeInsets.only(top: AppSpacing.md, bottom: 100.h),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14.h,
          crossAxisSpacing: 14.w,
          mainAxisExtent: 230.h,
          childAspectRatio: 0.82,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => ShimmerBox(
          width: double.infinity,
          height: double.infinity,
          borderRadius: BorderRadius.circular(20.r),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 72.sp,
              color: colorScheme.error.withValues(alpha: 0.7),
            ),
            AppSpacing.verticalLg,
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: kFontFamilyCairo,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.storefront_rounded,
            size: 72.sp,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          AppSpacing.verticalLg,
          Text(
            'لا توجد محلات حالياً',
            style: TextStyle(
              fontFamily: kFontFamilyCairo,
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopsGrid(BuildContext context) {
    return CustomScrollView(
      controller: controller.scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14.h,
              crossAxisSpacing: 14.w,
              mainAxisExtent: 230.h,
              childAspectRatio: 0.82,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final shop = controller.shops[i];
                return _ShopGridCard(shop: shop);
              },
              childCount: controller.shops.length,
            ),
          ),
        ),
        if (controller.hasNextPage.value || controller.loadingMore.value)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: LoadMoreFooter(
                isLoading: controller.loadingMore.value,
                hasMore: controller.hasNextPage.value,
                onLoadMore: controller.loadMore,
                compact: false,
              ),
            ),
          ),
        SliverToBoxAdapter(child: SizedBox(height: 100.h)),
      ],
    );
  }
}

class _ShopGridCard extends StatelessWidget {
  const _ShopGridCard({required this.shop});
  final Shop shop;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconBg = isDark ? colorScheme.primaryContainer : AppColors.primaryLight;
    final iconBorder = isDark ? colorScheme.outline : AppColors.border;
    final imageUrl = ApiConfig.shopImageUrl(shop.image);
    return GestureDetector(
      onTap: () => Get.toNamed('/shop-products', arguments: shop),
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: SizedBox(
                width: double.infinity,
                height: 125.h,
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: iconBg,
                          alignment: Alignment.center,
                          child: Text('🛒', style: TextStyle(fontSize: 32.sp)),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: iconBg,
                          alignment: Alignment.center,
                          child: Text('🛒', style: TextStyle(fontSize: 32.sp)),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: iconBg,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: iconBorder),
                        ),
                        alignment: Alignment.center,
                        child: Text('🛒', style: TextStyle(fontSize: 32.sp)),
                      ),
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              shop.name,
              style: TextStyle(
                fontFamily: kFontFamilyCairo,
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                shop.category,
                style: TextStyle(
                  fontFamily: kFontFamilyCairo,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
