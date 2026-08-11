import 'brand_model.dart';
import 'category_section_model.dart';

class CategoryCatalogModel {
  final List<CategorySectionModel> subSections;
  final List<BrandModel> brands;

  const CategoryCatalogModel({
    this.subSections = const [],
    this.brands = const [],
  });

  static const empty = CategoryCatalogModel();
}
