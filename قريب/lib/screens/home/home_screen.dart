import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/home_products_controller.dart';
import '../../controllers/home_shops_controller.dart';
import '../../controllers/home_voice_order_controller.dart';
import '../../core/config/api_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../utils/price_formatter.dart';
import '../../models/product.dart';
import '../../widgets/cart/cart_bottom_sheet.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_spacing.dart';
import '../../widgets/common/load_more_footer.dart';
import '../../widgets/common/loading/shimmer_box.dart';
import '../../widgets/dialogs/guest_register_dialog.dart';

/// محتوى الصفحة الرئيسية فقط — يُعرض داخل الـ shell مع الهيدر والشريط السفلي.
class HomeContent extends GetView<AuthController> {
  const HomeContent({super.key});

  Future<void> _onRefresh() async {
    final shopsController = Get.find<HomeShopsController>();
    final productsController = Get.find<HomeProductsController>();
    await shopsController.loadShops();
    await productsController.loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    final productsController = Get.find<HomeProductsController>();
    return Obx(() {
      final userName = controller.user.value?.name ?? 'ضيف';
      return CustomMaterialIndicator(
        onRefresh: _onRefresh,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        indicatorBuilder: (context, controller) {
          return Padding(
            padding: EdgeInsets.all(6.w),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Opacity(
                    opacity: controller.state.isLoading
                        ? 1.0
                        : math.min(controller.value, 1.0),
                    child: Image.asset(
                      'assets/icon_app.png',
                      height: 28.h,
                      width: 28.w,
                      fit: BoxFit.contain,
                    ),
                  ),
                  if (controller.state.isLoading) ...[
                    SizedBox(height: 4.h),
                    SizedBox(
                      width: 18.w,
                      height: 18.h,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
        child: CustomScrollView(
          controller: productsController.scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                child: _WelcomeCard(userName: userName, authController: controller),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
            SliverToBoxAdapter(
              child: Obx(() {
                final shopsCtrl = Get.find<HomeShopsController>();
                final isVoiceOnly = shopsCtrl.isVoiceOrderOnlyZone.value;
                if (isVoiceOnly) {
                  return _VoiceOrderOnlyHeroSection();
                }
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: _VoiceOrderButton(),
                );
              }),
            ),
            SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
            SliverToBoxAdapter(
              child: Obx(() {
                final shopsCtrl = Get.find<HomeShopsController>();
                if (shopsCtrl.isVoiceOrderOnlyZone.value) {
                  return const SizedBox.shrink();
                }
                return _ShopsSection();
              }),
            ),
            SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: _SectionTitle(title: 'منتجات متنوعة'),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
          _ProductsSection(productsController: productsController),
          SliverToBoxAdapter(child: SizedBox(height: 100.h)),
          ],
        ),
      );
    });
  }
}


/// مركز افتراضي للخريطة (بغداد) عند عدم وجود موقع محفوظ.
const double _defaultMapLat = 33.3152;
const double _defaultMapLng = 44.3661;

/// بطاقة ترحيب بتصميم عصري.
class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.userName, required this.authController});

  final String userName;
  final AuthController authController;

  double _initialLat() {
    final user = authController.user.value;
    if (user?.location is Map<String, dynamic>) {
      final loc = user!.location as Map<String, dynamic>;
      final coords = loc['coordinates'];
      if (coords is List && coords.length >= 2) {
        final lat = (coords[1] is num) ? (coords[1] as num).toDouble() : null;
        if (lat != null) return lat;
      }
    }
    return _defaultMapLat;
  }

  double _initialLng() {
    final user = authController.user.value;
    if (user?.location is Map<String, dynamic>) {
      final loc = user!.location as Map<String, dynamic>;
      final coords = loc['coordinates'];
      if (coords is List && coords.length >= 2) {
        final lng = (coords[0] is num) ? (coords[0] as num).toDouble() : null;
        if (lng != null) return lng;
      }
    }
    return _defaultMapLng;
  }

  Future<void> _onLocationIconTap() async {
    final result = await Get.toNamed(
      '/full-screen-map',
      arguments: {
        'lat': _initialLat(),
        'lng': _initialLng(),
        'mode': 'pick',
      },
    );
    if (result is LatLng) {
      await authController.updateDeliveryLocation(result.latitude, result.longitude);
    }
  }

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'مرحباً، $userName 👋',
                  style: TextStyle(
                    fontFamily: kFontFamilyCairo,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'ما الذي تبحث عنه اليوم؟',
                  style: TextStyle(
                    fontFamily: kFontFamilyCairo,
                    fontSize: 14.sp,
                    color: subTextColor,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _onLocationIconTap,
              borderRadius: BorderRadius.circular(12.r),
              child: Padding(
                padding: EdgeInsets.all(8.r),
                child: Icon(
                  Icons.location_on_rounded,
                  size: 28.sp,
                  color: textColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// قسم هيرو للطلب الصوتي فقط — يظهر عندما تكون المنطقة تدعم الطلب الصوتي فقط.
/// تصميم احترافي مع زر تسجيل بارز في المنتصف.
class _VoiceOrderOnlyHeroSection extends StatelessWidget {
  const _VoiceOrderOnlyHeroSection();

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<HomeVoiceOrderController>()) {
      Get.put(HomeVoiceOrderController());
    }
    final ctrl = Get.find<HomeVoiceOrderController>();
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardGradient = isDark
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surfaceContainerHigh,
              AppColors.primaryDark.withValues(alpha: 0.15),
            ],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryLight.withValues(alpha: 0.35),
              AppColors.primaryBeige.withValues(alpha: 0.25),
            ],
          );
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 28.h),
        decoration: BoxDecoration(
          gradient: cardGradient,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: AppColors.primaryDark.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'منطقتك حاليا تدعم الطلب الصوتي فقط',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: kFontFamilyCairo,
                fontSize: 20.sp,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'سجّل بصمة صوتية لطلبك وراح نوصلة الك',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: kFontFamilyCairo,
                fontSize: 14.sp,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                height: 1.4,
              ),
            ),

            SizedBox(height: 28.h),
            
            Obx(() {
              final hasRecording = ctrl.audioPath.value != null && ctrl.audioPath.value!.isNotEmpty;
              final isRecording = ctrl.isRecording.value;
              if (hasRecording && !isRecording) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: 48.sp,
                        color: colorScheme.primary,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    
                    AppButton(
                      label: 'إرسال الطلب',
                      // minHeight: 52.h,
                      loading: ctrl.isSubmitting.value || ctrl.isUploading.value,
                      onPressed: () {
                        final auth = Get.find<AuthController>();
                        if (!auth.isAuthenticated) {
                          showGuestRegisterDialog().then((result) {
                            if (result != null) ctrl.submit(guestCredentials: result);
                          });
                        } else {
                          ctrl.submit();
                        }
                      },
                    ),
                    SizedBox(height: 12.h),
                    TextButton.icon(
                      onPressed: ctrl.removeAudio,
                      icon: Icon(Icons.delete_outline_rounded, size: 20.sp, color: colorScheme.error),
                      label: Text(
                        'حذف التسجيل وتسجيل جديد',
                        style: TextStyle(
                          fontFamily: kFontFamilyCairo,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                );
              }
              return GestureDetector(
                onTapDown: (_) => ctrl.startRecording(),
                onTapUp: (_) => ctrl.stopRecording(),
                onTapCancel: () => ctrl.stopRecording(),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 160.w,
                  height: 160.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isRecording
                        ? colorScheme.errorContainer.withValues(alpha: 0.6)
                        : AppColors.primaryDark.withValues(alpha: 0.12),
                    border: Border.all(
                      color: isRecording ? colorScheme.error : AppColors.primaryDark,
                      width: isRecording ? 3 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isRecording ? colorScheme.error : AppColors.primaryDark).withValues(alpha: 0.25),
                        blurRadius: isRecording ? 16 : 12,
                        spreadRadius: isRecording ? 2 : 0,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                        size: 56.sp,
                        color: isRecording ? colorScheme.error : AppColors.primaryDark,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        isRecording ? 'ارفع لإيقاف' : 'اضغط للتسجيل',
                        style: TextStyle(
                          fontFamily: kFontFamilyCairo,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: isRecording ? colorScheme.onErrorContainer : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            if (ctrl.errorMessage.value != null) ...[
              SizedBox(height: 12.h),
              Text(
                ctrl.errorMessage.value!,
                style: TextStyle(
                  fontFamily: kFontFamilyCairo,
                  fontSize: 13.sp,
                  color: colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// زر طلب الشراء بالمقطع الصوتي.
class _VoiceOrderButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Get.toNamed('/voice-order'),
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: isDark ? colorScheme.surfaceContainerHigh : AppColors.primaryLight.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: AppColors.primaryDark.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.mic_rounded,
                size: 28.sp,
                color: AppColors.primaryDark,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'طلب شراء بالمقطع الصوتي',
                      style: TextStyle(
                        fontFamily: kFontFamilyCairo,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'سجّل المنتجات التي تريدها من المحل',
                      style: TextStyle(
                        fontFamily: kFontFamilyCairo,
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18.sp,
                color: AppColors.primaryDark,
              ),
            ],
          ),
        ),
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

/// قسم «محلات قريبة منك» — يجلب المحلات من الـ API ويعرضها مع إمكانية الضغط للانتقال إلى منتجات المحل.
class _ShopsSection extends StatelessWidget {
  const _ShopsSection();

  @override
  Widget build(BuildContext context) {
    final c = Get.find<HomeShopsController>();
    return Obx(() {
      final shops = c.shops;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _SectionTitle(title: 'محلات قريبة منك'),
                GestureDetector(
                  onTap: () => Get.toNamed('/all-shops'),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 4.w),
                    child: Text(
                      'عرض الكل',
                      style: TextStyle(
                        fontFamily: kFontFamilyCairo,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.verticalSm,
          if (c.error.value != null)
            Padding(
              padding: EdgeInsets.only(left: AppSpacing.lg, bottom: AppSpacing.sm),
              child: Text(
                c.error.value!,
                style: TextStyle(
                  fontFamily: kFontFamilyCairo,
                  fontSize: 12.sp,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          if (c.loading.value)
            SizedBox(
              height: 120.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.only(right: AppSpacing.lg),
                itemCount: 4,
                separatorBuilder: (_, __) => SizedBox(width: 14.w),
                itemBuilder: (_, __) => ShimmerBox(
                  width: 260.w,
                  height: 120.h,
                  borderRadius: BorderRadius.circular(20.r),
                ),
              ),
            )
          else if (shops.isEmpty) ...[
            Builder(
              builder: (_) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  c.maybeShowZoneNotSupportedDialog();
                });
                return const SizedBox.shrink();
              },
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Obx(() => _EmptyShopsState(
                isVoiceOrderOnlyZone: c.isVoiceOrderOnlyZone.value,
                onTap: () => c.showZoneNotSupportedDialog(),
              )),
            ),
          ]
          else
            SizedBox(
              height: 120.h,
              child: ListView.separated(
                    padding: EdgeInsets.only(right: AppSpacing.lg),
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: shops.length,
                    separatorBuilder: (_, __) => SizedBox(width: 14.w),
                    itemBuilder: (context, i) {
                      final shop = shops[i];
                      final desc = shop.description?.trim() ?? '';
                      return GestureDetector(
                        onTap: () => Get.toNamed(
                          '/shop-products',
                          arguments: shop,
                        ),
                        child: _ShopCard(
                          name: shop.name,
                          category: shop.category,
                          description: desc,
                          imageUrl: ApiConfig.shopImageUrl(shop.image),
                        ),
                      );
                    },
                  ),
          ),
        ],
      );
    });
  }
}

/// قسم «منتجات متنوعة» — شبكة منتجات مع infinite scroll.
class _ProductsSection extends StatelessWidget {
  const _ProductsSection({required this.productsController});
  final HomeProductsController productsController;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final c = productsController;
      if (c.loading.value) {
        return SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14.h,
              crossAxisSpacing: 14.w,
              childAspectRatio: 0.7,
            ),
            delegate: SliverChildBuilderDelegate(
              (_, __) => ShimmerBox(
                width: double.infinity,
                height: double.infinity,
                borderRadius: BorderRadius.circular(22.r),
              ),
              childCount: 6,
            ),
          ),
        );
      }
      if (c.error.value != null && c.products.isEmpty) {
        return SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
            child: Text(
              c.error.value!,
              style: TextStyle(
                fontFamily: kFontFamilyCairo,
                fontSize: 14.sp,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        );
      }
      if (c.products.isEmpty) {
        return SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Center(
              child: Text(
                'لا توجد منتجات حالياً',
                style: TextStyle(
                  fontFamily: kFontFamilyCairo,
                  fontSize: 15.sp,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        );
      }
      return SliverMainAxisGroup(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14.h,
                crossAxisSpacing: 14.w,
                mainAxisExtent: 250.h,
                childAspectRatio: 0.7,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final product = c.products[i];
                  final productMap = product.toMap();
                  if (!productMap.containsKey('_id') && product.id != null) productMap['_id'] = product.id;
                  return GestureDetector(
                    onTap: () => Get.toNamed('/product', arguments: productMap),
                    child: _HomeProductCard(
                      name: product.name,
                      price: product.price,
                      imageUrl: ApiConfig.productImageUrl(product.image),
                      emoji: product.emoji ?? '🛒',
                      shop: product.shopName ?? '',
                      product: product,
                    ),
                  );
                },
                childCount: c.products.length,
              ),
            ),
          ),
          if (c.hasNextPage.value || c.loadingMore.value)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: LoadMoreFooter(
                  isLoading: c.loadingMore.value,
                  hasMore: c.hasNextPage.value,
                  onLoadMore: c.loadMore,
                  compact: false,
                ),
              ),
            ),
        ],
      );
    });
  }
}

/// كارت منتج للصفحة الرئيسية.
class _HomeProductCard extends StatelessWidget {
  const _HomeProductCard({
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
    final emojiBg = isDark
        ? colorScheme.primaryContainer.withValues(alpha: 0.7)
        : AppColors.primaryLight.withValues(alpha: 0.7);
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
                padding: EdgeInsets.fromLTRB(12.w, 6.h, 12.w, 8.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.min,
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

/// حالة فارغة عند عدم وجود محلات ضمن منطقة المستخدم.
class _EmptyShopsState extends StatelessWidget {
  const _EmptyShopsState({
    this.isVoiceOrderOnlyZone = false,
    this.onTap,
  });

  final bool isVoiceOrderOnlyZone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final message = isVoiceOrderOnlyZone
        ? 'منطقتك تدعم فقط الطلبات الصوتية. ولاحقاً سيتم إضافة المحلات. إذا تحب نجيبلك طلب للبيت، سجّل اللي تريده بتسجيل صوتي.'
        : 'منطقتك غير مدعومة حاليا سيتم اضافة المنطقة قريبا';
    final content = Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.storefront_rounded,
              size: 56.sp,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: kFontFamilyCairo,
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }
    return content;
  }
}

/// كارت متجر أفقي عصري.
class _ShopCard extends StatelessWidget {
  const _ShopCard({
    required this.name,
    required this.category,
    required this.description,
    this.imageUrl,
  });

  final String name;
  final String category;
  /// وصف سطر واحد يعرض تحت اسم المحل.
  final String description;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconBg = isDark ? colorScheme.primaryContainer : AppColors.primaryLight;
    final iconBorder = isDark ? colorScheme.outline : AppColors.border;
    return Container(
      width: 260.w,
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
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16.r),
            child: SizedBox(
              width: 56.w,
              height: 56.h,
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl!,
                      fit: BoxFit.cover,
                      width: 56.w,
                      height: 56.h,
                      placeholder: (_, __) => Container(
                        color: iconBg,
                        alignment: Alignment.center,
                        child: Text('🛒', style: TextStyle(fontSize: 28.sp)),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: iconBg,
                        alignment: Alignment.center,
                        child: Text('🛒', style: TextStyle(fontSize: 28.sp)),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: iconBorder),
                      ),
                      alignment: Alignment.center,
                      child: Text('🛒', style: TextStyle(fontSize: 28.sp)),
                    ),
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              description.isNotEmpty ? '$name · $description' : name,
              style: TextStyle(
                fontFamily: kFontFamilyCairo,
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 14.sp, color: colorScheme.primary),
        ],
      ),
    );
  }
}
