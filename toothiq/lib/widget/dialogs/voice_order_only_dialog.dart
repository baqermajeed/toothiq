import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../utils/app_colors.dart';

/// دايلوج يوضح أن المنطقة تدعم خيارات طلب محدودة حالياً (مثل قريب).
class VoiceOrderOnlyDialog extends StatelessWidget {
  const VoiceOrderOnlyDialog({super.key});

  static void show() {
    Get.dialog(
      const VoiceOrderOnlyDialog(),
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      title: Text(
        'منطقتك غير متاحة للطلب العادي حالياً',
        style: TextStyle(
          fontFamily: 'Expo Arabic',
          fontSize: 20.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        textAlign: TextAlign.center,
      ),
      content: Text(
        'لا تتوفر خدمة التوصيل الكاملة في منطقتك بعد. سنضيف التغطية قريباً — جرّب لاحقاً أو تواصل مع الدعم.',
        style: TextStyle(
          fontFamily: 'Expo Arabic',
          fontSize: 15.sp,
          color: AppColors.textSecondary,
          height: 1.4,
        ),
        textAlign: TextAlign.center,
      ),
      contentPadding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 20.h),
      actions: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Get.back(),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),
            ),
            child: Text(
              'حسناً',
              style: TextStyle(
                fontFamily: 'Expo Arabic',
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
