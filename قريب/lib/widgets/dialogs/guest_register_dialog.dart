import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controllers/app_location_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../common/app_spacing.dart';
import '../common/app_text_field.dart';

/// نتيجة عرض دايلوج تسجيل الضيف.
typedef GuestRegisterResult = ({String phone, String code});

/// يعرض دايلوج لتسجيل الضيف (الاسم ورقم الهاتف) قبل إرسال الطلب.
/// يُرجع (phone, code) عند النجاح أو null عند الإلغاء/الفشل.
Future<GuestRegisterResult?> showGuestRegisterDialog() async {
  if (!Get.isRegistered<AuthController>()) return null;
  if (!Get.isRegistered<AppLocationController>()) return null;

  final result = await Get.dialog<GuestRegisterResult>(
    const GuestRegisterDialog(),
    barrierDismissible: false,
  );
  return result;
}

/// دايلوج تسجيل الضيف: الاسم + رقم الهاتف.
class GuestRegisterDialog extends StatefulWidget {
  const GuestRegisterDialog({super.key});

  @override
  State<GuestRegisterDialog> createState() => _GuestRegisterDialogState();
}

class _GuestRegisterDialogState extends State<GuestRegisterDialog> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'أدخل اسمك');
      return;
    }
    if (phone.isEmpty) {
      setState(() => _errorMessage = 'أدخل رقم الهاتف');
      return;
    }

    setState(() {
      _errorMessage = null;
      _isSubmitting = true;
    });

    final auth = Get.find<AuthController>();
    final appLoc = Get.find<AppLocationController>();
    final location = appLoc.hasLocation ? appLoc.coordinates : null;

    final result = await auth.guestRegister(
      name: name,
      phone: phone,
      location: location,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result != null) {
      Get.back(result: result);
    } else {
      setState(() => _errorMessage = auth.errorMessage.value ?? 'فشل التسجيل');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      title: Text(
        'أدخل بياناتك',
        style: TextStyle(
          fontFamily: kFontFamilyCairo,
          fontSize: 20.sp,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
        textAlign: TextAlign.center,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'لإتمام الطلب، أدخل اسمك ورقم هاتفك وسيُنشأ لك حساب تلقائياً.',
              style: TextStyle(
                fontFamily: kFontFamilyCairo,
                fontSize: 14.sp,
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.verticalLg,
            AppTextField(
              controller: _nameController,
              hint: 'الاسم',
              keyboardType: TextInputType.name,
              onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
            ),
            AppSpacing.verticalMd,
            AppTextField(
              controller: _phoneController,
              hint: 'رقم الهاتف',
              keyboardType: TextInputType.phone,
              onFieldSubmitted: (_) => _submit(),
            ),
            if (_errorMessage != null) ...[
              AppSpacing.verticalMd,
              Text(
                _errorMessage!,
                style: TextStyle(
                  fontFamily: kFontFamilyCairo,
                  fontSize: 13.sp,
                  color: AppColors.error,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
      contentPadding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 20.h),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Get.back(),
          child: Text(
            'إلغاء',
            style: TextStyle(
              fontFamily: kFontFamilyCairo,
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryDark,
            foregroundColor: AppColors.primaryLight,
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.r),
            ),
          ),
          child: _isSubmitting
              ? SizedBox(
                  width: 24.w,
                  height: 24.h,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryLight,
                  ),
                )
              : Text(
                  'متابعة',
                  style: TextStyle(
                    fontFamily: kFontFamilyCairo,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
    );
  }
}
