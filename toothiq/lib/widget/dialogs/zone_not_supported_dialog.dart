import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../core/api/api_exception.dart';
import '../../utils/app_colors.dart';

/// دايلوغ يوضح أن موقع المستخدم غير مدعوم للتوصيل حالياً.
class ZoneNotSupportedDialog extends StatelessWidget {
  const ZoneNotSupportedDialog({
    super.key,
    this.subtitle,
  });

  final String? subtitle;

  static void show({String? subtitle}) {
    Get.dialog(
      ZoneNotSupportedDialog(subtitle: subtitle),
      barrierDismissible: false,
    );
  }

  static bool isZoneError(ApiException error) =>
      ApiException.isZoneError(error);

  @override
  Widget build(BuildContext context) {
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
              color: AppColors.primaryLight.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_off_rounded,
              size: 48.sp,
              color: AppColors.primaryDark,
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'موقعك غير مدعوم حالياً',
            style: TextStyle(
              fontFamily: 'Expo Arabic',
              fontSize: 22.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12.h),
          Text(
            'عنوان التوصيل الذي اخترته يقع خارج مناطق التوصيل المتاحة. سنضيف تغطية لمنطقتك قريباً.',
            style: TextStyle(
              fontFamily: 'Expo Arabic',
              fontSize: 15.sp,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Text(
              subtitle!,
              style: TextStyle(
                fontFamily: 'Expo Arabic',
                fontSize: 14.sp,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          SizedBox(height: 24.h),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Get.back(),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16.h),
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
      ),
    );
  }
}
