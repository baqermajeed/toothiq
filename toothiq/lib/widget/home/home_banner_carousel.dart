import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../controller/home_controller.dart';
import '../../utils/app_colors.dart';
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
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.r),
                    child: AppImage(
                      source: banners[index].imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorIcon: Icons.image_outlined,
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
}
