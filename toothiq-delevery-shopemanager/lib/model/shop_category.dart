class ShopCategory {
  final String id;
  final String nameAr;
  final String? imagePath;
  final int productCount;

  const ShopCategory({
    required this.id,
    required this.nameAr,
    this.imagePath,
    this.productCount = 0,
  });

  ShopCategory copyWith({
    String? nameAr,
    String? imagePath,
    int? productCount,
    bool clearImage = false,
  }) {
    return ShopCategory(
      id: id,
      nameAr: nameAr ?? this.nameAr,
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
      productCount: productCount ?? this.productCount,
    );
  }

  factory ShopCategory.fromApi(Map<String, dynamic> json) {
    return ShopCategory(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      nameAr: json['nameAr']?.toString() ?? json['name']?.toString() ?? '',
      imagePath: json['image']?.toString() ?? json['logo']?.toString(),
      productCount: (json['productCount'] as num?)?.toInt() ?? 0,
    );
  }
}
