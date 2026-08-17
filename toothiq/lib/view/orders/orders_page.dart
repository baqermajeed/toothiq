import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controller/orders_controller.dart';
import '../../utils/app_colors.dart';
import '../../widget/app_bottom_navigation.dart';
import '../../widget/common/async_state_widgets.dart';
import '../../widget/common/skeleton.dart';
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
    final topInset =
        MediaQuery.paddingOf(context).top + MainAppBar.toolbarHeight();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.ordersPageBackground,
        extendBodyBehindAppBar: true,
        appBar: const MainAppBar(title: 'طلباتك'),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: topInset + 8.h),
            SearchFilterRow(
              controller: orders.searchController,
              hintText: 'أبحث عن طلب ..',
              onFilterTap: orders.onFilterTap,
            ),
            SizedBox(height: 14.h),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: orders.refresh,
                child: Obx(() {
                  final count = orders.filteredOrders.length;
                  if (count == 0) {
                    if (orders.isLoading.value) {
                      return const OrdersListSkeleton();
                    }
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return ListView(
                          controller: orders.scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            16.w,
                            0,
                            16.w,
                            AppBottomNavMetrics.contentBottomPadding(context),
                          ),
                          children: [
                            SizedBox(
                              height: constraints.maxHeight * 0.55,
                              child: orders.loadError.value != null
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
                    padding: EdgeInsets.fromLTRB(
                      16.w,
                      0,
                      16.w,
                      AppBottomNavMetrics.contentBottomPadding(context),
                    ),
                    itemCount: count + (orders.loadingMore.value ? 1 : 0),
                    separatorBuilder: (context, index) =>
                        SizedBox(height: 10.h),
                    itemBuilder: (context, index) {
                      if (index >= count) {
                        return AppShimmer(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 4.h),
                            child: const OrderCardSkeleton(),
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
