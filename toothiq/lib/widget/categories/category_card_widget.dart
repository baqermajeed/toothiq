import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../model/category_model.dart';
import '../my_text.dart';
import 'category_icon_widget.dart';

class CategoryCardWidget extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onTap;
  final bool compact;

  const CategoryCardWidget({
    super.key,
    required this.category,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    const designShadow = Color(0x61659AB9);
    final radius = BorderRadius.circular(compact ? 14.r : 20.65.r);
    final iconSize = compact ? 48.w : 56.w;
    final nameSize = compact ? 11.sp : 13.93.sp;

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
            padding: compact
                ? EdgeInsets.symmetric(vertical: 6.h, horizontal: 5.w)
                : EdgeInsets.symmetric(vertical: 8.45.h, horizontal: 7.51.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: compact ? 6.h : 0),
                  child: CategoryIconWidget(
                    category: category,
                    size: iconSize,
                  ),
                ),
                MyText(
                  category.name,
                  fontSize: nameSize,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF022B2F),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  height: 1.3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
