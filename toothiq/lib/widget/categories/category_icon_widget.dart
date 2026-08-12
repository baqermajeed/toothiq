import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/utils/image_url.dart';
import '../../model/category_model.dart';

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

    if (category.hasIconImage) {
      return Image.network(
        ImageUrl.resolve(category.iconUrl),
        width: iconSize,
        height: iconSize,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _fallbackIcon(iconSize),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            width: iconSize,
            height: iconSize,
            child: Center(
              child: SizedBox(
                width: iconSize * 0.4,
                height: iconSize * 0.4,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: category.iconColor,
                ),
              ),
            ),
          );
        },
      );
    }

    return _fallbackIcon(iconSize);
  }

  Widget _fallbackIcon(double iconSize) {
    return Icon(
      category.icon,
      size: iconSize,
      color: category.iconColor,
    );
  }
}
