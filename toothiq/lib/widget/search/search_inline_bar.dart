import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../utils/app_colors.dart';

/// شريط البحث مع زر الفلتر داخل الحقل — مطابق للصفحة الرئيسية.
class SearchInlineBar extends StatelessWidget {
  static const String _filterIconAsset =
      'assets/images/icon/Frame 427321661.png';
  static const String _searchIconAsset =
      'assets/images/icon/Frame 427321662.png';

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

  @override
  Widget build(BuildContext context) {
    const designShadow = Color(0x61659AB9);
    const filterColor = Color(0xFF16929E);

    return Container(
      height: 53.72.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21.89.r),
        border: Border.all(color: AppColors.searchBorder),
        boxShadow: const [
          BoxShadow(
            color: designShadow,
            blurRadius: 3.98,
            offset: Offset(0, 0),
          ),
        ],
      ),
      child: Row(
        textDirection: TextDirection.ltr,
        children: [
          Material(
            color: filterColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(21.89.r),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onFilterTap,
              customBorder: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(21.89.r),
              ),
              child: SizedBox(
                width: 48.75.w,
                height: 53.72.h,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    10.94.w,
                    13.93.h,
                    11.94.w,
                    13.93.h,
                  ),
                  child: Image.asset(
                    _filterIconAsset,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textAlign: TextAlign.right,
              textInputAction: TextInputAction.search,
              onSubmitted: onSubmitted,
              style: TextStyle(
                fontFamily: 'Expo Arabic',
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  fontFamily: 'Expo Arabic',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 15.92.w,
                  vertical: 14.h,
                ),
                prefixIcon: Padding(
                  padding: EdgeInsetsDirectional.only(start: 15.w, end: 6.w),
                  child: SizedBox(
                    width: 22.w,
                    height: 22.w,
                    child: Image.asset(
                      _searchIconAsset,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
