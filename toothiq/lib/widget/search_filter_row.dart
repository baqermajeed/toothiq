import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../utils/app_colors.dart';

class SearchFilterRow extends StatelessWidget {
  static const String _filterIconAsset =
      'assets/images/icon/Frame 427321661.png';
  static const String _searchIconAsset =
      'assets/images/icon/Frame 427321662.png';

  final TextEditingController controller;
  final String hintText;
  final VoidCallback? onFilterTap;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final bool filterCircular;
  final bool readOnly;
  final bool showFilter;

  const SearchFilterRow({
    super.key,
    required this.controller,
    required this.hintText,
    this.onFilterTap,
    this.onSubmitted,
    this.onTap,
    this.filterCircular = false,
    this.readOnly = false,
    this.showFilter = true,
  });

  @override
  Widget build(BuildContext context) {
    const designShadow = Color(0x61659AB9); // 38%
    const filterColor = Color(0xFF16929E);
    final searchField = Container(
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
          if (showFilter)
            Material(
              color: filterColor,
              shape: filterCircular
                  ? const CircleBorder()
                  : RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(21.89.r),
                    ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onFilterTap,
                customBorder: filterCircular
                    ? const CircleBorder()
                    : RoundedRectangleBorder(
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
              readOnly: readOnly,
              showCursor: !readOnly,
              enableInteractiveSelection: !readOnly,
              onTap: readOnly
                  ? () {
                      onTap?.call();
                    }
                  : null,
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

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: readOnly
          ? GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: AbsorbPointer(child: searchField),
            )
          : searchField,
    );
  }
}
