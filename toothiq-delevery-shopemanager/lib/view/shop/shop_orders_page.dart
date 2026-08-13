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
      body: Column(
        children: [
          _StatusFilterBar(controller: controller),
          Expanded(
            child: Obx(() {
              final list = controller.filteredOrders;
              if (list.isEmpty) {
                return _EmptyOrders(
                  status: controller.selectedStatus.value,
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
                    onTap: () =>
                        Get.to(() => ShopOrderDetailPage(order: order)),
                    trailing: order.status == PartnerOrderStatus.pending
                        ? Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () =>
                                      controller.rejectOrder(order.id),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.error,
                                    side: const BorderSide(
                                      color: AppColors.error,
                                    ),
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
                                  onPressed: () =>
                                      controller.acceptOrder(order.id),
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
          ),
        ],
      ),
    );
  }
}

class _StatusFilterBar extends StatelessWidget {
  const _StatusFilterBar({required this.controller});

  final ShopOrdersController controller;

  static const _filters = <PartnerOrderStatus?>[
    null,
    PartnerOrderStatus.pending,
    PartnerOrderStatus.accepted,
    PartnerOrderStatus.preparing,
    PartnerOrderStatus.onTheWay,
    PartnerOrderStatus.delivered,
    PartnerOrderStatus.canceled,
    PartnerOrderStatus.postponed,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.surface,
      child: Column(
        children: [
          SizedBox(
            height: 52.h,
            child: Obx(() {
              final selected = controller.selectedStatus.value;
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                itemCount: _filters.length,
                separatorBuilder: (context, index) => SizedBox(width: 8.w),
                itemBuilder: (context, index) {
                  final status = _filters[index];
                  final isSelected = selected == status;
                  final count = controller.countFor(status);
                  return _StatusChip(
                    label: status?.label ?? 'الكل',
                    count: count,
                    selected: isSelected,
                    backgroundColor: status?.backgroundColor ??
                        AppColors.primaryLight,
                    textColor: status?.textColor ?? AppColors.primary,
                    onTap: () => controller.selectStatus(status),
                  );
                },
              );
            }),
          ),
          Container(height: 1, color: AppColors.cardBorder),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: selected ? backgroundColor : AppColors.pageBackground,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: selected ? textColor.withValues(alpha: 0.35) : AppColors.cardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MyText(
              label,
              fontSize: 12.sp,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? textColor : AppColors.textSecondary,
            ),
            if (count > 0) ...[
              SizedBox(width: 6.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: selected
                      ? textColor.withValues(alpha: 0.12)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: MyText(
                  '$count',
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                  color: selected ? textColor : AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders({this.status});

  final PartnerOrderStatus? status;

  @override
  Widget build(BuildContext context) {
    final message = status == null
        ? 'لا توجد طلبات'
        : 'لا توجد طلبات بحالة «${status!.label}»';

    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72.w,
              height: 72.w,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 34.sp,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 16.h),
            MyText(
              message,
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
