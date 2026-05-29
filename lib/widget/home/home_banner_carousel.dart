import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../controller/home_controller.dart';
import '../../utils/app_colors.dart';

class HomeBannerCarousel extends StatelessWidget {
  const HomeBannerCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    final home = Get.find<HomeController>();

    return Column(
      children: [
        SizedBox(
          height: 160.h,
          child: PageView.builder(
            controller: home.bannerPageController,
            itemCount: HomeController.bannerAssets.length,
            onPageChanged: home.onBannerChanged,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.r),
                  child: Image.asset(
                    HomeController.bannerAssets[index],
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.cardPlaceholder,
                      child: Icon(
                        Icons.image_outlined,
                        size: 48.sp,
                        color: AppColors.textLight,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 12.h),
        SmoothPageIndicator(
          controller: home.bannerPageController,
          count: HomeController.bannerAssets.length,
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
  }
}
