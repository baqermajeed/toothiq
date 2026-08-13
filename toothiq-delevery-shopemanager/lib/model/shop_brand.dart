class ShopBrand {
  final String id;
  final String nameAr;
  final String? logoPath;
  final int productCount;

  const ShopBrand({
    required this.id,
    required this.nameAr,
    this.logoPath,
    this.productCount = 0,
  });

  ShopBrand copyWith({
    String? nameAr,
    String? logoPath,
    int? productCount,
    bool clearLogo = false,
  }) {
    return ShopBrand(
      id: id,
      nameAr: nameAr ?? this.nameAr,
      logoPath: clearLogo ? null : (logoPath ?? this.logoPath),
      productCount: productCount ?? this.productCount,
    );
  }

  factory ShopBrand.fromApi(Map<String, dynamic> json) {
    return ShopBrand(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      nameAr: json['nameAr']?.toString() ?? json['name']?.toString() ?? '',
      logoPath: json['image']?.toString() ?? json['logo']?.toString(),
      productCount: (json['productCount'] as num?)?.toInt() ??
          (json['productsCount'] as num?)?.toInt() ??
          0,
    );
  }
}
