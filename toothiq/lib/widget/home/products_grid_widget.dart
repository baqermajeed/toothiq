import 'package:flutter/material.dart';

import '../../model/product_model.dart';
import '../common/async_state_widgets.dart';
import 'product_card_widget.dart';

/// شبكة منتجات موحّدة — نفس تصميم ومقاسات الصفحة الرئيسية.
class ProductsGridWidget extends StatelessWidget {
  final List<ProductModel> products;
  final ScrollController? scrollController;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;
  final String emptyTitle;
  final String? emptySubtitle;

  const ProductsGridWidget({
    super.key,
    required this.products,
    this.scrollController,
    this.shrinkWrap = false,
    this.physics,
    this.padding,
    this.emptyTitle = 'لا توجد منتجات',
    this.emptySubtitle,
  });

  /// نفس شبكة الصفحة الرئيسية (عمودان + ارتفاع ثابت للكارد).
  static SliverGridDelegate get gridDelegate {
    return ProductCardWidget.gridDelegate;
  }

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return AppEmptyState(
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }

    return GridView.builder(
      controller: scrollController,
      shrinkWrap: shrinkWrap,
      primary: shrinkWrap ? false : null,
      physics: physics ??
          (shrinkWrap
              ? const NeverScrollableScrollPhysics()
              : const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                )),
      padding: padding ?? EdgeInsets.zero,
      itemCount: products.length,
      gridDelegate: gridDelegate,
      itemBuilder: (context, index) {
        return ProductCardWidget(product: products[index]);
      },
    );
  }
}
