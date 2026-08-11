class ShopCategoryModel {
  final String id;
  final String nameAr;

  const ShopCategoryModel({
    required this.id,
    required this.nameAr,
  });

  factory ShopCategoryModel.fromJson(Map<String, dynamic> json) {
    return ShopCategoryModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      nameAr: json['nameAr']?.toString() ?? json['name']?.toString() ?? '',
    );
  }
}
