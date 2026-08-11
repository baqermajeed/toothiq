import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// نوع التوست: معلومات، نجاح، خطأ، تحذير.
enum ToastType {
  info,
  success,
  error,
  warning,
}

/// بديل موحّد للـ SnackBar بتصميم متناسق مع التطبيق (Cairo، ألوان qaryp).
/// استخدم [AppToast.show] لعرض رسالة في أسفل الشاشة.
abstract final class AppToast {
  static const Duration _defaultDuration = Duration(seconds: 3);

  /// يعرض توستاً في أسفل الشاشة بعنوان ورسالة.
  /// [type] يحدد اللون والأيقونة (افتراضي: info).
  /// [duration] مدة العرض (افتراضي: 3 ثوان).
  static void show(
    String title,
    String message, {
    ToastType type = ToastType.info,
    Duration? duration,
  }) {
    final effectiveDuration = duration ?? _defaultDuration;
    final isDark = Get.isDarkMode;
    final (Color bgColor, Color leftColor, IconData icon) = _styleFor(type, isDark);

    Get.rawSnackbar(
      message: '',
      title: '',
      snackPosition: SnackPosition.BOTTOM,
      duration: effectiveDuration,
      backgroundColor: Colors.transparent,
      margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
      padding: EdgeInsets.zero,
      borderRadius: 0,
      titleText: const SizedBox.shrink(),
      messageText: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border(
            left: BorderSide(color: leftColor, width: 4.w),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 2.h),
              child: Icon(icon, size: 22.r, color: leftColor),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: kFontFamilyCairo,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    ),
                  ),
                  if (message.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Text(
                      message,
                      style: TextStyle(
                        fontFamily: kFontFamilyCairo,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w400,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static (Color bg, Color left, IconData icon) _styleFor(ToastType type, bool isDark) {
    final surface = isDark ? AppColors.surfaceDark : AppColors.surface;
    switch (type) {
      case ToastType.success:
        return (surface, const Color(0xFF2E7D32), Icons.check_circle_outline);
      case ToastType.error:
        return (surface, AppColors.error, Icons.error_outline);
      case ToastType.warning:
        return (surface, const Color(0xFFF57C00), Icons.warning_amber_rounded);
      case ToastType.info:
        return (surface, AppColors.primaryDark, Icons.info_outline);
    }
  }
}
