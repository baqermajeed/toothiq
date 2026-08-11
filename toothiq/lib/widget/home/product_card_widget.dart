import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controller/cart_controller.dart';
import '../../controller/home_controller.dart';
import '../../model/product_model.dart';
import '../../utils/app_colors.dart';
import '../../widget/app_image.dart';
import '../../widget/cart/cart_icon.dart';
import '../../view/product/product_details_page.dart';

/// كارد المنتج — مطابق لتصميم Frame_427321508
class ProductCardWidget extends StatelessWidget {
  final ProductModel product;
  final double? maxHeight;

  const ProductCardWidget({
    super.key,
    required this.product,
    this.maxHeight,
  });

  static const double _cardRadius = 24;

  @override
  Widget build(BuildContext context) {
    final home = Get.find<HomeController>();

    final card = Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(_cardRadius.r),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => ProductDetailsPage.open(product),
        borderRadius: BorderRadius.circular(_cardRadius.r),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_cardRadius.r),
            border: Border.all(color: AppColors.cardBorder, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
          Flexible(
            child: _ProductImageSection(
              imageAsset: product.imageAsset,
              isFavorite: product.isFavorite,
              onFavoriteTap: () => home.toggleFavorite(product.id),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.name,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Expo Arabic',
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.productTitle,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  product.storeName,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Expo Arabic',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.productStore,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  product.description,
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Expo Arabic',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.productDescription,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 6.h),
          Padding(
            padding: EdgeInsets.fromLTRB(10.w, 0, 10.w, 8.h),
            child: _ProductPriceBar(
              price: product.formattedPrice,
              onAddToCart: () {
                final cart = Get.isRegistered<CartController>()
                    ? Get.find<CartController>()
                    : Get.put(CartController(), permanent: true);
                cart.addProduct(product);
              },
            ),
          ),
            ],
          ),
        ),
      ),
    );

    if (maxHeight != null) {
      return SizedBox(height: maxHeight, child: card);
    }

    return card;
  }
}

class _ProductImageSection extends StatelessWidget {
  final String imageAsset;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;

  const _ProductImageSection({
    required this.imageAsset,
    required this.isFavorite,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(ProductCardWidget._cardRadius.r),
          ),
          child: AppImage(
            source: imageAsset,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorIcon: Icons.medical_services_outlined,
          ),
        ),
        Positioned(
          left: 10.w,
          bottom: 8.h,
          child: GestureDetector(
            onTap: onFavoriteTap,
            child: Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: AppColors.favoriteRed,
                size: 18.sp,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductPriceBar extends StatelessWidget {
  final String price;
  final VoidCallback onAddToCart;

  const _ProductPriceBar({
    required this.price,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.productPriceBar,
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Row(
        children: [
          Text(
            price,
            style: TextStyle(
              fontFamily: 'Expo Arabic',
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.productStore,
            ),
          ),
          const Spacer(),
          Material(
            color: AppColors.productStore,
            borderRadius: BorderRadius.circular(10.r),
            child: InkWell(
              onTap: onAddToCart,
              borderRadius: BorderRadius.circular(10.r),
              child: SizedBox(
                width: 34.w,
                height: 34.w,
                child: Center(
                  child: CartIcon(size: 19.sp, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
