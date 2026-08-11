import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'loading/shimmer_box.dart';

/// زر أساسي بتصميم موحد ومتجاوب.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.outlined = false,
    this.minHeight,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool outlined;
  final double? minHeight;

  @override
  Widget build(BuildContext context) {
    // final minH = minHeight ?? 56.h;
    if (outlined) {
      return SizedBox(
        width: double.infinity,
        // height: minH,
        child: OutlinedButton(
          onPressed: loading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryDark,
            side: const BorderSide(color: AppColors.primaryDark),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
          ),
          child: loading
              ? ShimmerBox(
                  width: 80.w,
                  height: 20.h,
                  borderRadius: BorderRadius.circular(6.r),
                )
              : Text(label, style: TextStyle(fontFamily: kFontFamilyCairo, fontSize: 16.sp)),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      // height: minH,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: AppColors.primaryLight,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
        child: loading
            ? ShimmerBox(
                width: 80.w,
                height: 20.h,
                borderRadius: BorderRadius.circular(6.r),
              )
            : Text(label, style: TextStyle(fontFamily: kFontFamilyCairo, fontSize: 16.sp)),
      ),
    );
  }
}
