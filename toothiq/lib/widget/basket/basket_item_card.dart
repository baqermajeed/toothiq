import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../model/cart_item_model.dart';
import '../../utils/app_colors.dart';

class BasketItemCard extends StatelessWidget {
  final CartItemModel item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const BasketItemCard({
    super.key,
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.settingsCardBorder, width: 1),
      ),
      padding: EdgeInsets.all(12.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  item.product.name,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Expo Arabic',
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  item.product.storeName,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Expo Arabic',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.productStore,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 12.h),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    children: [
                      _QtyCircleButton(
                        icon: Icons.add,
                        color: AppColors.productStore,
                        iconColor: Colors.white,
                        onTap: onIncrement,
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        child: Text(
                          '${item.quantity}',
                          style: TextStyle(
                            fontFamily: 'Expo Arabic',
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      _QtyCircleButton(
                        icon: Icons.remove,
                        color: AppColors.indicatorInactive,
                        iconColor: AppColors.textPrimary,
                        onTap: onDecrement,
                      ),
                      const Spacer(),
                      Text(
                        'السعر : ${item.product.formattedPrice}',
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontFamily: 'Expo Arabic',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: Image.asset(
              item.product.imageAsset,
              width: 72.w,
              height: 72.w,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 72.w,
                height: 72.w,
                color: AppColors.cardPlaceholder,
                child: Icon(
                  Icons.medical_services_rounded,
                  color: AppColors.productStore,
                  size: 28.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyCircleButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _QtyCircleButton({
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 32.w,
          height: 32.w,
          child: Icon(icon, color: iconColor, size: 18.sp),
        ),
      ),
    );
  }
}
