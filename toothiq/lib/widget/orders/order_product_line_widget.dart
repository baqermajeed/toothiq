import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../model/order_line_item_model.dart';
import '../../utils/app_colors.dart';
import '../app_image.dart';

class OrderProductLineWidget extends StatelessWidget {
  final OrderLineItemModel item;

  const OrderProductLineWidget({super.key, required this.item});

  static const double _radius = 16;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _ProductInfoCard(item: item)),
          SizedBox(width: 10.w),
          _PricePill(price: item.formattedLineTotal),
        ],
      ),
    );
  }
}

class _ProductInfoCard extends StatelessWidget {
  final OrderLineItemModel item;

  const _ProductInfoCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(OrderProductLineWidget._radius.r),
        border: Border.all(color: AppColors.orderDetailCardBorder, width: 1),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: AppImage(
              source: item.imageAsset,
              width: 56.w,
              height: 56.w,
              fit: BoxFit.cover,
              errorIcon: Icons.medical_services_rounded,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  item.name,
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Expo Arabic',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'الكمية المطلوبة : ${item.quantity}',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'Expo Arabic',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.orderDetailQuantity,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PricePill extends StatelessWidget {
  final String price;

  const _PricePill({required this.price});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: 88.w),
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(OrderProductLineWidget._radius.r),
        border: Border.all(color: AppColors.orderDetailCardBorder, width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        price,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Expo Arabic',
          fontSize: 13.sp,
          fontWeight: FontWeight.w800,
          color: AppColors.orderDetailPriceGreen,
          height: 1.2,
        ),
      ),
    );
  }
}
