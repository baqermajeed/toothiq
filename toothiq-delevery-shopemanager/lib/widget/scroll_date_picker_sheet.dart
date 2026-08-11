import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../utils/app_colors.dart';
import 'my_text.dart';

class ScrollDatePickerSheet {
  static Future<DateTime?> show({
    required BuildContext context,
    required String title,
    DateTime? initialDate,
    DateTime? minimumDate,
    DateTime? maximumDate,
    CupertinoDatePickerMode mode = CupertinoDatePickerMode.date,
  }) {
    final now = DateTime.now();
    final min = minimumDate ?? now;
    final max = maximumDate ?? DateTime(now.year + 20);
    var selected = initialDate ?? now;
    if (selected.isBefore(min)) selected = min;
    if (selected.isAfter(max)) selected = max;

    return showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 8.h),
                    Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: AppColors.cardBorder,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(4.w, 8.h, 4.w, 0),
                      child: Row(
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            child: MyText(
                              'إلغاء',
                              fontSize: 14.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Expanded(
                            child: MyText(
                              title,
                              fontSize: 15.sp,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(sheetContext, selected),
                            child: MyText(
                              'تأكيد',
                              fontSize: 14.sp,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 230.h,
                      child: CupertinoTheme(
                        data: CupertinoThemeData(
                          textTheme: CupertinoTextThemeData(
                            dateTimePickerTextStyle: TextStyle(
                              fontFamily: 'Expo Arabic',
                              fontSize: 20.sp,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        child: CupertinoDatePicker(
                          mode: mode,
                          initialDateTime: selected,
                          minimumDate: min,
                          maximumDate: max,
                          onDateTimeChanged: (date) {
                            selected = date;
                            setModalState(() {});
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
