import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// دايلوج يوضح أن منطقتك الحالية تدعم فقط الطلبات الصوتية (لا محلات حالياً).
class VoiceOrderOnlyDialog extends StatelessWidget {
  const VoiceOrderOnlyDialog({super.key});

  static void show() {
    Get.dialog(
      const VoiceOrderOnlyDialog(),
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      title: Text(
        'منطقتك الحالية تدعم فقط الطلبات الصوتية',
        style: TextStyle(
          fontFamily: kFontFamilyCairo,
          fontSize: 20.sp,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
        textAlign: TextAlign.center,
      ),
      content: Text(
        'لا توجد محلات في منطقتك حالياً. يمكنك طلب التوصيل بتسجيل طلب صوتي من الصفحة الرئيسية. سنضيف المحلات لاحقاً.',
        style: TextStyle(
          fontFamily: kFontFamilyCairo,
          fontSize: 15.sp,
          color: colorScheme.onSurfaceVariant,
          height: 1.4,
        ),
        textAlign: TextAlign.center,
      ),
      contentPadding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 20.h),
      actions: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Get.back(),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              foregroundColor: AppColors.primaryLight,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),
            ),
            child: Text(
              'حسناً',
              style: TextStyle(
                fontFamily: kFontFamilyCairo,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
