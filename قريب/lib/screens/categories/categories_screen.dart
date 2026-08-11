import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controllers/categories_controller.dart';
import '../../core/config/api_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/shop.dart';
import '../../widgets/common/app_spacing.dart';
import '../../widgets/common/loading/shimmer_box.dart';

/// محتوى صفحة التصنيفات — GetX stateless مع عرض التصنيفات والمحلات (API + بيانات وهمية).
class CategoriesContent extends GetView<CategoriesController> {
  const CategoriesContent({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
            child: _HeaderSection(),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: _SectionTitle(title: 'التصنيفات'),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
        SliverToBoxAdapter(
          child: Obx(() {
            final cats = controller.categories;
            return SizedBox(
              height: 55.h,
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: cats.length,
                separatorBuilder: (_, __) => SizedBox(width: 10.w),
                itemBuilder: (context, i) {
                  final cat = cats[i];
                  return Obx(() => _CategoryChip(
                    icon: cat.icon,
                    label: cat.name,
                    isSelected: controller.selectedCategoryIndex.value == i,
                    onTap: () => controller.selectCategory(i),
                  ));
                },
              ),
            );
          }),
        ),
        SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SectionTitle(title: 'المحلات'),
                Obx(() {
                  final list = controller.displayedShops;
                  return Text(
                    '${list.length}',
                    style: TextStyle(
                      fontFamily: kFontFamilyCairo,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),
        Obx(() {
          if (controller.loading.value) {
            return SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14.h,
                  crossAxisSpacing: 14.w,
                 
                  childAspectRatio: 0.82,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => ShimmerBox(
                    width: double.infinity,
                    height: double.infinity,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  childCount: 6,
                ),
              ),
            );
          }
          final shops = controller.displayedShops;
          if (shops.isEmpty) {
            return SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(),
            );
          }
          return SliverPadding(
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
                  final shop = shops[i];
                  return _ShopGridCard(shop: shop);
                },
                childCount: shops.length,
              ),
            ),
          );
        }),
        if (!controller.loading.value && controller.error.value != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(left: AppSpacing.lg, right: AppSpacing.lg, top: AppSpacing.md),
              child: _ErrorBanner(message: controller.error.value!),
            ),
          ),
        SliverToBoxAdapter(child: SizedBox(height: 100.h)),
      ],
    );
  }
}

class _HeaderSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradientColors = isDark
        ? [colorScheme.primaryContainer, colorScheme.surfaceContainerHigh]
        : [AppColors.primaryLight, AppColors.primaryBeige.withValues(alpha: 0.6)];
    final textColor = isDark ? colorScheme.onPrimaryContainer : AppColors.primaryDark;
    final subTextColor = isDark ? colorScheme.onSurfaceVariant : AppColors.textSecondary;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 20.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'استكشف التصنيفات',
            style: TextStyle(
              fontFamily: kFontFamilyCairo,
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'اختر تصنيفاً أو تصفح كل المحلات',
            style: TextStyle(
              fontFamily: kFontFamilyCairo,
              fontSize: 14.sp,
              color: subTextColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      title,
      style: TextStyle(
        fontFamily: kFontFamilyCairo,
        fontSize: 18.sp,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedBg = isDark ? colorScheme.primary : AppColors.primaryDark;
    final selectedFg = isDark ? colorScheme.onPrimary : AppColors.primaryLight;
    final unselectedBg = colorScheme.surfaceContainerHighest;
    final unselectedFg = colorScheme.onSurface;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : unselectedBg,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: isSelected
                ? (isDark ? colorScheme.primary : AppColors.primaryDark)
                : colorScheme.outline.withValues(alpha: 0.6),
            width: isSelected ? 2 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: isSelected ? 0.15 : 0.04),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: TextStyle(fontSize: 20.sp)),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                fontFamily: kFontFamilyCairo,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: isSelected ? selectedFg : unselectedFg,
              ),
            ),
          ],
        ),
      ),
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
    final distanceStr = shop.distance != null
        ? '${shop.distance!.toStringAsFixed(1)} كم'
        : '—';
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

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.storefront_rounded,
              size: 64.sp,
              color: colorScheme.primary.withValues(alpha: 0.5),
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              'لا توجد محلات في هذا التصنيف',
              style: TextStyle(
                fontFamily: kFontFamilyCairo,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 18.sp,
            color: Theme.of(context).colorScheme.error,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: kFontFamilyCairo,
                fontSize: 12.sp,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
