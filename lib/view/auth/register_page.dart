import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controller/auth_controller.dart';
import '../../utils/app_colors.dart';
import '../../utils/iraq_governorates.dart';
import '../../widget/auth_footer_link.dart';
import '../../widget/auth_text_field.dart';
import '../../widget/my_text.dart';
import '../../widget/primary_button.dart';
import '../../widget/profile_avatar_placeholder.dart';
import 'login_page.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController());

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 28.w),
            child: Column(
              children: [
                SizedBox(height: 24.h),
                const Center(child: ProfileAvatarPlaceholder()),
                SizedBox(height: 24.h),
                MyText(
                  'أنشاء الحساب',
                  fontSize: 26.sp,
                  fontWeight: FontWeight.w800,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12.h),
                MyText(
                  'أدخل معلوماتك لأنشاء حساب جديد في التطبيق',
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  textAlign: TextAlign.center,
                  height: 1.5,
                ),
                SizedBox(height: 28.h),
                Obx(
                  () => AuthTextField(
                    controller: auth.nameCtrl,
                    hint: 'أسمك',
                    icon: Icons.person_outline,
                    errorText: auth.nameError.value,
                    onChanged: (_) {
                      if (auth.nameError.value != null) {
                        auth.nameError.value = null;
                      }
                    },
                  ),
                ),
                SizedBox(height: 16.h),
                Obx(
                  () => AuthTextField(
                    controller: auth.registerPhoneCtrl,
                    hint: 'رقم الهاتف',
                    icon: Icons.phone_android_outlined,
                    keyboardType: TextInputType.phone,
                    errorText: auth.registerPhoneError.value,
                    onChanged: (_) => auth.clearRegisterErrors(),
                  ),
                ),
                SizedBox(height: 16.h),
                Obx(
                  () => AuthTextField(
                    controller: auth.governorateCtrl,
                    hint: 'محافظتك',
                    icon: Icons.map_outlined,
                    readOnly: true,
                    errorText: auth.governorateError.value,
                    onTap: () => _showGovernoratePicker(context, auth),
                    trailing: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary,
                      size: 24.sp,
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                AuthTextField(
                  controller: auth.clinicNameCtrl,
                  hint: '( أسم عيادتك ( أختياري',
                  icon: Icons.local_hospital_outlined,
                ),
                SizedBox(height: 32.h),
                Obx(
                  () => PrimaryButton(
                    label: 'أنشاء الحساب',
                    isLoading: auth.isLoading.value,
                    onPressed: auth.register,
                  ),
                ),
                SizedBox(height: 24.h),
                AuthFooterLink(
                  prefix: 'لديك حساب ؟ ',
                  linkText: 'سجل الدخول اليه',
                  onLinkTap: () => Get.off(() => const LoginPage()),
                ),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showGovernoratePicker(BuildContext context, AuthController auth) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(20.w),
                child: MyText(
                  'اختر محافظتك',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: IraqGovernorates.all.length,
                  itemBuilder: (context, index) {
                    final governorate = IraqGovernorates.all[index];
                    return ListTile(
                      title: MyText(
                        governorate,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      onTap: () {
                        auth.pickGovernorate(governorate);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              SizedBox(height: 16.h),
            ],
          ),
        );
      },
    );
  }
}
