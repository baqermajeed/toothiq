import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controllers/register_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_spacing.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/auth_header.dart';

/// شاشة إنشاء حساب — StatelessWidget مع GetView و RegisterController.
class RegisterScreen extends GetView<RegisterController> {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'إنشاء حساب',
          style: TextStyle(
            fontFamily: kFontFamilyCairo,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppSpacing.verticalLg,
                const AuthHeader(),
                AppSpacing.verticalLg,
                AppTextField(
                  controller: controller.nameController,
                  hint: 'الاسم',
                  textInputAction: TextInputAction.next,
                  validator: (v) => v == null || v.isEmpty ? 'أدخل الاسم' : null,
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
                  hint: 'كلمة المرور (8 أحرف على الأقل)',
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'أدخل كلمة المرور';
                    if (v.length < 8) return 'كلمة المرور 8 أحرف على الأقل';
                    return null;
                  },
                  onFieldSubmitted: (_) => controller.submit(),
                ),
                AppSpacing.verticalMd,
                Obx(() {
                  final msg = controller.auth.errorMessage.value;
                  if (msg == null) return const SizedBox.shrink();
                  return Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.md),
                    child: Text(
                      msg,
                      style: TextStyle(
                        fontFamily: kFontFamilyCairo,
                        color: AppColors.error,
                        fontSize: 14.sp,
                      ),
                    ),
                  );
                }),
                Obx(() => AppButton(
                      label: 'إنشاء حساب',
                      loading: controller.auth.isLoading.value,
                      onPressed: controller.submit,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
