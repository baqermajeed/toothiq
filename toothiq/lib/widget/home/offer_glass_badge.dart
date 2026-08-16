import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../utils/app_colors.dart';

/// تاك العرض الزجاجي الضبابي فوق صورة المنتج.
class OfferGlassBadge extends StatelessWidget {
  final String label;

  const OfferGlassBadge({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20.r);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: AppColors.favoriteRed.withValues(alpha: 0.32),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.28),
            blurRadius: 8,
            spreadRadius: 0.2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.5.h),
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFFF8A80).withValues(alpha: 0.72),
                  AppColors.favoriteRed.withValues(alpha: 0.48),
                  const Color(0xFFE53935).withValues(alpha: 0.28),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
              border: Border.all(
                color: const Color(0xFFFFCDD2).withValues(alpha: 0.88),
                width: 1.15,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 0,
                  left: 6.w,
                  right: 6.w,
                  child: Container(
                    height: 1.2,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.r),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0),
                          Colors.white.withValues(alpha: 0.95),
                          Colors.white.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Expo Arabic',
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                    letterSpacing: 0.2,
                    shadows: const [
                      Shadow(
                        color: Color(0x990D3136),
                        blurRadius: 8,
                        offset: Offset(0, 1),
                      ),
                      Shadow(
                        color: Color(0xCCFFFFFF),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
