import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../utils/app_colors.dart';
import '../my_text.dart';

class CategoryChipWidget extends StatelessWidget {
  static const Color _chipBorderUnselected = Color(0x6616929E); // 40%
  static const Color _chipTextUnselected = Color(0x9916929E); // 60%

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChipWidget({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 41.89.h,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 22.w : 10.w,
        ),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(21.94.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : _chipBorderUnselected,
            width: isSelected ? 0 : 1,
          ),
        ),
        child: MyText(
          label,
          fontSize: 13.96.sp,
          fontWeight: FontWeight.w700,
          color: isSelected ? Colors.white : _chipTextUnselected,
          textAlign: TextAlign.center,
          height: 1.5,
        ),
      ),
    );
  }
}
