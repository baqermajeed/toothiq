import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controller/orders_controller.dart';
import '../../utils/app_colors.dart';
import '../../widget/common/async_state_widgets.dart';
import '../../widget/main_app_bar.dart';
import '../../widget/orders/order_card_widget.dart';
import '../../widget/search_filter_row.dart';
import 'order_detail_page.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<OrdersController>()) {
      Get.put(OrdersController(), permanent: true);
    }
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
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: orders.refresh,
                child: Obx(() {
                  final count = orders.filteredOrders.length;
                  if (count == 0) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return ListView(
                          controller: orders.scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                          children: [
                            SizedBox(
                              height: constraints.maxHeight * 0.55,
                              child: orders.isLoading.value
                                  ? const AppLoadingState()
                                  : orders.loadError.value != null
                                  ? AppErrorState(
                                      message: orders.loadError.value!,
                                      onRetry: () => orders.refresh(),
                                    )
                                  : const AppEmptyState(title: 'لا توجد طلبات'),
                            ),
                          ],
                        );
                      },
                    );
                  }

                  return ListView.separated(
                    controller: orders.scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                    itemCount: count + (orders.loadingMore.value ? 1 : 0),
                    separatorBuilder: (context, index) =>
                        SizedBox(height: 16.h),
                    itemBuilder: (context, index) {
                      if (index >= count) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      }
                      final order = orders.filteredOrders[index];
                      return OrderCardWidget(
                        order: order,
                        onTap: () => OrderDetailPage.open(order),
                      );
                    },
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
