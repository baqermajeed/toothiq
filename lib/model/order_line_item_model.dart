class OrderLineItemModel {
  final String id;
  final String name;
  final int quantity;
  final int unitPrice;
  final String imageAsset;

  const OrderLineItemModel({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.imageAsset,
  });

  String get formattedPrice {
    final formatted = unitPrice.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$formatted د.ع';
  }
}
