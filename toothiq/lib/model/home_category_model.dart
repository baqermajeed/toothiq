class HomeCategoryModel {
  final String? id;
  final String name;
  final bool isShopCategory;

  const HomeCategoryModel({
    required this.id,
    required this.name,
    this.isShopCategory = false,
  });

  const HomeCategoryModel.all()
      : id = null,
        name = 'الكل',
        isShopCategory = false;

  bool get isAll => id == null;
}
