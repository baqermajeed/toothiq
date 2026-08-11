import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controller/session_controller.dart';
import '../../service_layer/services/preferences_storage.dart';
import '../../utils/app_colors.dart';
import '../../utils/storage_keys.dart';
import '../../widget/my_text.dart';
import '../auth/login_page.dart';
import '../onboarding/onboarding_page.dart';

/// مؤقت — يُستبدل بالصفحة الرئيسية عند تسليم التصميم.
class PlaceholderHomePage extends StatelessWidget {
  const PlaceholderHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: MyText(
            'متجر طب الأسنان',
            fontSize: 20.sp,
            color: AppColors.primary,
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.construction_outlined,
                  size: 64.sp,
                  color: AppColors.textSecondary,
                ),
                SizedBox(height: 16.h),
                MyText(
                  'الصفحة الرئيسية قيد التطوير',
                  fontSize: 18.sp,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
                MyText(
                  'أرسل التصميم التالي لنكمل البناء',
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32.h),
                TextButton(
                  onPressed: () async {
                    await Get.find<SessionController>().clearSession();
                    Get.offAll(() => const LoginPage());
                  },
                  child: MyText(
                    'تسجيل الخروج (للتجربة)',
                    fontSize: 14.sp,
                    color: AppColors.primary,
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await PreferencesStorage.instance.remove(
                      StorageKeys.onboardingCompleted,
                    );
                    await Get.find<SessionController>().clearSession();
                    Get.offAll(() => const OnboardingPage());
                  },
                  child: MyText(
                    'إعادة Onboarding (للتجربة)',
                    fontSize: 14.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
