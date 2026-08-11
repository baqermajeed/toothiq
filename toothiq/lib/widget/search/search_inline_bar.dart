import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../utils/app_colors.dart';

/// شريط البحث مع زر الفلتر داخل الحقل — مطابق لتصميم صفحات البحث.
class SearchInlineBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final VoidCallback? onFilterTap;
  final ValueChanged<String>? onSubmitted;

  const SearchInlineBar({
    super.key,
    required this.controller,
    this.focusNode,
    required this.hintText,
    this.onFilterTap,
    this.onSubmitted,
  });

  static const double _barHeight = 48;

  @override
  Widget build(BuildContext context) {
    final radius = Radius.circular(14.r);
    final filterRadius = BorderRadiusDirectional.only(
      topEnd: radius,
      bottomEnd: radius,
    );
    final resolvedFilterRadius =
        filterRadius.resolve(Directionality.of(context));

    return Container(
      height: _barHeight.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.searchBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textAlign: TextAlign.right,
              textInputAction: TextInputAction.search,
              onSubmitted: onSubmitted,
              style: TextStyle(
                fontFamily: 'Expo Arabic',
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  fontFamily: 'Expo Arabic',
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8.w,
                  vertical: 12.h,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColors.textPrimary,
                  size: 22.sp,
                ),
              ),
            ),
          ),
          Material(
            color: AppColors.productStore,
            borderRadius: resolvedFilterRadius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onFilterTap,
              borderRadius: resolvedFilterRadius,
              child: SizedBox(
                width: _barHeight.h,
                height: _barHeight.h,
                child: Icon(
                  Icons.tune_rounded,
                  color: Colors.white,
                  size: 22.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
