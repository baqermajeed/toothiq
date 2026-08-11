import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controllers/cart_controller.dart';
import '../../widgets/cart/cart_bottom_sheet.dart';
import '../../controllers/search_products_controller.dart';
import '../../utils/price_formatter.dart';
import '../../core/config/api_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/product.dart';
import '../../widgets/common/app_spacing.dart';
import '../../widgets/common/loading/shimmer_box.dart';

/// شاشة نتائج البحث — حقل بحث في الهيدر وشبكة منتجات مع أنيميشن.
class SearchResultsScreen extends GetView<SearchProductsController> {
  const SearchResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20.sp, color: colorScheme.onSurface),
          onPressed: () => Get.back(),
        ),
        titleSpacing: 0,
        title: Padding(
          padding: EdgeInsets.only(left: 8.w, right: AppSpacing.lg),
          child: _SearchField(
            onSubmitted: (_) => controller.search(),
          ),
        ),
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return _buildLoadingShimmer(context);
        }
        if (!controller.hasSearched.value || controller.query.value.isEmpty) {
          return _buildPlaceholder(context);
        }
        if (controller.products.isEmpty) {
          return controller.error.value != null
              ? _buildErrorState(context, controller.error.value!)
              : _buildEmptyState(context);
        }
        return _buildProductsGrid(context);
      }),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.6, end: 1),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            builder: (context, value, child) => Transform.scale(scale: value, child: child),
            child: Icon(
              Icons.search_rounded,
              size: 80.sp,
              color: colorScheme.primary.withValues(alpha: 0.5),
            ),
          ),
          AppSpacing.verticalLg,
          Text(
            'ابحث عن منتجات',
            style: TextStyle(
              fontFamily: kFontFamilyCairo,
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.verticalXs,
          Text(
            'اكتب اسم المنتج ثم اضغط بحث',
            style: TextStyle(
              fontFamily: kFontFamilyCairo,
              fontSize: 14.sp,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
        ],
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
              style: TextStyle(
                fontFamily: kFontFamilyCairo,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
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
            Icons.inbox_rounded,
            size: 72.sp,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          AppSpacing.verticalLg,
          Text(
            'لا توجد نتائج',
            style: TextStyle(
              fontFamily: kFontFamilyCairo,
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          AppSpacing.verticalXs,
          Text(
            'جرّب كلمات أخرى',
            style: TextStyle(
              fontFamily: kFontFamilyCairo,
              fontSize: 14.sp,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14.h,
          crossAxisSpacing: 14.w,
          childAspectRatio: 0.7,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => ShimmerBox(
          width: double.infinity,
          height: double.infinity,
          borderRadius: BorderRadius.circular(22.r),
        ),
      ),
    );
  }

  Widget _buildProductsGrid(BuildContext context) {
    return CustomScrollView(
      controller: controller.scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.lg, 8.h, AppSpacing.lg, AppSpacing.sm),
            child: Obx(() => Text(
              '${controller.products.length} منتج',
              style: TextStyle(
                fontFamily: kFontFamilyCairo,
                fontSize: 14.sp,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14.h,
              crossAxisSpacing: 14.w,
              childAspectRatio: 0.7,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final product = controller.products[i];
                return _AnimatedProductCard(
                  index: i,
                  product: product,
                  onTap: () {
                    final map = product.toMap();
                    if (product.id != null) map['_id'] = product.id;
                    Get.toNamed('/product', arguments: map);
                  },
                );
              },
              childCount: controller.products.length,
            ),
          ),
        ),
        if (controller.loadingMore.value)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(
                child: SizedBox(
                  width: 24.w,
                  height: 24.h,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ),
        SliverToBoxAdapter(child: SizedBox(height: 100.h)),
      ],
    );
  }
}

/// حقل بحث عصري مع أيقونة ومسح وأنيميشن.
class _SearchField extends StatelessWidget {
  const _SearchField({this.onSubmitted});

  final void Function(String)? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<SearchProductsController>();
    final colorScheme = Theme.of(context).colorScheme;

    return Obx(() => Container(
      height: 44.h,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.5)),
      ),
      child: TextField(
        controller: c.searchController,
        onChanged: c.setQuery,
        onSubmitted: (_) {
          c.search();
        },
        textInputAction: TextInputAction.search,
        style: TextStyle(
          fontFamily: kFontFamilyCairo,
          fontSize: 15.sp,
          color: colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: 'ابحث عن منتجات...',
          hintStyle: TextStyle(
            fontFamily: kFontFamilyCairo,
            fontSize: 14.sp,
            color: colorScheme.onSurfaceVariant,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 22.sp,
            color: colorScheme.primary,
          ),
          suffixIcon: c.query.value.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear_rounded, size: 20.sp, color: colorScheme.onSurfaceVariant),
                  onPressed: () {
                    c.clear();
                  },
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        ),
      ),
    ));
  }
}

/// كارت منتج مع أنيميشن ظهور متتابع.
class _AnimatedProductCard extends StatelessWidget {
  const _AnimatedProductCard({
    required this.index,
    required this.product,
    required this.onTap,
  });

  final int index;
  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final emojiBg = isDark
        ? colorScheme.primaryContainer.withValues(alpha: 0.7)
        : AppColors.primaryLight.withValues(alpha: 0.7);
    final imageUrl = ApiConfig.productImageUrl(product.image);

    return TweenAnimationBuilder<double>(
      key: ValueKey('${product.id ?? product.name}-$index'),
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index % 4) * 80),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder: (_, __) => Container(
                            color: emojiBg,
                            alignment: Alignment.center,
                            child: Text(product.emoji ?? '🛒', style: TextStyle(fontSize: 44.sp)),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: emojiBg,
                            alignment: Alignment.center,
                            child: Text(product.emoji ?? '🛒', style: TextStyle(fontSize: 44.sp)),
                          ),
                        )
                      : Container(
                          color: emojiBg,
                          alignment: Alignment.center,
                          child: Text(product.emoji ?? '🛒', style: TextStyle(fontSize: 44.sp)),
                        ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 12.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          (product.description != null && product.description!.isNotEmpty)
                              ? '${product.name} · ${product.description}'
                              : product.name,
                          style: TextStyle(
                            fontFamily: kFontFamilyCairo,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          product.shopName ?? '',
                          style: TextStyle(
                            fontFamily: kFontFamilyCairo,
                            fontSize: 11.sp,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              formatPrice(product.price),
                              style: TextStyle(
                                fontFamily: kFontFamilyCairo,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.primary,
                              ),
                            ),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  final cartController = Get.find<CartController>();
                                  final inCart = cartController.isInCart(product);
                                  if (inCart) {
                                    cartController.removeProduct(product);
                                  } else {
                                    cartController.add(product, quantity: 1);
                                    CartBottomSheet.show();
                                  }
                                },
                                borderRadius: BorderRadius.circular(12.r),
                                child: Obx(() {
                                  final cartController = Get.find<CartController>();
                                  final inCart = cartController.isInCart(product);
                                  return Container(
                                    padding: EdgeInsets.all(8.w),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary,
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    child: Icon(
                                      inCart ? Icons.check_rounded : Icons.add_rounded,
                                      size: 18.sp,
                                      color: colorScheme.onPrimary,
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
