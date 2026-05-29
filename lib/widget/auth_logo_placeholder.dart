import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../utils/app_colors.dart';

class AuthLogoPlaceholder extends StatelessWidget {
  final double size;

  const AuthLogoPlaceholder({super.key, this.size = 140});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.w,
      height: size.w,
      decoration: const BoxDecoration(
        color: AppColors.cardPlaceholder,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.medical_services_outlined,
        size: (size * 0.35).sp,
        color: AppColors.textLight,
      ),
    );
  }
}
