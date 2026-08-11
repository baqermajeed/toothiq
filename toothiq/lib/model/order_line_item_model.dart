class OrderLineItemModel {
  final String id;
  final String? productId;
  final String name;
  final int quantity;
  final int unitPrice;
  final String imageAsset;

  const OrderLineItemModel({
    required this.id,
    this.productId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.imageAsset,
  });

  int get lineTotal => unitPrice * quantity;

  String get formattedPrice {
    final formatted = unitPrice.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$formatted د.ع';
  }

  String get formattedLineTotal {
    final formatted = lineTotal.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$formatted د.ع';
  }
}
