class CategorySectionModel {
  final String id;
  final String nameAr;
  final int order;

  const CategorySectionModel({
    required this.id,
    required this.nameAr,
    this.order = 0,
  });

  factory CategorySectionModel.fromJson(Map<String, dynamic> json) {
    return CategorySectionModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      nameAr: json['nameAr']?.toString() ?? json['name']?.toString() ?? '',
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }
}
