import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../model/brand_model.dart';
import '../../utils/app_colors.dart';
import '../my_text.dart';

class BrandCardWidget extends StatelessWidget {
  final BrandModel brand;
  final VoidCallback onTap;

  const BrandCardWidget({
    super.key,
    required this.brand,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 6.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.r),
                  child: Image.asset(
                    brand.logoAsset,
                    width: 44.w,
                    height: 44.w,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.medical_services_outlined,
                      size: 32.sp,
                      color: AppColors.productStore,
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                MyText(
                  brand.name,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.productTitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
