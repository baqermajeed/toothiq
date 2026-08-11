import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/order.dart';

/// شارة حالة الطلب — قابلة لإعادة الاستخدام في قائمة الطلبات وشاشة التفاصيل.
class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({super.key, required this.status});

  final OrderStatus status;

  Color _backgroundColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (status) {
      case OrderStatus.pending:
        return isDark ? colorScheme.surfaceContainerHigh : AppColors.primaryBeige.withValues(alpha: 0.35);
      case OrderStatus.accepted:
      case OrderStatus.preparing:
        return isDark ? colorScheme.primaryContainer.withValues(alpha: 0.6) : AppColors.primaryLight.withValues(alpha: 0.8);
      case OrderStatus.onTheWay:
        return isDark ? colorScheme.primaryContainer : AppColors.primaryLight;
      case OrderStatus.delivered:
        return isDark ? colorScheme.tertiaryContainer.withValues(alpha: 0.5) : const Color(0xFFE8F5E9);
      case OrderStatus.canceled:
        return isDark ? colorScheme.errorContainer.withValues(alpha: 0.5) : AppColors.error.withValues(alpha: 0.12);
    }
  }

  Color _textColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (status) {
      case OrderStatus.pending:
        return isDark ? colorScheme.onSurfaceVariant : AppColors.primaryDark;
      case OrderStatus.accepted:
      case OrderStatus.preparing:
      case OrderStatus.onTheWay:
        return isDark ? colorScheme.onPrimaryContainer : AppColors.primaryDark;
      case OrderStatus.delivered:
        return isDark ? colorScheme.onTertiaryContainer : const Color(0xFF2E7D32);
      case OrderStatus.canceled:
        return isDark ? colorScheme.onErrorContainer : AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: _backgroundColor(context),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: _textColor(context).withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Text(
        status.labelAr,
        style: TextStyle(
          fontFamily: kFontFamilyCairo,
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: _textColor(context),
        ),
      ),
    );
  }
}
