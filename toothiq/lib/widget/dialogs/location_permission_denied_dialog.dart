import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import '../../utils/app_colors.dart';
import '../my_text.dart';

class LocationPermissionDeniedDialog extends StatelessWidget {
  const LocationPermissionDeniedDialog({super.key});

  static void show() {
    Get.dialog(
      const LocationPermissionDeniedDialog(),
      barrierDismissible: false,
    );
  }

  String _instructions() {
    if (Platform.isIOS) {
      return 'لتفعيل صلاحية الموقع:\n'
          '١) اضغط «فتح الإعدادات»\n'
          '٢) اختر «الموقع»\n'
          '٣) اختر «أثناء استخدام التطبيق»';
    }
    return 'لتفعيل صلاحية الموقع:\n'
        '١) اضغط «فتح الإعدادات»\n'
        '٢) فعّل صلاحية «الموقع»';
  }

  Future<void> _openSettings() async {
    await Geolocator.openAppSettings();
    if (Get.isDialogOpen == true) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      title: MyText(
        'صلاحية الموقع مرفوضة',
        fontSize: 20.sp,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        textAlign: TextAlign.center,
      ),
      content: MyText(
        'يحتاج التطبيق لصلاحية الموقع لتحديد عنوان التوصيل على الخريطة.\n\n${_instructions()}',
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        height: 1.5,
      ),
      contentPadding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 20.h),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('لاحقاً')),
        FilledButton(
          onPressed: _openSettings,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryDark,
            foregroundColor: Colors.white,
          ),
          child: const Text('فتح الإعدادات'),
        ),
      ],
    );
  }
}
