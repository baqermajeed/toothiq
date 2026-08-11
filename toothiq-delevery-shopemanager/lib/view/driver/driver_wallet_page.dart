import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controller/driver_orders_controller.dart';
import '../../model/partner_order.dart';
import '../../utils/app_colors.dart';
import '../../widget/my_text.dart';

class DriverWalletPage extends StatelessWidget {
  const DriverWalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DriverOrdersController>();

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(title: MyText('المحفظة', fontSize: 18.sp)),
      body: Obx(() {
        final delivered = controller.finishedOrders
            .where((o) => o.status == PartnerOrderStatus.delivered)
            .toList();
        final totalEarnings = delivered.fold<int>(
          0,
          (sum, o) => sum + o.deliveryFee,
        );

        return ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 20.r,
                    offset: Offset(0, 8.h),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText(
                    'إجمالي مستحقات التوصيل',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                  SizedBox(height: 8.h),
                  MyText(
                    _formatPrice(totalEarnings),
                    fontSize: 28.sp,
                    color: Colors.white,
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      _StatChip(
                        label: 'طلبات مُسلّمة',
                        value: '${delivered.length}',
                      ),
                      SizedBox(width: 10.w),
                      _StatChip(
                        label: 'قيد التنفيذ',
                        value: '${controller.inProgressOrders.length}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            MyText('آخر العمليات', fontSize: 15.sp),
            SizedBox(height: 12.h),
            if (delivered.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.h),
                  child: MyText(
                    'لا توجد عمليات بعد',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            else
              ...delivered.take(10).map(
                (order) => Container(
                  margin: EdgeInsets.only(bottom: 10.h),
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40.w,
                        height: 40.w,
                        decoration: BoxDecoration(
                          color: AppColors.orderStatusDeliveredBg,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(
                          Icons.add_circle_outline,
                          color: AppColors.success,
                          size: 22.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MyText(
                              'طلب #${order.orderNumber}',
                              fontSize: 13.sp,
                            ),
                            SizedBox(height: 2.h),
                            MyText(
                              order.formattedCreatedAt,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                      MyText(
                        '+${order.formattedDeliveryFee}',
                        fontSize: 14.sp,
                        color: AppColors.success,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }

  String _formatPrice(int value) {
    final formatted = value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$formatted د.ع';
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MyText(
              label,
              fontSize: 10.sp,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.8),
            ),
            SizedBox(height: 2.h),
            MyText(value, fontSize: 16.sp, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
