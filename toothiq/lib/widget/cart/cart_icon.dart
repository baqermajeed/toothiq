import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CartIcon extends StatelessWidget {
  const CartIcon({
    super.key,
    this.size,
    this.color,
  });

  final double? size;
  final Color? color;

  static const assetPath = 'assets/images/icon/basket23.png';

  @override
  Widget build(BuildContext context) {
    final dimension = size ?? 26.w;
    final image = Image.asset(
      assetPath,
      width: dimension,
      height: dimension,
      fit: BoxFit.contain,
    );

    if (color == null) return image;

    return ColorFiltered(
      colorFilter: ColorFilter.mode(color!, BlendMode.srcIn),
      child: image,
    );
  }
}
