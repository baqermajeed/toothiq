import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../model/partner_order.dart';
import '../utils/app_colors.dart';
import 'my_text.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    this.onTap,
    this.trailing,
  });

  final PartnerOrder order;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: MyText(
                    'طلب #${order.orderNumber}',
                    fontSize: 15.sp,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: order.status.backgroundColor,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: MyText(
                    order.status.label,
                    fontSize: 11.sp,
                    color: order.status.textColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            MyText(
              order.customerName,
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 4.h),
            MyText(
              '${order.itemCount} منتجات · ${order.formattedTotal}',
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
            if (trailing != null) ...[
              SizedBox(height: 12.h),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
