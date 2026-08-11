import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controller/orders_controller.dart';
import '../../model/order_model.dart';
import '../../utils/app_colors.dart';
import '../../view/orders/order_detail_page.dart';
import '../my_text.dart';

void showOrderSuccessDialog({
  required String orderId,
  VoidCallback? onClose,
}) {
  Get.dialog(
    _OrderSuccessDialog(orderId: orderId, onClose: onClose),
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
      Get.find<OrdersController>().refresh();
    }
    OrderDetailPage.open(
      OrderModel(
        id: orderId,
        orderName: 'طلب #$orderId',
        storeName: 'متجر',
        price: 0,
        imageAsset: 'assets/images/products/product_1.png',
        status: OrderStatus.pending,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      title: MyText(
        'تم إرسال الطلب بنجاح',
        fontSize: 20.sp,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        textAlign: TextAlign.center,
      ),
      content: MyText(
        'تم إنشاء طلبك بنجاح. يمكنك متابعة تفاصيل الطلب وحالته من الصفحة التالية.',
        fontSize: 15.sp,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        textAlign: TextAlign.center,
        height: 1.4,
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
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              child: MyText(
                'عرض تفاصيل الطلب',
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8.h),
            TextButton(
              onPressed: () {
                Get.back();
                onClose?.call();
                if (Get.isRegistered<OrdersController>()) {
                  Get.find<OrdersController>().refresh();
                }
              },
              child: const Text('حسناً'),
            ),
          ],
        ),
      ],
    );
  }
}
