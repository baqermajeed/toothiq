import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../utils/app_colors.dart';
import '../my_text.dart';

enum SettingsConfirmType {
  logout,
  deleteAccount,
}

class SettingsConfirmDialog extends StatelessWidget {
  final SettingsConfirmType type;

  const SettingsConfirmDialog({super.key, required this.type});

  static Future<bool?> show(SettingsConfirmType type) {
    return Get.dialog<bool>(
      SettingsConfirmDialog(type: type),
      barrierDismissible: true,
    );
  }

  static Future<bool?> showLogout() => show(SettingsConfirmType.logout);

  static Future<bool?> showDeleteAccount() =>
      show(SettingsConfirmType.deleteAccount);

  Color get _accent => switch (type) {
        SettingsConfirmType.logout => AppColors.settingsLogout,
        SettingsConfirmType.deleteAccount => AppColors.settingsDelete,
      };

  Color get _iconBackground => switch (type) {
        SettingsConfirmType.logout => AppColors.settingsLogout,
        SettingsConfirmType.deleteAccount => const Color(0xFFFFEBEE),
      };

  Color get _iconColor => switch (type) {
        SettingsConfirmType.logout => Colors.white,
        SettingsConfirmType.deleteAccount => AppColors.settingsDelete,
      };

  IconData get _icon => switch (type) {
        SettingsConfirmType.logout => Icons.logout_rounded,
        SettingsConfirmType.deleteAccount => Icons.delete_outline_rounded,
      };

  String get _title => switch (type) {
        SettingsConfirmType.logout => 'تسجيل الخروج',
        SettingsConfirmType.deleteAccount => 'حذف الحساب',
      };

  String get _message => switch (type) {
        SettingsConfirmType.logout => 'لن تفقد بياناتك ، هل أنت متأكد ؟',
        SettingsConfirmType.deleteAccount =>
          'ستفقد كافة بياناتك ، هل أنت متأكد ؟',
      };

  String get _confirmLabel => _title;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        insetPadding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52.w,
                height: 52.w,
                decoration: BoxDecoration(
                  color: _iconBackground,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(
                  _icon,
                  color: _iconColor,
                  size: 28.sp,
                ),
              ),
              SizedBox(height: 16.h),
              MyText(
                _title,
                fontSize: 20.sp,
                fontWeight: FontWeight.w800,
                color: _accent,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10.h),
              Text(
                _message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Expo Arabic',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48.h,
                      child: ElevatedButton(
                        onPressed: () => Get.back(result: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                        child: MyText(
                          _confirmLabel,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: SizedBox(
                      height: 48.h,
                      child: OutlinedButton(
                        onPressed: () => Get.back(result: false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _accent,
                          side: BorderSide(color: _accent, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                        child: MyText(
                          'الغاء',
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: _accent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
