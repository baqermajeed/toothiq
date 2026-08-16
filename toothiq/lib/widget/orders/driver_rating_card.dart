import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../utils/app_colors.dart';
import '../my_text.dart';
import '../primary_button.dart';

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
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.orderDetailCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MyText(
            hasSubmitted ? 'تقييمك للسائق' : 'قيّم السائق',
            fontSize: 16.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.productTitle,
            textAlign: TextAlign.right,
          ),
          if (driverName.trim().isNotEmpty) ...[
            SizedBox(height: 4.h),
            MyText(
              driverName,
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.productStore,
              textAlign: TextAlign.right,
            ),
          ],
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var star = 1; star <= 5; star++)
                IconButton(
                  onPressed: isSubmitting ? null : () => onRatingChanged(star),
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    star <= selectedRating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: AppColors.ratingStar,
                    size: 34.sp,
                  ),
                ),
            ],
          ),
          SizedBox(height: 8.h),
          TextField(
            controller: commentController,
            enabled: !isSubmitting,
            maxLines: 3,
            minLines: 2,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'Expo Arabic',
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'تعليق اختياري عن التوصيل',
              hintStyle: TextStyle(
                fontFamily: 'Expo Arabic',
                fontSize: 13.sp,
                color: AppColors.textSecondary,
              ),
              filled: true,
              fillColor: AppColors.ordersPageBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide(color: AppColors.orderDetailCardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide(color: AppColors.orderDetailCardBorder),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 10.h,
              ),
            ),
          ),
          SizedBox(height: 12.h),
          PrimaryButton(
            label: hasSubmitted ? 'تحديث التقييم' : 'إرسال التقييم',
            onPressed: selectedRating > 0 && !isSubmitting ? onSubmit : null,
            isLoading: isSubmitting,
          ),
        ],
      ),
    );
  }
}
