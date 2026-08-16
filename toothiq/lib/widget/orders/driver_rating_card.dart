import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../utils/app_colors.dart';
import '../my_text.dart';

class DriverRatingCard extends StatelessWidget {
  const DriverRatingCard({
    super.key,
    required this.driverName,
    required this.selectedRating,
    required this.commentController,
    required this.isSubmitting,
    required this.hasSubmitted,
    required this.onRatingChanged,
    required this.onSubmit,
  });

  final String driverName;
  final int selectedRating;
  final TextEditingController commentController;
  final bool isSubmitting;
  final bool hasSubmitted;
  final ValueChanged<int> onRatingChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.orderDetailCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MyText(
            hasSubmitted ? 'تقييمك للسائق' : 'قيّم السائق',
            fontSize: 14.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.productTitle,
            textAlign: TextAlign.right,
          ),
          if (driverName.trim().isNotEmpty) ...[
            SizedBox(height: 2.h),
            MyText(
              driverName,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.productStore,
              textAlign: TextAlign.right,
            ),
          ],
          SizedBox(height: 6.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var star = 1; star <= 5; star++)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2.w),
                  child: GestureDetector(
                    onTap: isSubmitting || hasSubmitted
                        ? null
                        : () => onRatingChanged(star),
                    behavior: HitTestBehavior.opaque,
                    child: Icon(
                      star <= selectedRating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: AppColors.ratingStar,
                      size: 22.sp,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 6.h),
          if (hasSubmitted) ...[
            if (commentController.text.trim().isNotEmpty)
              MyText(
                commentController.text.trim(),
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                textAlign: TextAlign.right,
              ),
          ] else ...[
            TextField(
              controller: commentController,
              enabled: !isSubmitting,
              maxLines: 2,
              minLines: 1,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Expo Arabic',
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'تعليق اختياري عن التوصيل',
                hintStyle: TextStyle(
                  fontFamily: 'Expo Arabic',
                  fontSize: 11.sp,
                  color: AppColors.textSecondary,
                ),
                filled: true,
                fillColor: AppColors.ordersPageBackground,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide:
                      BorderSide(color: AppColors.orderDetailCardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide:
                      BorderSide(color: AppColors.orderDetailCardBorder),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10.w,
                  vertical: 8.h,
                ),
              ),
            ),
            SizedBox(height: 8.h),
            SizedBox(
              height: 36.h,
              child: ElevatedButton(
                onPressed:
                    selectedRating > 0 && !isSubmitting ? onSubmit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor:
                      AppColors.primary.withValues(alpha: 0.6),
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: isSubmitting
                    ? SizedBox(
                        width: 16.w,
                        height: 16.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : MyText(
                        'إرسال التقييم',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
