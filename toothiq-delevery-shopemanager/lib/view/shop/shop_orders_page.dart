import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controller/shop_orders_controller.dart';
import '../../model/partner_order.dart';
import '../../utils/app_colors.dart';
import '../../widget/my_text.dart';
import '../../widget/order_card.dart';
import 'shop_order_detail_page.dart';

class ShopOrdersPage extends StatelessWidget {
  const ShopOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ShopOrdersController>();

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(title: MyText('طلبات المتجر', fontSize: 18.sp)),
      body: Obx(() {
        final list = controller.orders;
        if (list.isEmpty) {
          return Center(
            child: MyText(
              'لا توجد طلبات',
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.all(16.w),
          itemCount: list.length,
          separatorBuilder: (context, index) => SizedBox(height: 10.h),
          itemBuilder: (context, index) {
            final order = list[index];
            return OrderCard(
              order: order,
              onTap: () => Get.to(() => ShopOrderDetailPage(order: order)),
              trailing: order.status == PartnerOrderStatus.pending
                  ? Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => controller.rejectOrder(order.id),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                            ),
                            child: MyText(
                              'رفض',
                              fontSize: 12.sp,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => controller.acceptOrder(order.id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                            ),
                            child: MyText(
                              'قبول',
                              fontSize: 12.sp,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    )
                  : null,
            );
          },
        );
      }),
    );
  }
}
