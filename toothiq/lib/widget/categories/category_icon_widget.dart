import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/utils/image_url.dart';
import '../../model/category_model.dart';

class CategoryIconWidget extends StatelessWidget {
  const CategoryIconWidget({
    super.key,
    required this.category,
    this.size,
    this.backgroundColor,
  });

  final CategoryModel category;
  final double? size;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final boxSize = size ?? 40.w;
    final imageSize = boxSize * 0.72;
    final bg = backgroundColor ?? category.iconColor.withValues(alpha: 0.12);

    return Container(
      width: boxSize,
      height: boxSize,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: category.hasIconImage
          ? ClipOval(
              child: Image.network(
                ImageUrl.resolve(category.iconUrl),
                width: imageSize,
                height: imageSize,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => _fallbackIcon(imageSize),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return SizedBox(
                    width: imageSize * 0.5,
                    height: imageSize * 0.5,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: category.iconColor,
                    ),
                  );
                },
              ),
            )
          : _fallbackIcon(imageSize),
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
