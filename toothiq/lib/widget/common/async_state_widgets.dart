import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../utils/app_colors.dart';
import '../my_text.dart';

class AppLoadingState extends StatelessWidget {
  const AppLoadingState({super.key, this.padding});

  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final spinner = const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
    if (padding == null) return spinner;
    return Padding(padding: padding!, child: spinner);
  }
}

class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.message,
    required this.onRetry,
    this.compact = false,
  });

  final String message;
  final VoidCallback onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MyText(
          message,
          fontSize: compact ? 13.sp : 15.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.error,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: compact ? 8.h : 12.h),
        TextButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
      ],
    );
    if (compact) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        child: content,
      );
    }
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 28.w),
        child: content,
      ),
    );
  }
}

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_rounded,
    this.iconWidget,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? iconWidget;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 28.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget ??
                Icon(icon, size: 62.sp, color: AppColors.textLight),
            SizedBox(height: 14.h),
            MyText(
              title,
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              SizedBox(height: 6.h),
              MyText(
                subtitle!,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AppLoadMoreFooter extends StatelessWidget {
  const AppLoadMoreFooter({
    super.key,
    required this.isLoading,
    required this.hasNextPage,
    required this.onTap,
  });

  final bool isLoading;
  final bool hasNextPage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: const AppLoadingState(),
      );
    }
    if (!hasNextPage) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Center(
        child: TextButton(onPressed: onTap, child: const Text('تحميل المزيد')),
      ),
    );
  }
}
