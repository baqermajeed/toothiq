import 'product_model.dart';

class CartItemModel {
  final ProductModel product;
  int quantity;

  CartItemModel({
    required this.product,
    this.quantity = 1,
  });

  int get lineTotal => product.sellingPrice * quantity;

  String get formattedLineTotal {
    final formatted = lineTotal.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$formatted د.ع';
  }

  Map<String, dynamic> toJson() {
    return {
      'quantity': quantity,
      'product': product.toFavoriteJson(),
    };
  }

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final rawProduct = json['product'];
    final productMap = rawProduct is Map<String, dynamic>
        ? rawProduct
        : const <String, dynamic>{};
    return CartItemModel(
      product: ProductModel.fromFavoriteJson(productMap),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    );
  }
}
