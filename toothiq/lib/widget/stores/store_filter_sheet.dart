import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../utils/app_colors.dart';
import '../my_text.dart';
import '../primary_button.dart';

class StoreFilterPick {
  final double? minRating;

  const StoreFilterPick(this.minRating);
}

class StoreFilterSheet extends StatelessWidget {
  final double? selectedRating;

  const StoreFilterSheet({
    super.key,
    this.selectedRating,
  });

  static Future<StoreFilterPick?> show({double? selectedRating}) {
    return Get.bottomSheet<StoreFilterPick>(
      StoreFilterSheet(selectedRating: selectedRating),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    var currentRating = selectedRating;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: StatefulBuilder(
        builder: (context, setState) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
            ),
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: AppColors.indicatorInactive,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  MyText(
                    'فلترة المتاجر',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 18.h),
                  MyText(
                    'الحد الأدنى للتقييم',
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.productTitle,
                    textAlign: TextAlign.right,
                  ),
                  SizedBox(height: 10.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: [
                      _ChoiceChip(
                        label: 'الكل',
                        isSelected: currentRating == null,
                        onTap: () => setState(() => currentRating = null),
                      ),
                      ...[3.0, 4.0, 4.5].map(
                        (rating) => _ChoiceChip(
                          label: '$rating+',
                          isSelected: currentRating == rating,
                          onTap: () => setState(() => currentRating = rating),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  PrimaryButton(
                    label: 'تطبيق الفلتر',
                    onPressed: () =>
                        Get.back(result: StoreFilterPick(currentRating)),
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

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChoiceChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.editProfileActionsBg : Colors.white,
      borderRadius: BorderRadius.circular(14.r),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: isSelected
                  ? AppColors.editProfilePrimary
                  : AppColors.settingsCardBorder,
            ),
          ),
          child: MyText(
            label,
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: isSelected
                ? AppColors.editProfilePrimary
                : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
