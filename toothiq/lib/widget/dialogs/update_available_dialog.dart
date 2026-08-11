import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/app_colors.dart';
import '../my_text.dart';

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

  static Future<T?> show<T>({
    required String storeUrl,
    required bool forceUpdate,
    String? minimumVersion,
  }) {
    return Get.dialog<T>(
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
      final uri = Uri.tryParse(storeUrl);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
    if (!forceUpdate) {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      contentPadding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 24.h),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.system_update_rounded,
              size: 48.sp,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 20.h),
          MyText(
            'تحديث متاح',
            fontSize: 22.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.productTitle,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12.h),
          MyText(
            forceUpdate
                ? 'يجب تحديث التطبيق لمتابعة الاستخدام.'
                : 'يتوفر إصدار أحدث من التطبيق. ننصحك بالتحديث.',
            fontSize: 15.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
            textAlign: TextAlign.center,
            height: 1.5,
          ),
          if (minimumVersion != null && minimumVersion!.isNotEmpty) ...[
            SizedBox(height: 8.h),
            MyText(
              'الإصدار المطلوب: $minimumVersion',
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              textAlign: TextAlign.center,
            ),
          ],
          SizedBox(height: 24.h),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _openStore,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              child: MyText(
                'تحديث الآن',
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          if (!forceUpdate) ...[
            SizedBox(height: 12.h),
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('لاحقاً'),
            ),
          ],
        ],
      ),
    );
  }
}
