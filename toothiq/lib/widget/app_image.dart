import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/utils/image_url.dart';
import '../utils/app_colors.dart';
import 'common/skeleton.dart';

class AppImage extends StatelessWidget {
  final String source;
  final BoxFit fit;
  final double? width;
  final double? height;
  final IconData errorIcon;
  final String? fallback;
  final Color? placeholderColor;
  final bool showLoadingIndicator;
  final Widget? errorWidget;

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
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final resolved = ImageUrl.resolve(
      source,
      fallback: fallback ?? ImageUrl.productPlaceholder,
    );
    final imageWidth = width == double.infinity ? null : width;
    final imageHeight = height == double.infinity ? null : height;

    final image = ImageUrl.isNetwork(resolved)
        ? Image.network(
            resolved,
            width: imageWidth,
            height: imageHeight,
            fit: fit,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) => _placeholder(),
            frameBuilder: _frameBuilder,
          )
        : Image.asset(
            resolved,
            width: imageWidth,
            height: imageHeight,
            fit: fit,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) => _placeholder(),
            frameBuilder: _frameBuilder,
          );

    return SizedBox(
      width: width,
      height: height,
      child: image,
    );
  }

  Widget _frameBuilder(
    BuildContext context,
    Widget child,
    int? frame,
    bool wasSynchronouslyLoaded,
  ) {
    if (wasSynchronouslyLoaded) {
      return SizedBox.expand(child: child);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: placeholderColor ?? SkeletonStyle.base),
        if (frame == null)
          Positioned.fill(child: ImageShimmer(color: placeholderColor)),
        Positioned.fill(
          child: AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: child,
          ),
        ),
      ],
    );
  }

  Widget _placeholder() {
    return errorWidget ??
        ColoredBox(
          color: placeholderColor ?? AppColors.cardPlaceholder,
          child: Center(
            child: Icon(errorIcon, size: 40.sp, color: AppColors.textLight),
          ),
        );
  }
}
