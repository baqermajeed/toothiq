import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../model/order_model.dart';
import '../../utils/app_colors.dart';
import '../my_text.dart';

class OrderStatusFilterPick {
  final OrderStatus? status;

  const OrderStatusFilterPick(this.status);

  static const clearAll = OrderStatusFilterPick(null);
}

class OrderStatusFilterSheet extends StatelessWidget {
  final OrderStatus? selectedStatus;

  const OrderStatusFilterSheet({
    super.key,
    this.selectedStatus,
  });

  static Future<OrderStatusFilterPick?> show({OrderStatus? selectedStatus}) {
    return Get.bottomSheet<OrderStatusFilterPick>(
      OrderStatusFilterSheet(selectedStatus: selectedStatus),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        ),
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.indicatorInactive,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 16.h),
            MyText(
              'فلترة حسب الحالة',
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 18.h),
            _FilterOption(
              label: 'الكل',
              isSelected: selectedStatus == null,
              onTap: () => Get.back(result: OrderStatusFilterPick.clearAll),
            ),
            ...OrderStatus.values.map(
              (status) => Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: _FilterOption(
                  label: status.label,
                  isSelected: selectedStatus == status,
                  statusColor: status.textColor,
                  statusBg: status.backgroundColor,
                  onTap: () => Get.back(result: OrderStatusFilterPick(status)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? statusColor;
  final Color? statusBg;
  final VoidCallback onTap;

  const _FilterOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.statusColor,
    this.statusBg,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.editProfileActionsBg : Colors.white,
      borderRadius: BorderRadius.circular(16.r),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isSelected
                  ? AppColors.editProfilePrimary
                  : AppColors.settingsCardBorder,
            ),
          ),
          child: Row(
            children: [
              if (statusBg != null && statusColor != null) ...[
                Container(
                  width: 10.w,
                  height: 10.w,
                  decoration: BoxDecoration(
                    color: statusBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: statusColor!, width: 1.5),
                  ),
                ),
                SizedBox(width: 10.w),
              ],
              Expanded(
                child: MyText(
                  label,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  textAlign: TextAlign.right,
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.editProfilePrimary,
                  size: 22.sp,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
