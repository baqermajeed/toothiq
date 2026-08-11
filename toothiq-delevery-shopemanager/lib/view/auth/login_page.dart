import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controller/session_controller.dart';
import '../../core/api/api_exception.dart';
import '../../core/utils/phone_validator.dart';
import '../../model/user_role.dart';
import '../../utils/app_colors.dart';
import '../../widget/auth_text_field.dart';
import '../../widget/my_text.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.role});

  final AppUserRole role;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _isLoading = false.obs;
  final _obscurePassword = true.obs;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    _isLoading.value = true;
    try {
      final session = Get.find<SessionController>();
      await session.login(
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        selectedRole: widget.role,
      );
      session.openHomeForRole();
    } on ApiException catch (error) {
      Get.snackbar('تعذر الدخول', error.message);
    } catch (_) {
      Get.snackbar('تعذر الدخول', 'تحقق من الاتصال وحاول مجدداً');
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isShop = widget.role == AppUserRole.shop;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back_ios_new),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 12.h),
                Center(
                  child: Container(
                    width: 64.w,
                    height: 64.w,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Icon(
                      isShop
                          ? Icons.storefront_rounded
                          : Icons.delivery_dining_rounded,
                      color: AppColors.primary,
                      size: 32.sp,
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                MyText(
                  isShop ? 'دخول صاحب المتجر' : 'دخول مندوب التوصيل',
                  fontSize: 20.sp,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
                MyText(
                  isShop
                      ? 'أضف منتجاتك واقبل الطلبات الواردة'
                      : 'استلم الطلبات وتابع مسار التوصيل',
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32.h),
                AuthTextField(
                  controller: _phoneController,
                  label: 'رقم الهاتف',
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'أدخل رقم الهاتف';
                    }
                    if (!PhoneValidator.isValidIraqiPhone(value)) {
                      return 'رقم هاتف غير صالح';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.h),
                Obx(
                  () => AuthTextField(
                    controller: _passwordController,
                    label: 'كلمة المرور',
                    obscureText: _obscurePassword.value,
                    suffixIcon: IconButton(
                      onPressed: () =>
                          _obscurePassword.value = !_obscurePassword.value,
                      icon: Icon(
                        _obscurePassword.value
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'أدخل كلمة المرور';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 28.h),
                Obx(
                  () => ElevatedButton(
                    onPressed: _isLoading.value ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 52.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading.value
                        ? SizedBox(
                            width: 22.w,
                            height: 22.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : MyText(
                            'دخول',
                            fontSize: 16.sp,
                            color: Colors.white,
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
