import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/app_theme.dart';

/// ويدجت عصري لـ pagination: يعرض حالة التحميل أو زر «تحميل المزيد».
/// يُستخدم في الصفحة الرئيسية، صفحة المحلات، وصفحة منتجات المحل.
class LoadMoreFooter extends StatelessWidget {
  const LoadMoreFooter({
    super.key,
    required this.isLoading,
    required this.hasMore,
    this.onLoadMore,
    this.compact = false,
  });

  /// true أثناء جلب الصفحة التالية.
  final bool isLoading;

  /// true إذا كانت هناك صفحة تالية يمكن تحميلها.
  final bool hasMore;

  /// يُستدعى عند الضغط على «تحميل المزيد». إن كان null لا يُعرض الزر.
  final VoidCallback? onLoadMore;

  /// إن كان true يُستخدم تخطيط مضغوط (مثلاً داخل خلية شبكة).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (!hasMore && !isLoading) {
      return SizedBox(height: compact ? 24.h : 32.h);
    }

    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? colorScheme.surfaceContainerHigh
        : colorScheme.surfaceContainerHighest;
    final borderColor = colorScheme.outline.withValues(alpha: 0.4);
    final primaryColor = colorScheme.primary;

    if (isLoading) {
      return Align(
        alignment: Alignment.center,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12.w : 20.w,
            vertical: compact ? 10.h : 14.h,
          ),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(compact ? 14.r : 18.r),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: compact ? 20.w : 24.w,
                height: compact ? 20.h : 24.h,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: primaryColor,
                ),
              ),
              SizedBox(width: compact ? 8.w : 12.w),
              Text(
                'جارٍ جلب المزيد...',
                style: TextStyle(
                  fontFamily: kFontFamilyCairo,
                  fontSize: compact ? 12.sp : 14.sp,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (hasMore && onLoadMore != null) {
      return Align(
        alignment: Alignment.center,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onLoadMore,
            borderRadius: BorderRadius.circular(compact ? 14.r : 18.r),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 12.w : 20.w,
                vertical: compact ? 10.h : 14.h,
              ),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(compact ? 14.r : 18.r),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: compact ? 20.sp : 24.sp,
                    color: primaryColor,
                  ),
                  SizedBox(width: compact ? 6.w : 8.w),
                  Text(
                    'جارٍ جلب المزيد...',
                    style: TextStyle(
                      fontFamily: kFontFamilyCairo,
                      fontSize: compact ? 13.sp : 15.sp,
                      fontWeight: FontWeight.w700,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
