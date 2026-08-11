import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/app_colors.dart';

/// بطاقة المحتوى لشاشات طلب الموقع (بوابة الموقع / إضافة الموقع بعد تسجيل الدخول).
/// تصميم عصري: زجاجي، ظل خفيف، حدود ناعمة.
class LocationRequestContentCard extends StatelessWidget {
  const LocationRequestContentCard({
    super.key,
    required this.isDark,
    required this.child,
  });

  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: EdgeInsets.all(28.w),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceDark.withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(28.r),
            border: Border.all(
              color: isDark
                  ? AppColors.borderDark.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.8),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : AppColors.primaryDark)
                    .withValues(alpha: isDark ? 0.3 : 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// منطقة أيقونة الموقع الدائرية البارزة في شاشات طلب الموقع.
class LocationRequestIconArea extends StatelessWidget {
  const LocationRequestIconArea({
    super.key,
    required this.colorScheme,
  });

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 120.w,
        height: 120.w,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withValues(alpha: 0.2),
              colorScheme.primary.withValues(alpha: 0.08),
            ],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(
          Icons.location_on_rounded,
          size: 56.sp,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}
