import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controller/driver_orders_controller.dart';
import '../../controller/main_tab_controller.dart';
import '../../model/partner_order.dart';
import '../../utils/app_colors.dart';
import '../../widget/driver/driver_order_card.dart';
import '../../widget/my_text.dart';
import 'driver_order_detail_sheet.dart';
import 'driver_order_map_page.dart';

class DriverOrdersPage extends StatelessWidget {
  const DriverOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DriverOrdersController>();
    final tabs = Get.find<MainTabController>(tag: 'driver');

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: MyText('لوحة السائق', fontSize: 18.sp),
        leading: IconButton(
          onPressed: () => tabs.changeTab(2),
          icon: Icon(Icons.settings_outlined, size: 24.sp),
          tooltip: 'الإعدادات',
        ),
        actions: [
          Obx(() {
            if (!controller.isSharingLocation.value) {
              return SizedBox(width: 8.w);
            }
            return Padding(
              padding: EdgeInsets.only(left: 12.w),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.orderStatusDeliveredBg,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.gps_fixed,
                      size: 14.sp,
                      color: AppColors.orderStatusDeliveredText,
                    ),
                    SizedBox(width: 4.w),
                    MyText(
                      'مشاركة الموقع',
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.orderStatusDeliveredText,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
      body: Column(
        children: [
          _StageTabBar(controller: controller),
          Expanded(
            child: Obx(() {
              final list = controller.currentTabOrders;
              if (list.isEmpty) {
                return _EmptyState(tab: controller.selectedTab.value);
              }

              return ListView.separated(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
                itemCount: list.length,
                separatorBuilder: (context, index) => SizedBox(height: 14.h),
                itemBuilder: (context, index) {
                  final order = list[index];
                  return DriverOrderCard(
                    order: order,
                    tab: controller.selectedTab.value,
                    isPickedUp: controller.isPickedUp(order.id),
                    onAccept: () async {
                      await controller.acceptOrder(order.id);
                      Get.snackbar('تم', 'تم قبول الطلب بنجاح');
                    },
                    onPickup: () async {
                      await controller.markPickedUp(order.id);
                      Get.snackbar('الاستلام', 'تم تأكيد استلام الطلب من المتجر');
                    },
                    onDeliver: () async {
                      await controller.completeDelivery(order.id);
                      Get.snackbar('تم', 'تم تسليم الطلب بنجاح');
                    },
                    onDetails: () => showDriverOrderDetailSheet(order),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _StageTabBar extends StatelessWidget {
  const _StageTabBar({required this.controller});

  final DriverOrdersController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          Obx(
            () => Row(
              children: [
                _TabItem(
                  label: 'قيد الانتظار',
                  count: controller.countForTab(DriverOrderTab.pending),
                  selected: controller.selectedTab.value == DriverOrderTab.pending,
                  onTap: () => controller.changeTab(DriverOrderTab.pending),
                ),
                _TabItem(
                  label: 'قيد التنفيذ',
                  count: controller.countForTab(DriverOrderTab.inProgress),
                  selected:
                      controller.selectedTab.value == DriverOrderTab.inProgress,
                  onTap: () => controller.changeTab(DriverOrderTab.inProgress),
                ),
                _TabItem(
                  label: 'المنتهية',
                  count: controller.countForTab(DriverOrderTab.finished),
                  selected: controller.selectedTab.value == DriverOrderTab.finished,
                  onTap: () => controller.changeTab(DriverOrderTab.finished),
                ),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.cardBorder),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 14.h),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? AppColors.primary : Colors.transparent,
                width: 3.h,
              ),
            ),
          ),
          child: Column(
            children: [
              MyText(
                label,
                fontSize: 13.sp,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
              if (count > 0) ...[
                SizedBox(height: 4.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primaryLight
                        : AppColors.pageBackground,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: MyText(
                    '$count',
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: selected ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.tab});

  final DriverOrderTab tab;

  String get _message {
    switch (tab) {
      case DriverOrderTab.pending:
        return 'لا توجد طلبات واردة حالياً';
      case DriverOrderTab.inProgress:
        return 'لا توجد طلبات قيد التنفيذ';
      case DriverOrderTab.finished:
        return 'لا توجد طلبات منتهية';
    }
  }

  IconData get _icon {
    switch (tab) {
      case DriverOrderTab.pending:
        return Icons.inbox_outlined;
      case DriverOrderTab.inProgress:
        return Icons.local_shipping_outlined;
      case DriverOrderTab.finished:
        return Icons.task_alt_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72.w,
              height: 72.w,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(_icon, size: 34.sp, color: AppColors.primary),
            ),
            SizedBox(height: 16.h),
            MyText(
              _message,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

void showDriverOrderDetailSheet(PartnerOrder order) {
  Get.bottomSheet(
    DriverOrderDetailSheet(order: order),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

void openDriverOrderMap(PartnerOrder order) {
  Get.to(() => DriverOrderMapPage(order: order));
}
