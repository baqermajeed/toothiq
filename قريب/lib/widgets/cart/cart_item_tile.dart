import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/cart_item.dart';
import '../../utils/price_formatter.dart';
import '../common/app_spacing.dart';

/// تنسيق السعر بالريال مع فواصل الآلاف — للاستخدام المشترك في شاشة السلة والـ bottom sheet.
String formatCartPrice(double value) => formatPrice(value);

/// صف عنصر سلة قابل لإعادة الاستخدام — شاشة السلة والـ bottom sheet.
class CartItemTile extends StatelessWidget {
  const CartItemTile({
    super.key,
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
    required this.formatPrice,
    this.compact = false,
  });

  final CartItem item;
  final void Function(int) onQuantityChanged;
  final VoidCallback onRemove;
  final String Function(double) formatPrice;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = item.product;
    final padding = compact ? AppSpacing.sm : AppSpacing.md;
    final nameSize = compact ? 13.sp : 15.sp;
    final priceSize = compact ? 11.sp : 12.sp;
    final totalSize = compact ? 14.sp : 16.sp;
    final radius = compact ? 14.r : 20.r;
    final shadowBlur = compact ? 8.r : 12.r;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.06),
            blurRadius: shadowBlur,
            offset: Offset(0, compact ? 2.h : 4.h),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Transform(
              alignment: Alignment.centerLeft,
              transform: Matrix4.skewX(-0.08),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    p.name,
                    style: TextStyle(
                      fontFamily: kFontFamilyCairo,
                      fontSize: nameSize,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: compact ? 2.h : 4.h),
                  Text(
                    '${formatPrice(p.price)}${p.unit != null && p.unit!.isNotEmpty ? ' / ${p.unit}' : ''}',
                    style: TextStyle(
                      fontFamily: kFontFamilyCairo,
                      fontSize: priceSize,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: compact ? 6.h : 10.h),
                  Row(
                    children: [
                      _QuantityStepper(
                        quantity: item.quantity,
                        compact: compact,
                        onDecrement: () => onQuantityChanged(item.quantity - 1),
                        onIncrement: () => onQuantityChanged(item.quantity + 1),
                      ),
                      const Spacer(),
                      Text(
                        formatPrice(item.lineTotal),
                        style: TextStyle(
                          fontFamily: kFontFamilyCairo,
                          fontSize: totalSize,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: Icon(
              Icons.delete_outline_rounded,
              size: compact ? 20.sp : 22.sp,
              color: AppColors.textSecondary,
            ),
            style: IconButton.styleFrom(
              padding: EdgeInsets.all(compact ? 2.w : 4.w),
              minimumSize: Size(compact ? 32.w : 36.w, compact ? 32.h : 36.h),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
    this.compact = false,
  });

  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 32.w : 36.w;
    final iconSize = compact ? 18.sp : 20.sp;
    final textSize = compact ? 14.sp : 16.sp;
    final radius = compact ? 10.r : 12.r;
    final padding = compact ? 10.w : 14.w;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: quantity > 1 ? onDecrement : null,
            borderRadius: BorderRadius.circular(radius),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: quantity > 1 ? AppColors.primaryLight : AppColors.border.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: AppColors.border),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.remove_rounded,
                size: iconSize,
                color: quantity > 1 ? AppColors.primaryDark : AppColors.textSecondary,
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: Text(
            '$quantity',
            style: TextStyle(
              fontFamily: kFontFamilyCairo,
              fontSize: textSize,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onIncrement,
            borderRadius: BorderRadius.circular(radius),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: AppColors.primaryDark),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.add_rounded, size: iconSize, color: AppColors.primaryLight),
            ),
          ),
        ),
      ],
    );
  }
}

/// شريط المجموع الكلي — للاستخدام في شاشة السلة والـ bottom sheet.
class CartTotalBar extends StatelessWidget {
  const CartTotalBar({
    super.key,
    required this.total,
    required this.formatPrice,
  });

  final double total;
  final String Function(double) formatPrice;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg + 8.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.06),
            blurRadius: 12.r,
            offset: Offset(0, -4.h),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'المجموع الكلي',
              style: TextStyle(
                fontFamily: kFontFamilyCairo,
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              formatPrice(total),
              style: TextStyle(
                fontFamily: kFontFamilyCairo,
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
