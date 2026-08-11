import 'brand_model.dart';
import 'category_section_model.dart';
import 'product_model.dart';

class SectionDetailCacheEntry {
  final List<ProductModel> products;
  final List<CategorySectionModel> subSections;
  final List<BrandModel> brands;
  final bool hasNextPage;
  final int currentPage;

  const SectionDetailCacheEntry({
    required this.products,
    required this.subSections,
    required this.brands,
    required this.hasNextPage,
    required this.currentPage,
  });
}
