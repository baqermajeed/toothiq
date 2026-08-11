class HomeCategoryModel {
  final String? id;
  final String name;

  const HomeCategoryModel({
    required this.id,
    required this.name,
  });

  const HomeCategoryModel.all() : id = null, name = 'الكل';

  bool get isAll => id == null;
}
