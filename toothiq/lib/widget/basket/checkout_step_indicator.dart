import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../utils/app_colors.dart';

class CheckoutStepIndicator extends StatelessWidget {
  final int currentIndex;

  const CheckoutStepIndicator({super.key, required this.currentIndex});

  static const _labels = ['بيانات التوصيل', 'تأكيد الطلب', 'تم الإرسال'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: List.generate(_labels.length * 2 - 1, (index) {
          if (index.isOdd) {
            final stepIndex = index ~/ 2;
            final done = currentIndex > stepIndex;
            return Expanded(
              child: Container(
                height: 2.h,
                margin: EdgeInsets.only(bottom: 18.h),
                color: done
                    ? AppColors.productStore
                    : AppColors.indicatorInactive,
              ),
            );
          }

          final stepIndex = index ~/ 2;
          final active = currentIndex >= stepIndex;
          final completed = currentIndex > stepIndex;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28.w,
                height: 28.w,
                decoration: BoxDecoration(
                  color: active ? AppColors.productStore : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: active
                        ? AppColors.productStore
                        : AppColors.indicatorInactive,
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: completed
                    ? Icon(Icons.check, color: Colors.white, size: 16.sp)
                    : Text(
                        '${stepIndex + 1}',
                        style: TextStyle(
                          fontFamily: 'Expo Arabic',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                          color: active ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
              ),
              SizedBox(height: 6.h),
              SizedBox(
                width: 72.w,
                child: Text(
                  _labels[stepIndex],
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                    fontFamily: 'Expo Arabic',
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: active
                        ? AppColors.productTitle
                        : AppColors.textSecondary,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
