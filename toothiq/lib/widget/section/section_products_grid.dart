import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../model/product_model.dart';
import '../home/products_grid_widget.dart';

/// شبكة منتجات القسم — تعتمد نفس كارد وتصميم الصفحة الرئيسية.
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
    return ProductsGridWidget(
      products: products,
      scrollController: scrollController,
      emptyTitle: emptyTitle,
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
    );
  }
}
