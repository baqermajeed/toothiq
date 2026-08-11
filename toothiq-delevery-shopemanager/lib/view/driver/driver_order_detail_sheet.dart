import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../model/partner_order.dart';
import '../../utils/app_colors.dart';
import '../../widget/my_text.dart';
import 'driver_order_map_page.dart';

class DriverOrderDetailSheet extends StatelessWidget {
  const DriverOrderDetailSheet({super.key, required this.order});

  final PartnerOrder order;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: 0.85.sh),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 10.h),
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
            child: Row(
              children: [
                Expanded(
                  child: MyText(
                    'تفاصيل الطلب #${order.orderNumber}',
                    fontSize: 17.sp,
                  ),
                ),
                IconButton(
                  onPressed: Get.back,
                  icon: Icon(Icons.close, size: 22.sp),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 24.h),
              shrinkWrap: true,
              children: [
                _InfoTile(
                  icon: Icons.storefront_outlined,
                  title: 'المتجر',
                  value: order.shopName,
                ),
                _InfoTile(
                  icon: Icons.location_on_outlined,
                  title: 'عنوان المتجر',
                  value: order.shopAddress,
                ),
                _InfoTile(
                  icon: Icons.person_outline,
                  title: 'الزبون',
                  value: order.customerName,
                ),
                _InfoTile(
                  icon: Icons.phone_outlined,
                  title: 'هاتف الزبون',
                  value: order.customerPhone,
                ),
                _InfoTile(
                  icon: Icons.home_outlined,
                  title: 'عنوان التوصيل',
                  value: order.customerAddress,
                ),
                SizedBox(height: 12.h),
                MyText('المنتجات', fontSize: 14.sp),
                SizedBox(height: 8.h),
                ...order.items.map(
                  (item) => Container(
                    margin: EdgeInsets.only(bottom: 8.h),
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.pageBackground,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: MyText(
                            item.name,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        MyText(
                          '${item.quantity} × ${_formatPrice(item.price)}',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      MyText('الإجمالي', fontSize: 14.sp),
                      MyText(
                        order.formattedTotal,
                        fontSize: 15.sp,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                ElevatedButton.icon(
                  onPressed: () {
                    Get.back();
                    Get.to(() => DriverOrderMapPage(order: order));
                  },
                  icon: const Icon(Icons.map_outlined),
                  label: MyText(
                    'عرض الخريطة والمسار',
                    fontSize: 14.sp,
                    color: Colors.white,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 48.h),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20.sp, color: AppColors.primary),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(
                  title,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
                SizedBox(height: 2.h),
                MyText(value, fontSize: 13.sp, fontWeight: FontWeight.w500),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
