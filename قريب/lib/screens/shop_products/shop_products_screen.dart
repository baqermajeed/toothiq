import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controllers/cart_controller.dart';
import '../../controllers/shop_products_controller.dart';
import '../../utils/price_formatter.dart';
import '../../widgets/cart/cart_bottom_sheet.dart';
import '../../core/config/api_config.dart';
import '../../core/theme/app_colors.dart';
import '../../models/shop.dart';
import '../../models/product.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common/app_spacing.dart';
import '../../widgets/common/load_more_footer.dart';
import '../../widgets/common/loading/shimmer_box.dart';

/// شاشة منتجات المحل — تُفتح عند الضغط على محل في الصفحة الرئيسية.
/// المُدخلات: Shop أو Map عبر Get.arguments.
class ShopProductsScreen extends GetView<ShopProductsController> {
  const ShopProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Obx(() => Text(
          controller.shop.value?.name ?? 'منتجات المحل',
          style: TextStyle(
            fontFamily: kFontFamilyCairo,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        )),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20.sp),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return _buildLoadingShimmer();
        }
        final productsToShow = controller.productsToShow;
        if (productsToShow.isEmpty) {
          return _buildEmptyState(context);
        }
        return CustomScrollView(
          controller: controller.scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            if (controller.shop.value != null) _ShopHeader(shop: controller.shop.value!),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                child: TextField(
                  controller: controller.searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: controller.applySearch,
                  decoration: InputDecoration(
                    hintText: 'ابحث داخل منتجات هذا المحل...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: Obx(() {
                      final hasText = controller.searchQuery.value.isNotEmpty;
                      if (!hasText) {
                        return const SizedBox.shrink();
                      }
                      return IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: controller.clearSearch,
                      );
                    }),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 10.h,
                    ),
                  ),
                ),
              ),
            ),
            if (controller.error.value != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
                  child: Text(
                    controller.error.value!,
                    style: TextStyle(
                      fontFamily: kFontFamilyCairo,
                      fontSize: 12.sp,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14.h,
                  crossAxisSpacing: 14.w,
                  childAspectRatio: 0.7,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final product = productsToShow[i];
                    final productMap = product.toMap();
                    if (!productMap.containsKey('_id') && product.id != null) {
                      productMap['_id'] = product.id;
                    }
                    return GestureDetector(
                      onTap: () => Get.toNamed('/product', arguments: productMap),
                      child: _ProductCard(
                        name: product.name,
                        price: product.price,
                        imageUrl: ApiConfig.productImageUrl(product.image),
                        emoji: product.emoji ?? '🛒',
                        shop: product.shopName ?? controller.shop.value?.name ?? '',
                        product: product,
                      ),
                    );
                  },
                  childCount: productsToShow.length,
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
      }),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64.sp,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          SizedBox(height: AppSpacing.lg),
          Text(
            controller.error.value ?? 'لا توجد منتجات',
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
    );
  }

  Widget _buildLoadingShimmer() {
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
}

/// هيدر صورة المحل في صفحة منتجات المحل.
class _ShopHeader extends StatelessWidget {
  const _ShopHeader({required this.shop});
  final Shop shop;

  @override
  Widget build(BuildContext context) {
    final imageUrl = ApiConfig.shopImageUrl(shop.image);
    if (imageUrl == null || imageUrl.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    final colorScheme = Theme.of(context).colorScheme;
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: SizedBox(
            height: 120.h,
            width: double.infinity,
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: colorScheme.surfaceContainerHighest,
                alignment: Alignment.center,
                child: Text('🛒', style: TextStyle(fontSize: 40.sp)),
              ),
              errorWidget: (_, __, ___) => Container(
                color: colorScheme.surfaceContainerHighest,
                alignment: Alignment.center,
                child: Text('🛒', style: TextStyle(fontSize: 40.sp)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// كارت منتج بنفس نمط الصفحة الرئيسية.
class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.name,
    required this.price,
    this.imageUrl,
    required this.emoji,
    required this.shop,
    required this.product,
  });

  final String name;
  final double price;
  final String? imageUrl;
  final String emoji;
  final String shop;
  /// المنتج الكامل لاستخدامه مع حالة السلة.
  final Product product;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cartController = Get.find<CartController>();
    final emojiBg = isDark ? colorScheme.primaryContainer.withValues(alpha: 0.7) : AppColors.primaryLight.withValues(alpha: 0.7);
    return Container(
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
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (_, __) => Container(
                        color: emojiBg,
                        alignment: Alignment.center,
                        child: Text(emoji, style: TextStyle(fontSize: 44.sp)),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: emojiBg,
                        alignment: Alignment.center,
                        child: Text(emoji, style: TextStyle(fontSize: 44.sp)),
                      ),
                    )
                  : Container(
                      color: emojiBg,
                      alignment: Alignment.center,
                      child: Text(emoji, style: TextStyle(fontSize: 44.sp)),
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
                          ? '$name · ${product.description}'
                          : name,
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
                      shop,
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
                          formatPrice(price),
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
    );
  }
}
