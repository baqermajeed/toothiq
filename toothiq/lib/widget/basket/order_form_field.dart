import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../utils/app_colors.dart';
import 'order_field_metrics.dart';

/// حقل نصي لصفحة طلب منتج — مقاسات Figma
class OrderFormField extends StatelessWidget {
  final TextEditingController? controller;
  final String hint;
  final IconData icon;
  final String? errorText;
  final TextInputType keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? trailing;
  final ValueChanged<String>? onChanged;

  const OrderFormField({
    super.key,
    this.controller,
    required this.hint,
    required this.icon,
    this.errorText,
    this.keyboardType = TextInputType.text,
    this.readOnly = false,
    this.onTap,
    this.trailing,
    this.onChanged,
  });

  bool get _hasError => OrderFieldMetrics.hasError(errorText);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: OrderFieldMetrics.height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
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
                    child: TextField(
                      controller: controller,
                      readOnly: readOnly,
                      onTap: onTap,
                      onChanged: onChanged,
                      keyboardType: keyboardType,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: 'Expo Arabic',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.0,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        isCollapsed: true,
                        hintText: hint,
                        hintStyle: TextStyle(
                          fontFamily: 'Expo Arabic',
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                          height: 1.0,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
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
        if (_hasError) ...[
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(
                Icons.info_outline,
                size: 16.sp,
                color: AppColors.error,
              ),
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
