import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controller/orders_controller.dart';
import '../../utils/app_colors.dart';
import '../../widget/main_app_bar.dart';
import '../../widget/orders/order_card_widget.dart';
import '../../widget/search_filter_row.dart';
import 'order_detail_page.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = Get.find<OrdersController>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.ordersPageBackground,
        appBar: const MainAppBar(title: 'طلباتك'),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 8.h),
            SearchFilterRow(
              controller: orders.searchController,
              hintText: 'أبحث عن طلب ..',
              onFilterTap: orders.onFilterTap,
              filterCircular: true,
            ),
            SizedBox(height: 14.h),
            Expanded(
              child: Obx(() {
                final count = orders.filteredOrders.length;
                if (count == 0) {
                  return Center(
                    child: Text(
                      'لا توجد طلبات',
                      style: TextStyle(
                        fontFamily: 'Expo Arabic',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                  itemCount: count,
                  separatorBuilder: (context, index) => SizedBox(height: 16.h),
                  itemBuilder: (context, index) {
                    final order = orders.filteredOrders[index];
                    return OrderCardWidget(
                      order: order,
                      onTap: () => OrderDetailPage.open(order),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
