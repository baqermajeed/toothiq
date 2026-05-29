import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../utils/app_colors.dart';

class SearchFilterRow extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final VoidCallback? onFilterTap;
  final bool filterCircular;

  const SearchFilterRow({
    super.key,
    required this.controller,
    required this.hintText,
    this.onFilterTap,
    this.filterCircular = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: AppColors.searchBorder),
              ),
              child: TextField(
                controller: controller,
                textAlign: TextAlign.right,
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
                    horizontal: 14.w,
                    vertical: 12.h,
                  ),
                  suffixIcon: Icon(
                    Icons.search,
                    color: AppColors.textPrimary,
                    size: 22.sp,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Material(
            color: AppColors.primary,
            shape: filterCircular
                ? const CircleBorder()
                : RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
            child: InkWell(
              onTap: onFilterTap,
              customBorder: filterCircular
                  ? const CircleBorder()
                  : RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
              child: SizedBox(
                width: 48.w,
                height: 48.h,
                child: Icon(
                  Icons.tune_rounded,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
