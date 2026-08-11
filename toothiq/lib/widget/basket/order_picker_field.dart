import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../utils/app_colors.dart';
import 'order_field_metrics.dart';

class OrderPickerField extends StatelessWidget {
  final String? value;
  final String hint;
  final IconData icon;
  final String? errorText;
  final VoidCallback? onTap;
  final Widget? trailing;

  const OrderPickerField({
    super.key,
    this.value,
    required this.hint,
    required this.icon,
    this.errorText,
    this.onTap,
    this.trailing,
  });

  bool get _hasError => OrderFieldMetrics.hasError(errorText);
  bool get _hasValue => (value ?? '').trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: OrderFieldMetrics.height,
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(OrderFieldMetrics.radius),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(OrderFieldMetrics.radius),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(OrderFieldMetrics.radius),
                  border: Border.all(
                    color: OrderFieldMetrics.borderColor(hasError: _hasError),
                    width: OrderFieldMetrics.borderWidthFor(hasError: _hasError),
                  ),
                ),
                child: Padding(
                  padding: OrderFieldMetrics.horizontalPadding,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        color: AppColors.textSecondary,
                        size: 20.sp,
                      ),
                      SizedBox(width: OrderFieldMetrics.iconGap),
                      Expanded(
                        child: Text(
                          _hasValue ? value! : hint,
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Expo Arabic',
                            fontSize: 15.sp,
                            fontWeight:
                                _hasValue ? FontWeight.w600 : FontWeight.w500,
                            color: _hasValue
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            height: 1.0,
                          ),
                        ),
                      ),
                      if (trailing != null) ...[
                        SizedBox(width: OrderFieldMetrics.iconGap),
                        trailing!,
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_hasError) ...[
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.info_outline, size: 16.sp, color: AppColors.error),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  errorText!,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'Expo Arabic',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
