import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../model/product_model.dart';
import 'product_card_widget.dart';

/// شريط أفقي بنفس كارد ومقاس الصفحة الرئيسية.
class ProductCardsStrip extends StatelessWidget {
  final List<ProductModel> products;

  const ProductCardsStrip({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: ProductCardWidget.cardHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: products.length,
        separatorBuilder: (_, _) => SizedBox(width: 12.w),
        itemBuilder: (context, index) {
          return SizedBox(
            width: ProductCardWidget.cardWidthFor(context),
            child: ProductCardWidget(product: products[index]),
          );
        },
      ),
    );
  }
}
