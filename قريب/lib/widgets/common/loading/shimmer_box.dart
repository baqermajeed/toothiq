import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'app_shimmer_theme.dart';

/// صندوق shimmer عام — يُستخدم كـ placeholder في أي مكان (قوائم، بطاقات، أزرار).
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  final double width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppShimmerTheme.baseColor,
      highlightColor: AppShimmerTheme.highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppShimmerTheme.baseColor,
          borderRadius: borderRadius ?? BorderRadius.zero,
        ),
      ),
    );
  }
}
