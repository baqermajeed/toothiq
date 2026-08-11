import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../controller/shop_orders_controller.dart';
import '../../model/partner_order.dart';
import '../../utils/app_colors.dart';
import '../../widget/my_text.dart';

class ShopOrderDetailPage extends StatelessWidget {
  const ShopOrderDetailPage({super.key, required this.order});

  final PartnerOrder order;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ShopOrdersController>();

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: MyText('طلب #${order.orderNumber}', fontSize: 18.sp),
      ),
      body: Obx(() {
        final live = controller.orders.firstWhereOrNull((o) => o.id == order.id) ??
            order;

        return ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            _InfoCard(
              children: [
                _row('الحالة', live.status.label),
                _row('الزبون', live.customerName),
                _row('الهاتف', live.customerPhone),
                _row('العنوان', live.customerAddress),
                _row('الإجمالي', live.formattedTotal),
              ],
            ),
            SizedBox(height: 14.h),
            MyText('المنتجات', fontSize: 15.sp),
            SizedBox(height: 8.h),
            ...live.items.map(
              (item) => Container(
                margin: EdgeInsets.only(bottom: 8.h),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: MyText(item.name, fontSize: 13.sp),
                    ),
                    MyText(
                      '×${item.quantity}',
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20.h),
            if (live.status == PartnerOrderStatus.pending) ...[
              ElevatedButton(
                onPressed: () async {
                  await controller.acceptOrder(live.id);
                  Get.snackbar('تم', 'تم قبول الطلب وبدء التحضير');
                },
                style: _primaryBtn(),
                child: MyText('قبول الطلب', fontSize: 15.sp, color: Colors.white),
              ),
              SizedBox(height: 10.h),
              OutlinedButton(
                onPressed: () async {
                  await controller.rejectOrder(live.id);
                  Get.back();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  minimumSize: Size(double.infinity, 48.h),
                  side: const BorderSide(color: AppColors.error),
                ),
                child: MyText('رفض الطلب', fontSize: 15.sp, color: AppColors.error),
              ),
            ],
            if (live.status == PartnerOrderStatus.preparing ||
                live.status == PartnerOrderStatus.accepted) ...[
              ElevatedButton(
                onPressed: () async {
                  await controller.markReadyForDelivery(live.id);
                  Get.snackbar('تم', 'الطلب جاهز للتوصيل');
                },
                style: _primaryBtn(),
                child: MyText(
                  'جاهز للتوصيل',
                  fontSize: 15.sp,
                  color: Colors.white,
                ),
              ),
            ],
            SizedBox(height: 10.h),
            OutlinedButton.icon(
              onPressed: () => launchUrl(Uri.parse('tel:${live.customerPhone}')),
              icon: const Icon(Icons.phone),
              label: MyText('اتصال بالزبون', fontSize: 14.sp),
              style: OutlinedButton.styleFrom(
                minimumSize: Size(double.infinity, 48.h),
                foregroundColor: AppColors.primary,
              ),
            ),
          ],
        );
      }),
    );
  }

  ButtonStyle _primaryBtn() => ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: Size(double.infinity, 48.h),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
      );

  Widget _row(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80.w,
            child: MyText(
              label,
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          Expanded(child: MyText(value, fontSize: 13.sp)),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(children: children),
    );
  }
}
