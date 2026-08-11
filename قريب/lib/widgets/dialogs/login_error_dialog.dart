import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// دايلوج يعرض رسالة الخطأ من السيرفر عند فشل تسجيل الدخول أو إنشاء الحساب.
class LoginErrorDialog extends StatelessWidget {
  const LoginErrorDialog({
    super.key,
    required this.message,
    this.title,
  });

  final String message;
  /// عنوان الدايلوج. إن لم يُحدد يُستخدم "فشل تسجيل الدخول".
  final String? title;

  /// يعرض الدايلوج برسالة الخطأ (رد السيرفر أو خطأ عام).
  /// [title] اختياري: للإنشاء حساب استخدم "فشل إنشاء الحساب".
  static void show(String message, {String? title}) {
    Get.dialog(
      LoginErrorDialog(message: message, title: title),
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dialogTitle = title ?? 'فشل تسجيل الدخول';
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      title: Text(
        dialogTitle,
        style: TextStyle(
          fontFamily: kFontFamilyCairo,
          fontSize: 20.sp,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
        textAlign: TextAlign.center,
      ),
      content: Text(
        message,
        style: TextStyle(
          fontFamily: kFontFamilyCairo,
          fontSize: 15.sp,
          color: colorScheme.onSurfaceVariant,
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
              foregroundColor: AppColors.primaryLight,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),
            ),
            child: Text(
              'حسناً',
              style: TextStyle(
                fontFamily: kFontFamilyCairo,
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
