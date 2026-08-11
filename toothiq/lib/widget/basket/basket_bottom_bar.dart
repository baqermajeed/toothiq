import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../utils/app_colors.dart';
import '../my_text.dart';

class BasketBottomBar extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isLoading;

  const BasketBottomBar({
    super.key,
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  static const double _topRadius = 32;
  static const double _buttonHeight = 54;

  @override
  Widget build(BuildContext context) {
    final topRadius = Radius.circular(_topRadius.r);

    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: topRadius,
        topRight: topRadius,
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.bottomNavBackground,
          borderRadius: BorderRadius.only(
            topLeft: topRadius,
            topRight: topRadius,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 18.h),
            child: SizedBox(
              width: double.infinity,
              height: _buttonHeight.h,
              child: Material(
                color: Colors.white,
                elevation: 0,
                borderRadius: BorderRadius.circular(_buttonHeight.h / 2),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: isLoading ? null : onTap,
                  borderRadius: BorderRadius.circular(_buttonHeight.h / 2),
                  child: Center(
                    child: isLoading
                        ? SizedBox(
                            width: 24.w,
                            height: 24.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.productTitle,
                            ),
                          )
                        : MyText(
                            label,
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.productTitle,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
