import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// تاك «شائع» الأصفر مع أيقونة نار فوق صورة المنتج.
class PopularGlassBadge extends StatelessWidget {
  const PopularGlassBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20.r);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB300).withValues(alpha: 0.36),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFFFE082).withValues(alpha: 0.9),
                  const Color(0xFFFFC107).withValues(alpha: 0.78),
                  const Color(0xFFFFB300).withValues(alpha: 0.62),
                ],
              ),
              border: Border.all(
                color: const Color(0xFFFFF8E1).withValues(alpha: 0.92),
                width: 1.1,
              ),
            ),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_fire_department_rounded,
                    size: 13.sp,
                    color: const Color(0xFFE65100),
                  ),
                  SizedBox(width: 3.w),
                  Text(
                    'شائع',
                    style: TextStyle(
                      fontFamily: 'Expo Arabic',
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF5D4037),
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
