import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controllers/login_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_spacing.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/auth_header.dart';
import 'register_screen.dart';

/// شاشة تسجيل الدخول — StatelessWidget مع GetView و LoginController.
class LoginScreen extends GetView<LoginController> {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppSpacing.verticalXxl,
                AppSpacing.verticalXl,
                const AuthHeader(),
                AppSpacing.verticalXl,
                Text(
                  'تسجيل الدخول',
                  style: TextStyle(
                    fontFamily: kFontFamilyCairo,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                AppSpacing.verticalSm,
                Text(
                  'أدخل رقم هاتفك وكلمة المرور',
                  style: TextStyle(
                    fontFamily: kFontFamilyCairo,
                    fontSize: 15.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
                AppSpacing.verticalMd,
                AppTextField(
                  controller: controller.phoneController,
                  hint: 'رقم الهاتف',
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'أدخل رقم الهاتف' : null,
                ),
                AppSpacing.verticalMd,
                AppTextField(
                  controller: controller.passwordController,
                  hint: 'كلمة المرور',
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'أدخل كلمة المرور' : null,
                  onFieldSubmitted: (_) => controller.submit(),
                ),
                AppSpacing.verticalMd,
                Obx(() => AppButton(
                      label: 'تسجيل الدخول',
                      loading: controller.auth.isLoading.value,
                      onPressed: controller.submit,
                    )),
                AppSpacing.verticalLg,
                TextButton(
                  onPressed: () => Get.to(() => const RegisterScreen()),
                  child: Text(
                    'ليس لديك حساب؟ إنشاء حساب',
                    style: TextStyle(
                      fontFamily: kFontFamilyCairo,
                      fontSize: 15.sp,
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w600,
                    ),
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
