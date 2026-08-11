import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../utils/app_colors.dart';

class OrderSectionTitle extends StatelessWidget {
  final String title;

  const OrderSectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Text(
        title,
        textAlign: TextAlign.right,
        style: TextStyle(
          fontFamily: 'Expo Arabic',
          fontSize: 15.sp,
          fontWeight: FontWeight.w800,
          color: AppColors.productTitle,
          height: 1.3,
        ),
      ),
    );
  }
}
