import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controller/session_controller.dart';
import '../../utils/app_colors.dart';
import '../../widget/my_text.dart';

class DriverSettingsPage extends StatelessWidget {
  const DriverSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionController>();

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(title: MyText('الإعدادات', fontSize: 18.sp)),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28.r,
                  backgroundColor: AppColors.primaryLight,
                  child: Icon(
                    Icons.delivery_dining,
                    color: AppColors.primary,
                    size: 28.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Obx(
                    () => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MyText(
                          session.displayName.value.isEmpty
                              ? 'مندوب توصيل'
                              : session.displayName.value,
                          fontSize: 15.sp,
                        ),
                        SizedBox(height: 4.h),
                        MyText(
                          'حساب مندوب التوصيل',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () => session.logout(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 50.h),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),
            ),
            child: MyText('تسجيل الخروج', fontSize: 15.sp, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
