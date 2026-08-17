import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../utils/app_colors.dart';

class StoreDetailAppBar {
  static double toolbarHeight() => 56.h;
}

class StoreRatingBadge extends StatelessWidget {
  final double rating;

  const StoreRatingBadge({super.key, required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.ratingBackground,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontFamily: 'Expo Arabic',
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.productTitle,
              height: 1,
            ),
          ),
          SizedBox(width: 3.w),
          Icon(
            Icons.star_rounded,
            color: AppColors.ratingStar,
            size: 16.sp,
          ),
        ],
      ),
    );
  }
}
