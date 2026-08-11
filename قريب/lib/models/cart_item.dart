import 'product.dart';

/// عنصر السلة — منتج مع كمية وسعر السطر.
class CartItem {
  const CartItem({
    required this.product,
    this.quantity = 1,
  });

  final Product product;
  final int quantity;

  /// سعر السطر = سعر الوحدة × الكمية.
  double get lineTotal => product.price * quantity;
}
