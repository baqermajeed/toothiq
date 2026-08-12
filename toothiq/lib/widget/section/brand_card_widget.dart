import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../model/brand_model.dart';
import '../app_image.dart';
import '../my_text.dart';

class BrandCardWidget extends StatelessWidget {
  final BrandModel brand;
  final VoidCallback onTap;

  const BrandCardWidget({
    super.key,
    required this.brand,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const designShadow = Color(0x61659AB9);
    final radius = BorderRadius.circular(20.65.r);
    final imageSize = 56.w;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: const [
            BoxShadow(
              color: designShadow,
              blurRadius: 5.5,
              offset: Offset(0, 0),
            ),
          ],
        ),
        child: Material(
          color: Colors.white,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8.45.h, horizontal: 7.51.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppImage(
                  source: brand.imageUrl,
                  width: imageSize,
                  height: imageSize,
                  fit: BoxFit.contain,
                  errorIcon: Icons.storefront_outlined,
                ),
                MyText(
                  brand.name,
                  fontSize: 13.93.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF022B2F),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  height: 1.5,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
