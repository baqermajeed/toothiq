import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../model/store_review_model.dart';
import '../../utils/app_colors.dart';
import '../my_text.dart';

class StoreReviewCardWidget extends StatelessWidget {
  final StoreReviewModel review;
  final VoidCallback? onMoreTap;

  const StoreReviewCardWidget({
    super.key,
    required this.review,
    this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                5,
                (index) => Padding(
                  padding: EdgeInsets.only(left: index == 0 ? 0 : 2.w),
                  child: Icon(
                    Icons.star_rounded,
                    size: 20.sp,
                    color: AppColors.ratingStar,
                  ),
                ),
              ),
            ),
            const Spacer(),
            MyText(
              review.timeAgo,
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
            SizedBox(width: 6.w),
            GestureDetector(
              onTap: onMoreTap,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Icon(
                  Icons.more_vert_rounded,
                  size: 20.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            _ReviewAvatar(avatarAsset: review.avatarAsset),
            SizedBox(width: 10.w),
            Expanded(
              child: MyText(
                review.userName,
                fontSize: 15.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.productTitle,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        MyText(
          review.text,
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
          textAlign: TextAlign.right,
          height: 1.55,
        ),
      ],
    );
  }
}

class _ReviewAvatar extends StatelessWidget {
  final String? avatarAsset;

  const _ReviewAvatar({this.avatarAsset});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40.w,
      height: 40.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.cardPlaceholder,
        image: avatarAsset != null
            ? DecorationImage(
                image: AssetImage(avatarAsset!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: avatarAsset == null
          ? Icon(
              Icons.person_rounded,
              size: 22.sp,
              color: AppColors.textLight,
            )
          : null,
    );
  }
}
