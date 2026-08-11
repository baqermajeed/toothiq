import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../model/delivery_address_model.dart';
import '../../utils/app_colors.dart';
import '../my_text.dart';

class SavedAddressCardWidget extends StatelessWidget {
  final DeliveryAddressModel address;
  final VoidCallback? onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SavedAddressCardWidget({
    super.key,
    required this.address,
    this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 14.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LocationIconBox(),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 4.w,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        MyText(
                          address.displayTitle,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.productTitle,
                        ),
                        if (address.isCurrent)
                          MyText(
                            '( العنوان الحالي )',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.productStore,
                          ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    MyText(
                      address.displaySubtitle,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              _AddressActionButton(
                backgroundColor: const Color(0xFFFFF3D6),
                iconAsset: 'assets/images/cart/edi.png',
                onTap: onEdit,
              ),
              SizedBox(width: 8.w),
              _AddressActionButton(
                backgroundColor: const Color(0xFFFFE8E8),
                iconAsset: 'assets/images/cart/del.png',
                onTap: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationIconBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44.w,
      height: 44.w,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Icon(
        Icons.location_on_rounded,
        size: 24.sp,
        color: AppColors.productStore,
      ),
    );
  }
}

class _AddressActionButton extends StatelessWidget {
  final Color backgroundColor;
  final String iconAsset;
  final VoidCallback onTap;

  const _AddressActionButton({
    required this.backgroundColor,
    required this.iconAsset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12.r),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 40.w,
          height: 40.w,
          child: Center(
            child: Image.asset(
              iconAsset,
              width: 20.w,
              height: 20.w,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
