import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controller/session_controller.dart';
import '../../model/user_role.dart';
import '../../utils/app_colors.dart';
import '../../widget/my_text.dart';
import 'login_page.dart';

class RoleSelectPage extends StatelessWidget {
  const RoleSelectPage({super.key});

  Future<void> _pickRole(AppUserRole role) async {
    await Get.find<SessionController>().selectRole(role);
    Get.to(() => LoginPage(role: role));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              SizedBox(height: 48.h),
              Image.asset(
                'assets/images/icon/toothiqlogo.png',
                width: 96.w,
                height: 96.w,
              ),
              SizedBox(height: 12.h),
              Image.asset(
                'assets/images/icon/toothiqtext.png',
                width: 140.w,
              ),
              SizedBox(height: 8.h),
              MyText(
                'تطبيق الشركاء',
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
              SizedBox(height: 36.h),
              MyText(
                'كيف تريد الدخول؟',
                fontSize: 20.sp,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              MyText(
                'اختر دورك لفتح الواجهة المناسبة',
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.h),
              _RoleCard(
                icon: Icons.storefront_rounded,
                title: 'صاحب متجر',
                subtitle: 'إدارة المنتجات وقبول الطلبات',
                onTap: () => _pickRole(AppUserRole.shop),
              ),
              SizedBox(height: 14.h),
              _RoleCard(
                icon: Icons.delivery_dining_rounded,
                title: 'مندوب توصيل',
                subtitle: 'عرض الطلبات وموقع المتجر والزبون',
                onTap: () => _pickRole(AppUserRole.driver),
              ),
              const Spacer(),
              MyText(
                'مكمل لتطبيق ToothIQ للعملاء',
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textLight,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 52.w,
              height: 52.w,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Icon(icon, color: Colors.white, size: 28.sp),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText(title, fontSize: 16.sp),
                  SizedBox(height: 4.h),
                  MyText(
                    subtitle,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_back_ios_new,
              size: 16.sp,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
