import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../utils/app_colors.dart';
import '../my_text.dart';

class LoginErrorDialog extends StatelessWidget {
  const LoginErrorDialog({
    super.key,
    required this.message,
    this.title,
  });

  final String message;
  final String? title;

  static void show(String message, {String? title}) {
    Get.dialog(
      LoginErrorDialog(message: message, title: title),
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dialogTitle = title ?? 'فشل تسجيل الدخول';
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      title: MyText(
        dialogTitle,
        fontSize: 20.sp,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        textAlign: TextAlign.center,
      ),
      content: MyText(
        message,
        fontSize: 15.sp,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        textAlign: TextAlign.center,
        height: 1.4,
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
            child: MyText(
              'حسناً',
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
