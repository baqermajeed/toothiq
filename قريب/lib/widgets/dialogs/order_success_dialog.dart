import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controllers/orders_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../common/app_spacing.dart';

/// يعرض دايلوج «تم إرسال الطلب بنجاح» مع زر للانتقال مباشرة لصفحة تفاصيل الطلب.
void showOrderSuccessDialog({
  required String orderId,
  VoidCallback? onClose,
}) {
  Get.dialog(
    _OrderSuccessDialog(
      orderId: orderId,
      onClose: onClose,
    ),
    barrierDismissible: false,
  );
}

class _OrderSuccessDialog extends StatelessWidget {
  const _OrderSuccessDialog({
    required this.orderId,
    this.onClose,
  });

  final String orderId;
  final VoidCallback? onClose;

  void _goToOrderDetail() {
    Get.back();
    onClose?.call();
    if (Get.isRegistered<OrdersController>()) {
      Get.find<OrdersController>().loadOrders();
    }
    Get.toNamed('/order-detail', arguments: orderId);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      title: Text(
        'تم إرسال الطلب بنجاح',
        style: TextStyle(
          fontFamily: kFontFamilyCairo,
          fontSize: 20.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        textAlign: TextAlign.center,
      ),
      content: Text(
        'تم إنشاء طلبك بنجاح. يمكنك متابعة تفاصيل الطلب وحالته من الصفحة التالية.',
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
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton(
              onPressed: _goToOrderDetail,
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
            AppSpacing.verticalSm,
            TextButton(
              onPressed: () {
                Get.back();
                onClose?.call();
                if (Get.isRegistered<OrdersController>()) {
                  Get.find<OrdersController>().loadOrders();
                }
              },
              child: Text(
                'حسناً',
                style: TextStyle(
                  fontFamily: kFontFamilyCairo,
                  fontSize: 15.sp,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
