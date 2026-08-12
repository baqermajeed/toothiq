class ShopCategory {
  final String id;
  final String nameAr;
  final String? imagePath;
  final int productCount;
  final String? parentCategoryId;
  final String source;

  const ShopCategory({
    required this.id,
    required this.nameAr,
    this.imagePath,
    this.productCount = 0,
    this.parentCategoryId,
    this.source = 'shop',
  });

  bool get isAdminLinked => source == 'admin' || parentCategoryId != null;

  ShopCategory copyWith({
    String? nameAr,
    String? imagePath,
    int? productCount,
    String? parentCategoryId,
    String? source,
    bool clearImage = false,
  }) {
    return ShopCategory(
      id: id,
      nameAr: nameAr ?? this.nameAr,
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
      productCount: productCount ?? this.productCount,
      parentCategoryId: parentCategoryId ?? this.parentCategoryId,
      source: source ?? this.source,
    );
  }

  factory ShopCategory.fromApi(Map<String, dynamic> json) {
    final parentId = json['parentCategoryId']?.toString();
    final rawSource = json['source']?.toString();
    return ShopCategory(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      nameAr: json['nameAr']?.toString() ?? json['name']?.toString() ?? '',
      imagePath: json['image']?.toString() ?? json['logo']?.toString() ?? json['icon']?.toString(),
      productCount: (json['productCount'] as num?)?.toInt() ??
          (json['productsCount'] as num?)?.toInt() ??
          0,
      parentCategoryId: parentId?.isNotEmpty == true ? parentId : null,
      source: rawSource ??
          (parentId != null && parentId.isNotEmpty ? 'admin' : 'shop'),
    );
  }
}
