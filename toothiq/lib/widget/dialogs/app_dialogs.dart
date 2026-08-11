import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../utils/app_colors.dart';
import '../my_text.dart';

/// دايلوجات موحّدة للتأكيد والتحميل (مثل قريب).
abstract final class AppDialogs {
  static const _loadingRouteName = '/app-loading-dialog';
  static bool _loadingVisible = false;

  static Future<bool> confirm({
    required String title,
    required String message,
    String confirmLabel = 'نعم',
    String cancelLabel = 'لا',
  }) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: MyText(
          title,
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
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
      barrierDismissible: false,
    );
    return result == true;
  }

  static void showLoading(String message) {
    if (_loadingVisible) return;
    _loadingVisible = true;
    Get.dialog(
      PopScope(
        canPop: false,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 32.w),
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 40.w,
                    height: 40.h,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  MyText(
                    message,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: false,
      routeSettings: const RouteSettings(name: _loadingRouteName),
    ).whenComplete(() => _loadingVisible = false);
  }

  static void hideLoading() {
    if (!_loadingVisible) return;
    if (Get.isDialogOpen == true) Get.back();
    _loadingVisible = false;
  }

  static void showError({
    required String title,
    required String message,
    String buttonLabel = 'حسناً',
  }) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: MyText(
          title,
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
              child: Text(buttonLabel),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
}
