import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../utils/app_colors.dart';
import '../app_back_button.dart';
import '../my_text.dart';

class StoreDetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  final double rating;

  const StoreDetailAppBar({super.key, required this.rating});

  @override
  Size get preferredSize => Size.fromHeight(56.h);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      leadingWidth: 72.w,
      title: MyText(
        'صفحة المتجر',
        fontSize: 18.sp,
        fontWeight: FontWeight.w800,
        color: AppColors.productTitle,
      ),
      leading: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Padding(
          padding: EdgeInsetsDirectional.only(end: 8.w),
          child: _StoreRatingBadge(rating: rating),
        ),
      ),
      actions: [
        const AppBackButton(),
        SizedBox(width: 8.w),
      ],
    );
  }
}

class _StoreRatingBadge extends StatelessWidget {
  final double rating;

  const _StoreRatingBadge({required this.rating});

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
