import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/utils/image_url.dart';
import '../utils/app_colors.dart';

class AppImage extends StatelessWidget {
  final String source;
  final BoxFit fit;
  final double? width;
  final double? height;
  final IconData errorIcon;

  const AppImage({
    super.key,
    required this.source,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorIcon = Icons.image_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final resolved = ImageUrl.resolve(source);

    if (ImageUrl.isNetwork(resolved)) {
      return Image.network(
        resolved,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _placeholder(showLoader: true);
        },
      );
    }

    return Image.asset(
      resolved,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => _placeholder(),
    );
  }

  Widget _placeholder({bool showLoader = false}) {
    return Container(
      width: width,
      height: height,
      color: AppColors.cardPlaceholder,
      alignment: Alignment.center,
      child: showLoader
          ? SizedBox(
              width: 24.w,
              height: 24.w,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(errorIcon, size: 40.sp, color: AppColors.textLight),
    );
  }
}
