import 'dart:ui';

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
  final double? height;
  final EdgeInsetsGeometry? padding;
  final bool centerTextVertically;
  final bool frosted;

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
    this.height,
    this.padding,
    this.centerTextVertically = false,
    this.frosted = false,
  });

  @override
  Widget build(BuildContext context) {
    const designShadow = Color(0x61659AB9); // 38%
    const filterColor = Color(0xFF16929E);
    final barHeight = height ?? 53.72.h;
    final radius = BorderRadius.circular(21.89.r);
    final fieldRow = Row(
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
                  height: barHeight,
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
              textAlignVertical: centerTextVertically
                  ? TextAlignVertical.center
                  : null,
              textInputAction: TextInputAction.search,
              onSubmitted: onSubmitted,
              style: TextStyle(
                fontFamily: 'Expo Arabic',
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: frosted ? Colors.white : AppColors.textPrimary,
                height: centerTextVertically ? 1 : null,
              ),
              decoration: InputDecoration(
                isDense: centerTextVertically,
                hintText: hintText,
                hintStyle: TextStyle(
                  fontFamily: 'Expo Arabic',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: frosted
                      ? Colors.white.withValues(alpha: 0.82)
                      : AppColors.textSecondary,
                  height: centerTextVertically ? 1 : null,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 15.92.w,
                  vertical: centerTextVertically ? 0 : 14.h,
                ),
                prefixIconConstraints: centerTextVertically
                    ? BoxConstraints(
                        minWidth: 43.w,
                        minHeight: 22.w,
                      )
                    : null,
                prefixIcon: Padding(
                  padding: EdgeInsetsDirectional.only(start: 15.w, end: 6.w),
                  child: SizedBox(
                    width: 22.w,
                    height: 22.w,
                    child: frosted
                        ? ColorFiltered(
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                            child: Image.asset(
                              _searchIconAsset,
                              fit: BoxFit.contain,
                            ),
                          )
                        : Image.asset(
                            _searchIconAsset,
                            fit: BoxFit.contain,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
    );

    final searchField = frosted
        ? ClipRRect(
            borderRadius: radius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                height: barHeight,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: radius,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.48),
                  ),
                ),
                child: fieldRow,
              ),
            ),
          )
        : Container(
            height: barHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: radius,
              border: Border.all(color: AppColors.searchBorder),
              boxShadow: const [
                BoxShadow(
                  color: designShadow,
                  blurRadius: 3.98,
                  offset: Offset(0, 0),
                ),
              ],
            ),
            child: fieldRow,
          );

    return Padding(
      padding: padding ?? EdgeInsets.symmetric(horizontal: 20.w),
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
