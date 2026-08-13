import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'sparkle_icon.dart';

/// بريقات زخرفية حول محتوى صفحات تسجيل الدخول وإنشاء الحساب.
class AuthPageDecorations extends StatelessWidget {
  const AuthPageDecorations({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: 36.h,
            left: 22.w,
            child: SparkleIcon(size: 14.w, delay: 200.ms),
          ),
          Positioned(
            top: 72.h,
            right: 28.w,
            child: SparkleIcon(size: 12.w, filled: false, delay: 400.ms),
          ),
          Positioned(
            top: 168.h,
            left: 36.w,
            child: SparkleIcon(size: 10.w, delay: 600.ms),
          ),
          Positioned(
            bottom: 120.h,
            right: 28.w,
            child: SparkleIcon(size: 12.w, filled: false, delay: 500.ms),
          ),
          Positioned(
            bottom: 72.h,
            left: 32.w,
            child: SparkleIcon(size: 14.w, delay: 300.ms),
          ),
        ],
      ),
    );
  }
}
