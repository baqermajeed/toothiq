import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../utils/launch_phone_utils.dart';

/// دايلوغ يظهر عند وجود تحديث للتطبيق — إما اختياري أو إجباري.
class UpdateAvailableDialog extends StatelessWidget {
  const UpdateAvailableDialog({
    super.key,
    required this.storeUrl,
    required this.forceUpdate,
    this.minimumVersion,
  });

  final String storeUrl;
  final bool forceUpdate;
  final String? minimumVersion;

  /// يعرض الدايلوغ. [forceUpdate] يمنع الإغلاق بدون تحديث.
  static void show({
    required String storeUrl,
    required bool forceUpdate,
    String? minimumVersion,
  }) {
    Get.dialog(
      UpdateAvailableDialog(
        storeUrl: storeUrl,
        forceUpdate: forceUpdate,
        minimumVersion: minimumVersion,
      ),
      barrierDismissible: !forceUpdate,
    );
  }

  Future<void> _openStore() async {
    if (storeUrl.isNotEmpty) {
      await launchUrlString(storeUrl);
    }
    if (!forceUpdate) {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.r),
      ),
      contentPadding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 24.h),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                  .withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.system_update_rounded,
              size: 48.sp,
              color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'تحديث متاح',
            style: TextStyle(
              fontFamily: kFontFamilyCairo,
              fontSize: 22.sp,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12.h),
          Text(
            forceUpdate
                ? 'يجب تحديث التطبيق لمتابعة الاستخدام.'
                : 'يتوفر إصدار أحدث من التطبيق. ننصحك بالتحديث.',
            style: TextStyle(
              fontFamily: kFontFamilyCairo,
              fontSize: 15.sp,
              height: 1.5,
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (minimumVersion != null && minimumVersion!.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              'الإصدار المطلوب: $minimumVersion',
              style: TextStyle(
                fontFamily: kFontFamilyCairo,
                fontSize: 14.sp,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.9),
              ),
            ),
          ],
          SizedBox(height: 24.h),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _openStore,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: AppColors.primaryLight,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              child: Text(
                'تحديث الآن',
                style: TextStyle(
                  fontFamily: kFontFamilyCairo,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (!forceUpdate) ...[
            SizedBox(height: 12.h),
            TextButton(
              onPressed: () => Get.back(),
              child: Text(
                'لاحقاً',
                style: TextStyle(
                  fontFamily: kFontFamilyCairo,
                  fontSize: 15.sp,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
