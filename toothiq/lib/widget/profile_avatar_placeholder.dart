import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../utils/app_colors.dart';

class ProfileAvatarPlaceholder extends StatelessWidget {
  final VoidCallback? onTap;

  const ProfileAvatarPlaceholder({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120.w,
        height: 120.w,
        decoration: const BoxDecoration(
          color: AppColors.cardPlaceholder,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.camera_alt_outlined,
          size: 36.sp,
          color: AppColors.textLight,
        ),
      ),
    );
  }
}
