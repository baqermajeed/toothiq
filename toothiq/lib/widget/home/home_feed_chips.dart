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
        clipBehavior: Clip.none,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: HomeFeedTab.values.length,
        separatorBuilder: (_, _) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          final tab = HomeFeedTab.values[index];
          final isSelected = tab == selected;
          return GestureDetector(
            onTap: () => onSelected(tab),
            child: Container(
              padding: EdgeInsetsDirectional.only(
                start: 16.w,
                end: 14.w,
                top: 5.h,
                bottom: 5.h,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.cardBorder,
                  width: isSelected ? 1.6 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                textDirection: TextDirection.rtl,
                children: [
                  MyText(
                    tab.label,
                    fontSize: 13.sp,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                  SizedBox(width: 6.w),
                  Image.asset(
                    tab.iconAsset,
                    width: tab == HomeFeedTab.all ? 20.w : 24.w,
                    height: tab == HomeFeedTab.all ? 20.w : 24.w,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.image_outlined,
                        size: 18.sp,
                        color: AppColors.textSecondary,
                      );
                    },
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
