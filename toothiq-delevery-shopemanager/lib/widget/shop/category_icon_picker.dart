import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/category_preset_icons.dart';
import '../../utils/app_colors.dart';
import '../my_text.dart';

class CategoryIconPicker extends StatelessWidget {
  const CategoryIconPicker({
    super.key,
    required this.selectedAssetPath,
    required this.onSelected,
    this.errorText,
  });

  final String? selectedAssetPath;
  final ValueChanged<String> onSelected;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MyText(
          'أيقونة القسم *',
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
        ),
        SizedBox(height: 8.h),
        if (selectedAssetPath != null) ...[
          Center(
            child: Container(
              width: 72.w,
              height: 72.w,
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: Image.asset(selectedAssetPath!, fit: BoxFit.contain),
            ),
          ),
          SizedBox(height: 10.h),
        ],
        Container(
          constraints: BoxConstraints(maxHeight: 220.h),
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: errorText != null ? AppColors.error : AppColors.cardBorder,
            ),
          ),
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 8.h,
              crossAxisSpacing: 8.w,
            ),
            itemCount: CategoryPresetIcons.assetPaths.length,
            itemBuilder: (context, index) {
              final assetPath = CategoryPresetIcons.assetPaths[index];
              final selected = selectedAssetPath == assetPath;
              return InkWell(
                onTap: () => onSelected(assetPath),
                borderRadius: BorderRadius.circular(12.r),
                child: Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.cardBorder,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Image.asset(assetPath, fit: BoxFit.contain),
                ),
              );
            },
          ),
        ),
        if (errorText != null) ...[
          SizedBox(height: 6.h),
          MyText(
            errorText!,
            fontSize: 11.sp,
            color: AppColors.error,
          ),
        ],
      ],
    );
  }
}
