import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../utils/app_colors.dart';

class StoreReviewInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const StoreReviewInputBar({
    super.key,
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.searchBorder.withValues(alpha: 0.6)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 52.h,
                padding: EdgeInsets.symmetric(horizontal: 18.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28.r),
                  border: Border.all(color: AppColors.searchBorder),
                ),
                alignment: Alignment.centerRight,
                child: TextField(
                  controller: controller,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: 'Expo Arabic',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.productTitle,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: 'لديك تجربة مع هذا المتجر ؟ شارك رأيك',
                    hintStyle: TextStyle(
                      fontFamily: 'Expo Arabic',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textLight,
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Material(
              color: AppColors.productStore,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onSend,
                child: SizedBox(
                  width: 52.w,
                  height: 52.w,
                  child: Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 22.sp,
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
