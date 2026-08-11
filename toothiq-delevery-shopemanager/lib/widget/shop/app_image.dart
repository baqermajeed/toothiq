import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/utils/image_url.dart';
import '../../utils/app_colors.dart';

class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    this.path,
    this.width,
    this.height,
    this.borderRadius,
    this.fit = BoxFit.cover,
    this.icon = Icons.image_outlined,
    this.iconColor,
    this.backgroundColor,
  });

  final String? path;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxFit fit;
  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(12.r);
    final bg = backgroundColor ?? AppColors.primaryLight;

    Widget child;
    final raw = path?.trim();
    if (raw != null && raw.isNotEmpty) {
      if (ImageUrl.isLocalFile(raw) && File(raw).existsSync()) {
        child = Image.file(File(raw), fit: fit, width: width, height: height);
      } else {
        final resolved = ImageUrl.isNetwork(raw) ? raw : ImageUrl.resolve(raw);
        if (ImageUrl.isNetwork(resolved)) {
          child = Image.network(
            resolved,
            fit: fit,
            width: width,
            height: height,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return _placeholder(bg, showLoader: true);
            },
            errorBuilder: (_, __, ___) => _placeholder(bg),
          );
        } else {
          child = _placeholder(bg);
        }
      }
    } else {
      child = _placeholder(bg);
    }

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(width: width, height: height, child: child),
    );
  }

  double _resolveIconSize() {
    final candidates = [width, height];
    for (final dimension in candidates) {
      if (dimension != null && dimension.isFinite && dimension > 0) {
        return (dimension * 0.35).clamp(20.0, 48.0);
      }
    }
    return 28.sp;
  }

  Widget _placeholder(Color bg, {bool showLoader = false}) {
    return Container(
      width: width,
      height: height,
      color: bg,
      alignment: Alignment.center,
      child: showLoader
          ? SizedBox(
              width: 24.w,
              height: 24.w,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              icon,
              color: iconColor ?? AppColors.primary.withValues(alpha: 0.7),
              size: _resolveIconSize(),
            ),
    );
  }
}
