import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../bindings/product_details_binding.dart';
import '../../controller/product_details_controller.dart';
import '../../model/product_model.dart';
import '../../utils/app_colors.dart';
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
        backgroundColor: AppColors.background,
        appBar: _ProductDetailsAppBar(controller: ctrl),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ProductGallerySection(controller: ctrl),
                    SizedBox(height: 16.h),
                    _StoreLinkBar(storeName: ctrl.product.storeName),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: 16.h),
                          MyText(
                            ctrl.product.name,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.productTitle,
                            textAlign: TextAlign.right,
                          ),
                          SizedBox(height: 14.h),
                          _PriceQuantityRow(controller: ctrl),
                          SizedBox(height: 20.h),
                          MyText(
                            'وصف المنتج',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.productStore,
                            textAlign: TextAlign.right,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            ctrl.product.detailsDescription,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontFamily: 'Expo Arabic',
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                              color: AppColors.productDescription,
                              height: 1.6,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          MyText(
                            'تاريخ الأنتهاء : ${ctrl.product.expirationDate}',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.productTitle,
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _ProductDetailsBottomBar(controller: ctrl),
          ],
        ),
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
      leading: _CircleIconButton(
        icon: Icons.chevron_right,
        onTap: () => Get.back(),
      ),
      title: MyText(
        'صفحة المنتج',
        fontSize: 18.sp,
        fontWeight: FontWeight.w800,
        color: AppColors.productTitle,
      ),
      actions: [
        Obx(
          () => _CircleIconButton(
            icon: controller.isFavorite.value
                ? Icons.favorite
                : Icons.favorite_border,
            iconColor: controller.isFavorite.value
                ? AppColors.favoriteRed
                : Colors.white,
            onTap: controller.toggleFavorite,
          ),
        ),
        SizedBox(width: 8.w),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(8.w),
      child: Material(
        color: AppColors.productStore,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 40.w,
            height: 40.w,
            child: Icon(
              icon,
              color: iconColor ?? Colors.white,
              size: 24.sp,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductGallerySection extends StatelessWidget {
  static const double _galleryHeight = 280;

  final ProductDetailsController controller;

  const _ProductGallerySection({required this.controller});

  @override
  Widget build(BuildContext context) {
    final images = controller.product.images;
    final galleryHeight = _galleryHeight.h;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: SizedBox(
        height: galleryHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Obx(
                () => Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16.r),
                      child: Image.asset(
                        images[controller.selectedImageIndex.value],
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                          color: AppColors.cardPlaceholder,
                          child: Icon(
                            Icons.image_outlined,
                            size: 48.sp,
                            color: AppColors.textLight,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 10.w,
                      bottom: 10.h,
                      child: Container(
                        width: 36.w,
                        height: 36.w,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.open_in_full_rounded,
                          size: 18.sp,
                          color: AppColors.productStore,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Obx(
              () {
                final thumbCount = images.length.clamp(0, 4);
                return SizedBox(
                  width: 56.w,
                  height: galleryHeight,
                  child: Column(
                    children: List.generate(thumbCount, (index) {
                      final isSelected =
                          controller.selectedImageIndex.value == index;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            bottom: index < thumbCount - 1 ? 6.h : 0,
                          ),
                          child: GestureDetector(
                            onTap: () => controller.selectImage(index),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.productStore
                                      : AppColors.cardBorder,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(11.r),
                                child: Image.asset(
                                  images[index],
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) =>
                                          Container(
                                    color: AppColors.cardPlaceholder,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreLinkBar extends StatelessWidget {
  final String storeName;

  const _StoreLinkBar({required this.storeName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Material(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(14.r),
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(14.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            child: Row(
              children: [
                MyText(
                  storeName,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.productStore,
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_left,
                  color: AppColors.productStore,
                  size: 22.sp,
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
          color: AppColors.productStore,
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.productStore.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QtyButton(icon: Icons.remove, onTap: onDecrement),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: MyText(
              '$quantity',
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.productStore,
            ),
          ),
          _QtyButton(icon: Icons.add, onTap: onIncrement),
        ],
      ),
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
      color: AppColors.productStore,
      borderRadius: BorderRadius.circular(10.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: SizedBox(
          width: 36.w,
          height: 36.w,
          child: Icon(icon, color: Colors.white, size: 20.sp),
        ),
      ),
    );
  }
}

class _ProductDetailsBottomBar extends StatelessWidget {
  final ProductDetailsController controller;

  const _ProductDetailsBottomBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 20.h),
      decoration: BoxDecoration(
        color: AppColors.bottomNavBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 50.h,
                child: ElevatedButton(
                  onPressed: controller.buyNow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: MyText(
                    'شراء مباشر',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.productTitle,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: SizedBox(
                height: 50.h,
                child: OutlinedButton(
                  onPressed: controller.addToCart,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: MyText(
                    'أضافة للسلة',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
