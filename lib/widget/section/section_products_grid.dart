import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../model/product_model.dart';
import '../home/product_card_widget.dart';

class SectionProductsGrid extends StatelessWidget {
  final List<ProductModel> products;

  const SectionProductsGrid({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 14.h,
        childAspectRatio: 0.55,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return Align(
              alignment: Alignment.topCenter,
              child: ProductCardWidget(
                product: products[index],
                maxHeight: constraints.maxHeight,
              ),
            );
          },
        );
      },
    );
  }
}
