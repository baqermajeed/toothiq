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
  final String? fallback;
  final Color? placeholderColor;
  final bool showLoadingIndicator;

  const AppImage({
    super.key,
    required this.source,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorIcon = Icons.image_outlined,
    this.fallback,
    this.placeholderColor,
    this.showLoadingIndicator = true,
  });

  @override
  Widget build(BuildContext context) {
    final resolved = ImageUrl.resolve(
      source,
      fallback: fallback ?? ImageUrl.productPlaceholder,
    );

    if (ImageUrl.isNetwork(resolved)) {
      return Image.network(
        resolved,
        width: width,
        height: height,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _loadingPlaceholder();
        },
      );
    }

    return Image.asset(
      resolved,
      width: width,
      height: height,
      fit: fit,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) => _placeholder(),
    );
  }

  Widget _loadingPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: placeholderColor ?? AppColors.cardPlaceholder,
      alignment: Alignment.center,
      child: showLoadingIndicator
          ? SizedBox(
              width: 24.w,
              height: 24.w,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
    );
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: placeholderColor ?? AppColors.cardPlaceholder,
      alignment: Alignment.center,
      child: Icon(errorIcon, size: 40.sp, color: AppColors.textLight),
    );
  }
}
