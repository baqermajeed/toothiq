import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import '../../utils/app_colors.dart';
import '../my_text.dart';

class PhotosPermissionDeniedDialog extends StatelessWidget {
  const PhotosPermissionDeniedDialog({super.key});

  static void show() {
    Get.dialog(
      const PhotosPermissionDeniedDialog(),
      barrierDismissible: false,
    );
  }

  String _instructions() {
    if (Platform.isIOS) {
      return 'لتفعيل الوصول إلى الصور:\n'
          '١) اضغط «فتح الإعدادات»\n'
          '٢) اختر «الصور»\n'
          '٣) اختر «كل الصور» أو «الصور المحددة»';
    }
    return 'لتفعيل الوصول إلى الصور:\n'
        '١) اضغط «فتح الإعدادات»\n'
        '٢) فعّل صلاحية «الصور والوسائط»';
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
        'صلاحية الصور مرفوضة',
        fontSize: 20.sp,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        textAlign: TextAlign.center,
      ),
      content: MyText(
        'يحتاج التطبيق للوصول إلى المعرض لاختيار صورة الملف الشخصي.\n\n${_instructions()}',
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
