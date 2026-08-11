/// نموذج المنتج — يُنشأ من Map (بيانات وهمية) أو من استجابة API لاحقاً.
class Product {
  const Product({
    this.id,
    required this.name,
    this.description,
    required this.price,
    this.image,
    this.unit,
    this.isAvailable = true,
    this.shopName,
    this.shopId,
    this.emoji,
  });

  /// من خريطة (وهمية أو من API).
  factory Product.fromMap(Map<String, dynamic> map) {
    final price = map['price'];
    return Product(
      id: map['id'] as String? ?? map['_id'] as String?,
      name: map['name'] as String? ?? '',
      description: map['description'] as String?,
      price: price is num ? price.toDouble() : double.tryParse(price?.toString() ?? '0') ?? 0,
      image: map['image'] as String?,
      unit: map['unit'] as String?,
      isAvailable: map['isAvailable'] as bool? ?? true,
      shopName: map['shopName'] as String? ?? map['shop'] as String?,
      shopId: map['shopId'] as String?,
      emoji: map['emoji'] as String?,
    );
  }

  final String? id;
  final String name;
  final String? description;
  final double price;
  final String? image;
  final String? unit;
  final bool isAvailable;
  final String? shopName;
  final String? shopId;
  final String? emoji;

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        if (description != null) 'description': description,
        'price': price,
        if (image != null) 'image': image,
        if (unit != null) 'unit': unit,
        'isAvailable': isAvailable,
        if (shopName != null) 'shopName': shopName,
        if (shopId != null) 'shopId': shopId,
        if (emoji != null) 'emoji': emoji,
      };
}
