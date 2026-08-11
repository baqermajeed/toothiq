import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controllers/orders_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../common/app_spacing.dart';
import '../common/app_toast.dart';

/// يعرض دايلوج «تم إتمام طلبك بنجاح» مع معلومات الحساب (رقم + رمز) للضيف.
/// إن وُفر [orderId] يُعرض زر «عرض تفاصيل الطلب» للانتقال لصفحة تفاصيل الطلب.
void showOrderSuccessWithCredentialsDialog({
  required String phone,
  required String code,
  String? orderId,
  VoidCallback? onClose,
}) {
  Get.dialog(
    _OrderSuccessCredentialsDialog(
      phone: phone,
      code: code,
      orderId: orderId,
      onClose: onClose,
    ),
    barrierDismissible: false,
  );
}

class _OrderSuccessCredentialsDialog extends StatelessWidget {
  const _OrderSuccessCredentialsDialog({
    required this.phone,
    required this.code,
    this.orderId,
    this.onClose,
  });

  final String phone;
  final String code;
  final String? orderId;
  final VoidCallback? onClose;

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    AppToast.show('تم النسخ', '$label تم نسخه', type: ToastType.success);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      title: Text(
        'تم إتمام طلبك بنجاح',
        style: TextStyle(
          fontFamily: kFontFamilyCairo,
          fontSize: 20.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        textAlign: TextAlign.center,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'تم تسجيل دخولك تلقائياً. يمكنك متابعة طلباتك من تبويب طلباتي وتعديل بياناتك من حسابي.',
              style: TextStyle(
                fontFamily: kFontFamilyCairo,
                fontSize: 15.sp,
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.verticalMd,
            Text(
              'احتفظ بهذه المعلومات لتسجيل الدخول لاحقاً من جهاز آخر:',
              style: TextStyle(
                fontFamily: kFontFamilyCairo,
                fontSize: 14.sp,
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.verticalLg,
            _CredentialRow(
              label: 'رقم الهاتف',
              value: phone,
              onCopy: () => _copy(phone, 'رقم الهاتف'),
            ),
            AppSpacing.verticalMd,
            _CredentialRow(
              label: 'الرمز',
              value: code,
              onCopy: () => _copy(code, 'الرمز'),
            ),
          ],
        ),
      ),
      contentPadding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 20.h),
      actions: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (orderId != null && orderId!.isNotEmpty) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Get.back();
                    onClose?.call();
                    if (Get.isRegistered<OrdersController>()) {
                      Get.find<OrdersController>().loadOrders();
                    }
                    Get.toNamed('/order-detail', arguments: orderId);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: AppColors.primaryLight,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: Text(
                    'عرض تفاصيل الطلب',
                    style: TextStyle(
                      fontFamily: kFontFamilyCairo,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              AppSpacing.verticalSm,
            ],
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Get.back();
                  onClose?.call();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: orderId != null && orderId!.isNotEmpty
                      ? colorScheme.surfaceContainerHighest
                      : AppColors.primaryDark,
                  foregroundColor: orderId != null && orderId!.isNotEmpty
                      ? colorScheme.onSurface
                      : AppColors.primaryLight,
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
        ),
      ],
    );
  }
}

class _CredentialRow extends StatelessWidget {
  const _CredentialRow({
    required this.label,
    required this.value,
    required this.onCopy,
  });

  final String label;
  final String value;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: kFontFamilyCairo,
                    fontSize: 12.sp,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: kFontFamilyCairo,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCopy,
            icon: Icon(Icons.copy_rounded, size: 22.sp, color: colorScheme.primary),
            tooltip: 'نسخ',
          ),
        ],
      ),
    );
  }
}
