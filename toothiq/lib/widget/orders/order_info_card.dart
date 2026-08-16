import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../utils/app_colors.dart';

class OrderInfoField {
  final String label;
  final String value;
  final bool highlightValue;
  final bool valueIsGreen;

  const OrderInfoField({
    required this.label,
    required this.value,
    this.highlightValue = false,
    this.valueIsGreen = false,
  });
}

class OrderInfoCard extends StatelessWidget {
  final List<OrderInfoField> fields;

  const OrderInfoCard({super.key, required this.fields});

  static const double _radius = 20;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_radius.r),
        border: Border.all(color: AppColors.orderDetailCardBorder, width: 1),
      ),
      child: Column(
        children: [
          for (var i = 0; i < fields.length; i++) ...[
            if (i > 0) SizedBox(height: 6.h),
            _OrderInfoFieldRow(field: fields[i]),
          ],
        ],
      ),
    );
  }
}

class _OrderInfoFieldRow extends StatelessWidget {
  final OrderInfoField field;

  const _OrderInfoFieldRow({required this.field});

  @override
  Widget build(BuildContext context) {
    final valueColor = field.valueIsGreen
        ? AppColors.orderDetailPriceGreen
        : AppColors.textPrimary;
    final valueWeight =
        field.highlightValue ? FontWeight.w800 : FontWeight.w700;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            field.label,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'Expo Arabic',
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.orderDetailLabel,
              height: 1.2,
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Flexible(
          child: Text(
            field.value,
            textAlign: TextAlign.left,
            style: TextStyle(
              fontFamily: 'Expo Arabic',
              fontSize: field.highlightValue ? 15.sp : 14.sp,
              fontWeight: valueWeight,
              color: valueColor,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}
