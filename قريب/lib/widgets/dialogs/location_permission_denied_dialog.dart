import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// دايلوج يظهر عند رفض صلاحية الموقع، مع زر لفتح الإعدادات وتعليمات التفعيل.
class LocationPermissionDeniedDialog extends StatelessWidget {
  const LocationPermissionDeniedDialog({super.key});

  /// يعرض الدايلوج باستخدام Get.dialog.
  static void show() {
    Get.dialog(
      const LocationPermissionDeniedDialog(),
      barrierDismissible: false,
    );
  }

  String _getInstructions() {
    if (Platform.isIOS) {
      return 'لتفعيل صلاحية الموقع:\n'
          '١) اضغط «فتح الإعدادات» أدناه\n'
          '٢) اختر «الموقع» أو «Location»\n'
          '٣) اختر «أثناء استخدام التطبيق» أو «While Using the App»';
    }
    return 'لتفعيل صلاحية الموقع:\n'
        '١) اضغط «فتح الإعدادات» أدناه\n'
        '٢) ابحث عن «صلاحيات» أو «Permissions»\n'
        '٣) فعّل صلاحية «الموقع» أو «Location»';
  }

  Future<void> _openSettings() async {
    await Geolocator.openAppSettings();
    if (Get.isDialogOpen ?? false) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      title: Text(
        'صلاحية الموقع مرفوضة',
        style: TextStyle(
          fontFamily: kFontFamilyCairo,
          fontSize: 20.sp,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'يحتاج التطبيق لصلاحية الموقع لعرض المحلات القريبة وتوصيل الطلبات.',
            style: TextStyle(
              fontFamily: kFontFamilyCairo,
              fontSize: 15.sp,
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: TextAlign.start,
          ),
          SizedBox(height: 16.h),
          Text(
            _getInstructions(),
            style: TextStyle(
              fontFamily: kFontFamilyCairo,
              fontSize: 14.sp,
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.start,
          ),
        ],
      ),
      contentPadding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 20.h),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: Text(
            'لاحقاً',
            style: TextStyle(
              fontFamily: kFontFamilyCairo,
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        FilledButton(
          onPressed: _openSettings,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryDark,
            foregroundColor: AppColors.primaryLight,
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.r),
            ),
          ),
          child: Text(
            'فتح الإعدادات',
            style: TextStyle(
              fontFamily: kFontFamilyCairo,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
