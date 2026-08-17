import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../model/category_model.dart';
import '../app_image.dart';

class CategoryIconWidget extends StatelessWidget {
  const CategoryIconWidget({
    super.key,
    required this.category,
    this.size,
  });

  final CategoryModel category;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final iconSize = size ?? 56.w;
    final fallback = _fallbackIcon(iconSize);

    if (!category.hasIconImage) return fallback;

    return AppImage(
      source: category.iconUrl!,
      width: iconSize,
      height: iconSize,
      fit: BoxFit.contain,
      errorWidget: fallback,
    );
  }

  Widget _fallbackIcon(double iconSize) {
    return Icon(
      category.icon,
      size: iconSize,
      color: category.iconColor,
    );
  }
}
