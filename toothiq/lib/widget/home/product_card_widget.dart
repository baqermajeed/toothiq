import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controller/cart_controller.dart';
import '../../model/product_model.dart';
import '../../service_layer/services/favorites_service.dart';
import '../../utils/app_colors.dart';
import '../../widget/app_image.dart';
import '../../widget/cart/cart_icon.dart';
import '../../widget/home/offer_glass_badge.dart';
import '../../view/product/product_details_page.dart';

/// كارد المنتج — مطابق لتصميم Frame_427321508
class ProductCardWidget extends StatelessWidget {
  final ProductModel product;

  const ProductCardWidget({
    super.key,
    required this.product,
  });

  static const double _cardRadius = 24;
  static const double _fixedCardHeight = 252;
  static const double _imageHeight = 127.34;
  static const double _gridHPad = 16;
  static const double _gridGap = 12;
  static const int _crossAxisCount = 2;

  /// ارتفاع الكارد بعد ScreenUtil — ليتطابق مع `mainAxisExtent` في الشبكة
  static double get cardHeight => _fixedCardHeight.h;

  /// عرض كارد واحد في شبكة عمودين (هوامش 16 + تباعد 12).
  static double cardWidthFor(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    return (screenW - _gridHPad.w * 2 - _gridGap.w) / _crossAxisCount;
  }

  /// شبكة الصفحة الرئيسية — مصدر واحد لكل صفحات المنتجات.
  static SliverGridDelegate get gridDelegate {
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: _crossAxisCount,
      crossAxisSpacing: _gridGap.w,
      mainAxisSpacing: 10.h,
      mainAxisExtent: cardHeight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final favorites = Get.find<FavoritesService>();

    final card = Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(_cardRadius.r),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_cardRadius.r),
          border: Border.all(color: AppColors.cardBorder, width: 1),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: InkWell(
                onTap: () => ProductDetailsPage.open(product),
                borderRadius: BorderRadius.circular(_cardRadius.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(6.w),
                      child: SizedBox(
                        height: _imageHeight.h,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18.r),
                          child: AppImage(
                            source: product.imageAsset,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorIcon: Icons.medical_services_outlined,
                            showLoadingIndicator: false,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Padding(
                      padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 0),
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
                          SizedBox(height: 3.h),
                          Text(
                            product.description,
                            textAlign: TextAlign.right,
                            maxLines: 1,
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
                    SizedBox(height: 3.h),
                    const Spacer(),
                    Padding(
                      padding: EdgeInsets.fromLTRB(10.w, 0, 10.w, 6.w),
                      child: _ProductPriceBar(
                        price: product.formattedPrice,
                        originalPrice: product.isOnOffer
                            ? product.formattedOriginalPrice
                            : null,
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
            Positioned(
              right: 12.w,
              top: 10.w,
              child: product.isOnOffer
                  ? OfferGlassBadge(label: product.offerBadgeLabel)
                  : const SizedBox.shrink(),
            ),
            Positioned(
              left: 16.w,
              top: 6.w + _imageHeight.h - 32.w - 8.h,
              child: Obx(() {
                // الاشتراك في قائمة المفضلة ليُحدَّث شكل القلب فوراً
                favorites.favoriteProducts.length;
                final isFavorite = favorites.isFavorite(product.id);
                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.r),
                  elevation: 2,
                  shadowColor: Colors.black26,
                  child: InkWell(
                    onTap: () => favorites.toggle(product),
                    borderRadius: BorderRadius.circular(10.r),
                    child: SizedBox(
                      width: 32.w,
                      height: 32.w,
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: AppColors.favoriteRed,
                        size: 18.sp,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );

    return SizedBox(
      height: cardHeight,
      child: card,
    );
  }
}

class _ProductPriceBar extends StatelessWidget {
  final String price;
  final String? originalPrice;
  final VoidCallback onAddToCart;

  const _ProductPriceBar({
    required this.price,
    required this.onAddToCart,
    this.originalPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40.h,
      padding: EdgeInsets.fromLTRB(0, 0, 10.w, 0),
      decoration: BoxDecoration(
        color: AppColors.productPriceBar,
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (originalPrice != null)
                    Text(
                      originalPrice!,
                      style: TextStyle(
                        fontFamily: 'Expo Arabic',
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.productDescription,
                        decoration: TextDecoration.lineThrough,
                        height: 1,
                      ),
                    ),
                  Text(
                    price,
                    style: TextStyle(
                      fontFamily: 'Expo Arabic',
                      fontSize: originalPrice != null ? 12.sp : 13.sp,
                      fontWeight: FontWeight.w900,
                      color: AppColors.productStore,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Material(
            color: AppColors.productStore,
            borderRadius: BorderRadius.circular(10.r),
            child: InkWell(
              onTap: onAddToCart,
              borderRadius: BorderRadius.circular(10.r),
              child: SizedBox(
                width: 40.w,
                height: double.infinity,
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
