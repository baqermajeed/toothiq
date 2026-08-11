import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../utils/app_colors.dart';

/// شريط البحث في صفحة النتائج — فلتر خارج الحقل + إلغاء.
class SearchResultsBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final VoidCallback onFilterTap;
  final VoidCallback onCancel;
  final ValueChanged<String>? onSubmitted;
  final Widget? subtitle;

  const SearchResultsBar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onFilterTap,
    required this.onCancel,
    this.onSubmitted,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: _buildSearchField()),
            SizedBox(width: 10.w),
            _buildFilterButton(),
            SizedBox(width: 12.w),
            _buildCancelButton(),
          ],
        ),
        if (subtitle != null) ...[
          SizedBox(height: 16.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: subtitle!,
                ),
              ),
              SizedBox(width: 10.w),
              SizedBox(width: 48.w),
              SizedBox(width: 12.w),
              Opacity(
                opacity: 0,
                child: IgnorePointer(child: _buildCancelButton()),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 48.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.searchBorder),
      ),
      child: TextField(
        controller: controller,
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
            horizontal: 14.w,
            vertical: 12.h,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.textPrimary,
            size: 22.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton() {
    return Material(
      color: AppColors.productStore,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onFilterTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 48.w,
          height: 48.w,
          child: Icon(
            Icons.tune_rounded,
            color: Colors.white,
            size: 24.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return GestureDetector(
      onTap: onCancel,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Text(
          'الغاء',
          style: TextStyle(
            fontFamily: 'Expo Arabic',
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
