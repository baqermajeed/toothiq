import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../model/home_feed_tab.dart';
import '../../utils/app_colors.dart';
import '../my_text.dart';

class HomeFeedChips extends StatelessWidget {
  const HomeFeedChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final HomeFeedTab selected;
  final ValueChanged<HomeFeedTab> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: HomeFeedTab.values.length,
        separatorBuilder: (_, _) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          final tab = HomeFeedTab.values[index];
          final isSelected = tab == selected;
          return GestureDetector(
            onTap: () => onSelected(tab),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22.r),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.cardBorder,
                  width: isSelected ? 1.6 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (tab == HomeFeedTab.offers) ...[
                    Icon(
                      Icons.percent_rounded,
                      size: 14.sp,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    ),
                    SizedBox(width: 4.w),
                  ],
                  MyText(
                    tab.label,
                    fontSize: 13.sp,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
