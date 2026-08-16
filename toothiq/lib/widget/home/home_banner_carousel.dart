import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../controller/home_controller.dart';
import '../../model/banner_model.dart';
import '../../model/product_model.dart';
import '../../model/store_model.dart';
import '../../utils/app_colors.dart';
import '../../view/product/product_details_page.dart';
import '../../view/stores/store_detail_page.dart';
import '../../widget/app_image.dart';

class HomeBannerCarousel extends StatelessWidget {
  const HomeBannerCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    final home = Get.find<HomeController>();

    return Obx(() {
      final banners = home.banners;
      if (banners.isEmpty) return const SizedBox.shrink();

      return Column(
        children: [
          SizedBox(
            height: 160.h,
            child: PageView.builder(
              controller: home.bannerPageController,
              itemCount: banners.length,
              onPageChanged: home.onBannerChanged,
              itemBuilder: (context, index) {
                final banner = banners[index];
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: GestureDetector(
                    onTap: () => _openBanner(banner),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16.r),
                      child: AppImage(
                        source: banner.imageUrl,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorIcon: Icons.image_outlined,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 6.h),
          SmoothPageIndicator(
            controller: home.bannerPageController,
            count: banners.length,
            effect: ExpandingDotsEffect(
              dotHeight: 7.h,
              dotWidth: 7.w,
              spacing: 6.w,
              expansionFactor: 2.8,
              activeDotColor: AppColors.indicatorActive,
              dotColor: AppColors.indicatorInactive,
            ),
          ),
        ],
      );
    });
  }

  void _openBanner(BannerModel banner) {
    switch (banner.actionType) {
      case BannerActionType.shop:
        final shop = banner.shop ??
            StoreModel(
              id: banner.shopId ?? '',
              name: '',
              description: '',
            );
        if (shop.id.isEmpty) return;
        StoreDetailPage.open(shop);
        return;
      case BannerActionType.product:
        final product = banner.product ??
            ProductModel(
              id: banner.productId ?? '',
              name: '',
              storeName: '',
              description: '',
              price: 0,
              imageAsset: 'assets/images/products/product_1.png',
              shopId: banner.shopId,
            );
        if (product.id.isEmpty) return;
        ProductDetailsPage.open(product);
        return;
      case BannerActionType.externalUrl:
      case BannerActionType.none:
        return;
    }
  }
}
