import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../utils/app_colors.dart';

/// خلفية زخرفية بأشكال عضوية فاتحة مثل شاشة الـ onboarding.
class DecorativeBackground extends StatelessWidget {
  const DecorativeBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.background),
        Positioned(
          top: -60.h,
          right: -80.w,
          child: _Blob(size: 220.w, color: const Color(0xFFEFF8F9)),
        ),
        Positioned(
          top: 220.h,
          left: -90.w,
          child: _Blob(size: 160.w, color: const Color(0xFFF3FAFB)),
        ),
        Positioned(
          bottom: -40.h,
          left: -60.w,
          child: _Blob(size: 180.w, color: const Color(0xFFF3FAFB)),
        ),
        Positioned(
          bottom: 140.h,
          right: -70.w,
          child: _Blob(size: 140.w, color: const Color(0xFFE8F6F7)),
        ),
        child,
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(size * 0.6),
          topRight: Radius.circular(size * 0.3),
          bottomLeft: Radius.circular(size * 0.4),
          bottomRight: Radius.circular(size * 0.7),
        ),
      ),
    );
  }
}
