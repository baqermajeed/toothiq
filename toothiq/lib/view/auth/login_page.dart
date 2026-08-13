import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controller/auth_controller.dart';
import '../../utils/app_colors.dart';
import '../../widget/auth_footer_link.dart';
import '../../widget/auth_logo_placeholder.dart';
import '../../widget/auth_page_decorations.dart';
import '../../widget/auth_text_field.dart';
import '../../widget/decorative_background.dart';
import '../../widget/my_text.dart';
import '../../widget/primary_button.dart';
import 'register_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController());

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: DecorativeBackground(
          child: Stack(
            children: [
              const Positioned.fill(child: AuthPageDecorations()),
              SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 28.w),
                  child: Column(
                    children: [
                      SizedBox(height: 20.h),
                      const Center(child: AuthLogoPlaceholder(size: 110)),
                      SizedBox(height: 8.h),
                      MyText(
                        'تسجيل الدخول',
                        fontSize: 26.sp,
                        fontWeight: FontWeight.w800,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 12.h),
                      MyText(
                        'أدخل معلوماتك لتسجيل الدخول الى حسابك',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                        textAlign: TextAlign.center,
                        height: 1.5,
                      ),
                      SizedBox(height: 36.h),
                      Obx(
                        () => AuthTextField(
                          controller: auth.loginPhoneCtrl,
                          hint: 'أكتب رقم الهاتف',
                          icon: Icons.phone_android_outlined,
                          keyboardType: TextInputType.phone,
                          errorText: auth.loginPhoneError.value,
                          onChanged: (_) => auth.clearLoginErrors(),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Obx(
                        () => AuthTextField(
                          controller: auth.loginPasswordCtrl,
                          hint: 'كلمة المرور',
                          icon: Icons.lock_outline_rounded,
                          isPassword: true,
                          errorText: auth.loginPasswordError.value,
                          onChanged: (_) => auth.clearLoginErrors(),
                        ),
                      ),
                      SizedBox(height: 32.h),
                      Obx(
                        () => PrimaryButton(
                          label: 'تسجيل الدخول',
                          isLoading: auth.isLoading.value,
                          onPressed: auth.login,
                        ),
                      ),
                      SizedBox(height: 24.h),
                      AuthFooterLink(
                        prefix: 'ليس لديك حساب ؟ ',
                        linkText: 'أنشئ واحدًا',
                        onLinkTap: () {
                          Get.to(() => const RegisterPage());
                        },
                      ),
                      SizedBox(height: 24.h),
                    ],
                  )
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .slideY(
                        begin: 0.08,
                        end: 0,
                        duration: 500.ms,
                        curve: Curves.easeOutCubic,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
