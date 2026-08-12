import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../bindings/product_details_binding.dart';
import '../../controller/product_details_controller.dart';
import '../../model/product_model.dart';
import '../../utils/app_colors.dart';
import '../../widget/app_back_button.dart';
import '../../widget/app_image.dart';
import '../../widget/common/async_state_widgets.dart';
import '../../widget/my_text.dart';

class ProductDetailsPage extends StatelessWidget {
  const ProductDetailsPage({super.key});

  static void open(ProductModel product) {
    Get.to(
      () => const ProductDetailsPage(),
      binding: ProductDetailsBinding(product: product),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ProductDetailsController>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _ProductDetailsBottomBar.barGreen,
        appBar: _ProductDetailsAppBar(controller: ctrl),
        body: Obx(() {
          final product = ctrl.product;

          if (ctrl.isLoading.value && product.name.isEmpty) {
            return const ColoredBox(
              color: AppColors.background,
              child: AppLoadingState(),
            );
          }

          if (ctrl.loadError.value != null && product.name.isEmpty) {
            return ColoredBox(
              color: AppColors.background,
              child: AppErrorState(
                message: ctrl.loadError.value!,
                onRetry: () => ctrl.loadProductDetail(),
              ),
            );
          }

          if (product.name.isEmpty) {
            return const ColoredBox(
              color: AppColors.background,
              child: AppEmptyState(title: 'المنتج غير متوفر'),
            );
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: AppColors.background,
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: ctrl.refresh,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: EdgeInsets.only(bottom: 130.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (ctrl.loadError.value != null) ...[
                          AppErrorState(
                            message: ctrl.loadError.value!,
                            onRetry: () => ctrl.loadProductDetail(),
                            compact: true,
                          ),
                          SizedBox(height: 8.h),
                        ],
                        _ProductGallerySection(controller: ctrl),
                        SizedBox(height: 16.h),
                        _StoreLinkBar(
                          storeName: product.storeName,
                          onTap: ctrl.openStorePage,
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(height: 16.h),
                              MyText(
                                product.name,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.productStoreName,
                                textAlign: TextAlign.right,
                                height: 1.0,
                              ),
                              SizedBox(height: 14.h),
                              _PriceQuantityRow(controller: ctrl),
                              SizedBox(height: 20.h),
                              MyText(
                                'وصف المنتج',
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.productStoreName,
                                textAlign: TextAlign.right,
                                height: 1.5,
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                product.detailsDescription.isEmpty
                                    ? 'لا يوجد وصف لهذا المنتج.'
                                    : product.detailsDescription,
                                textAlign: TextAlign.justify,
                                style: TextStyle(
                                  fontFamily: 'Expo Arabic',
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                  height: 1.6,
                                ),
                              ),
                              if (product.expirationDate.isNotEmpty) ...[
                                SizedBox(height: 16.h),
                                MyText(
                                  'تاريخ الأنتهاء : ${product.expirationDate}',
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.productTitle,
                                  textAlign: TextAlign.right,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _ProductDetailsBottomBar(controller: ctrl),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _ProductDetailsAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final ProductDetailsController controller;

  const _ProductDetailsAppBar({required this.controller});

  @override
  Size get preferredSize => Size.fromHeight(56.h);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      leading: Obx(
        () => _FavoriteIconButton(
          isFavorite: controller.isFavorite.value,
          onTap: controller.toggleFavorite,
        ),
      ),
      title: MyText(
        'صفحة المنتج',
        fontSize: 18.sp,
        fontWeight: FontWeight.w800,
        color: AppColors.productTitle,
      ),
      actions: [
        const AppBackButton(),
        SizedBox(width: 8.w),
      ],
    );
  }
}

class _FavoriteIconButton extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onTap;

  const _FavoriteIconButton({
    required this.isFavorite,
    required this.onTap,
  });

  static const Color _fill = Color(0xFF16929E);
  static const Color _shadow = Color(0xFF659AB9);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(start: 12.w),
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _fill,
            borderRadius: BorderRadius.circular(10.r),
            boxShadow: [
              BoxShadow(
                color: _shadow.withValues(alpha: 0.38),
                blurRadius: 3.76,
                offset: Offset.zero,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10.r),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10.r),
              child: SizedBox(
                width: 34.w,
                height: 30.h,
                child: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductGallerySection extends StatelessWidget {
  static const double _galleryHeight = 280;
  static const int _maxThumbs = 4;

  final ProductDetailsController controller;

  const _ProductGallerySection({required this.controller});

  void _showProductImageDialog(String imageSource) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 48.h),
        child: Stack(
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: AppImage(
                    source: imageSource,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              child: Material(
                color: Colors.black.withValues(alpha: 0.45),
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: Get.back,
                  customBorder: const CircleBorder(),
                  child: SizedBox(
                    width: 40.w,
                    height: 40.w,
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 22.sp,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      barrierColor: Colors.black.withValues(alpha: 0.85),
    );
  }

  @override
  Widget build(BuildContext context) {
    final galleryHeight = _galleryHeight.h;
    final thumbGap = 6.h;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: SizedBox(
        height: galleryHeight,
        child: Obx(() {
          if (controller.showGalleryLoading) {
            return Container(
              width: double.infinity,
              height: galleryHeight,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primary,
                ),
              ),
            );
          }

          final images = controller.product.images;
          if (images.isEmpty) {
            return const SizedBox.shrink();
          }

          final selectedIndex =
              controller.selectedImageIndex.value.clamp(0, images.length - 1);
          final thumbCount = images.length.clamp(0, _maxThumbs);
          // مقاس ثابت كما في حالة 4 صور — بدون تمديد عند 2 أو 3.
          final thumbSize =
              (galleryHeight - (thumbGap * (_maxThumbs - 1))) / _maxThumbs;

          Widget mainImage() {
            return Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16.r),
                  child: AppImage(
                    source: images[selectedIndex],
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  right: 10.w,
                  bottom: 10.h,
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: () => _showProductImageDialog(
                        images[selectedIndex],
                      ),
                      customBorder: const CircleBorder(),
                      child: SizedBox(
                        width: 36.w,
                        height: 36.w,
                        child: Icon(
                          Icons.open_in_full_rounded,
                          size: 18.sp,
                          color: AppColors.productStore,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          // صورة واحدة: العرض الكامل بدون عمود مصغّرات.
          if (thumbCount <= 1) {
            return mainImage();
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: mainImage()),
              SizedBox(width: 10.w),
              SizedBox(
                width: thumbSize,
                height: galleryHeight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var index = 0; index < thumbCount; index++) ...[
                      if (index > 0) SizedBox(height: thumbGap),
                      SizedBox(
                        width: thumbSize,
                        height: thumbSize,
                        child: _GalleryThumb(
                          source: images[index],
                          isSelected: selectedIndex == index,
                          onTap: () => controller.selectImage(index),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _GalleryThumb extends StatelessWidget {
  final String source;
  final bool isSelected;
  final VoidCallback onTap;

  const _GalleryThumb({
    required this.source,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? AppColors.productStore : AppColors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11.r),
          child: AppImage(
            source: source,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

class _StoreLinkBar extends StatelessWidget {
  final String storeName;
  final VoidCallback onTap;

  const _StoreLinkBar({required this.storeName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Material(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(14.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            child: Row(
              children: [
                MyText(
                  storeName,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.productStoreName,
                  textAlign: TextAlign.right,
                  height: 1.42,
                ),
                const Spacer(),
                Transform.rotate(
                  angle: 3.141592653589793,
                  child: Icon(
                    Icons.chevron_left,
                    color: AppColors.productStore,
                    size: 22.sp,
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

class _PriceQuantityRow extends StatelessWidget {
  final ProductDetailsController controller;

  const _PriceQuantityRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MyText(
          controller.product.formattedPrice,
          fontSize: 18.sp,
          fontWeight: FontWeight.w800,
          color: AppColors.productAccent,
          height: 1.0,
        ),
        const Spacer(),
        Obx(
          () => _QuantitySelector(
            quantity: controller.quantity.value,
            onIncrement: controller.incrementQuantity,
            onDecrement: controller.decrementQuantity,
          ),
        ),
      ],
    );
  }
}

class _QuantitySelector extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _QuantitySelector({
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _QtyButton(icon: Icons.remove, onTap: onDecrement),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: MyText(
            '$quantity',
            fontSize: 16.sp,
            fontWeight: FontWeight.w800,
            color: Colors.black,
            height: 1.0,
          ),
        ),
        _QtyButton(icon: Icons.add, onTap: onIncrement),
      ],
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.productAccent,
      borderRadius: BorderRadius.circular(11.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11.r),
        child: SizedBox(
          width: 28.w,
          height: 25.h,
          child: Icon(icon, color: Colors.white, size: 16.sp),
        ),
      ),
    );
  }
}

class _ProductDetailsBottomBar extends StatelessWidget {
  final ProductDetailsController controller;

  const _ProductDetailsBottomBar({required this.controller});

  static const Color barGreen = Color(0xFF0D3136);
  /// `#FFFEFB` — يجب كتابة الـ alpha صراحةً (`FF`) وإلا اللون يكون شفافاً.
  static const Color _cream = Color(0xFFFFFEFB);

  @override
  Widget build(BuildContext context) {
    final topRadius = Radius.circular(24.r);

    return Material(
      color: barGreen,
      borderRadius: BorderRadius.only(
        topLeft: topRadius,
        topRight: topRadius,
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
          child: SizedBox(
            height: 51.h,
            width: double.infinity,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final buyNowWidth = constraints.maxWidth * 0.58;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // كونتينر أضافة للسلة
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: _cream.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: controller.addToCart,
                            borderRadius: BorderRadius.circular(20.r),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: SizedBox(
                                width: constraints.maxWidth * 0.42,
                                child: MyText(
                                  'أضافة للسلة',
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // كونتينر شراء مباشر الأبيض
                    Positioned(
                      top: 0,
                      right: 0,
                      bottom: 0,
                      width: buyNowWidth,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: _cream,
                          borderRadius: BorderRadius.circular(20.r),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3A3F41)
                                  .withValues(alpha: 0.16),
                              offset: const Offset(0, 21.94),
                              blurRadius: 87.77,
                              spreadRadius: -3.99,
                            ),
                            BoxShadow(
                              color: const Color(0xFF3A3F41)
                                  .withValues(alpha: 0.16),
                              offset: const Offset(0, 9.97),
                              blurRadius: 27.93,
                              spreadRadius: -5.98,
                            ),
                          ],
                        ),
                        child: Material(
                          color: _cream,
                          borderRadius: BorderRadius.circular(20.r),
                          child: InkWell(
                            onTap: controller.buyNow,
                            borderRadius: BorderRadius.circular(20.r),
                            child: Center(
                              child: MyText(
                                'شراء مباشر',
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                color: barGreen,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
