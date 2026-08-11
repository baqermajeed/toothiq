import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../model/product_model.dart';
import '../common/async_state_widgets.dart';
import '../home/product_card_widget.dart';

class SectionProductsGrid extends StatelessWidget {
  final List<ProductModel> products;
  final ScrollController? scrollController;
  final String emptyTitle;

  const SectionProductsGrid({
    super.key,
    required this.products,
    this.scrollController,
    this.emptyTitle = 'لا توجد منتجات',
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return AppEmptyState(title: emptyTitle);
    }

    return GridView.builder(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 14.h,
        childAspectRatio: 0.55,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return ProductCardWidget(product: products[index]);
      },
    );
  }
}
