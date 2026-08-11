import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../app_spacing.dart';
import 'shimmer_box.dart';

/// شاشة تحميل كاملة — skeleton من عدة ShimmerBox للاستخدام في AuthWrapper وأي full-screen loading.
class FullPageLoading extends StatelessWidget {
  const FullPageLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: AppSpacing.xl),
              ShimmerBox(
                width: 160.w,
                height: 28.h,
                borderRadius: BorderRadius.circular(8.r),
              ),
              SizedBox(height: AppSpacing.xl),
              ShimmerBox(
                width: double.infinity,
                height: 120.h,
                borderRadius: BorderRadius.circular(16.r),
              ),
              SizedBox(height: AppSpacing.lg),
              ShimmerBox(
                width: 120.w,
                height: 20.h,
                borderRadius: BorderRadius.circular(6.r),
              ),
              SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  ShimmerBox(
                    width: 80.w,
                    height: 48.h,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  ShimmerBox(
                    width: 80.w,
                    height: 48.h,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  ShimmerBox(
                    width: 80.w,
                    height: 48.h,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.xl),
              ShimmerBox(
                width: 140.w,
                height: 20.h,
                borderRadius: BorderRadius.circular(6.r),
              ),
              SizedBox(height: AppSpacing.md),
              ShimmerBox(
                width: double.infinity,
                height: 100.h,
                borderRadius: BorderRadius.circular(12.r),
              ),
              SizedBox(height: AppSpacing.sm),
              ShimmerBox(
                width: double.infinity,
                height: 100.h,
                borderRadius: BorderRadius.circular(12.r),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
