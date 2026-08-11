import '../../core/api/api_client.dart';
import '../../model/brand_model.dart';
import '../../model/category_catalog_model.dart';
import '../../model/category_section_model.dart';
import '../../model/product_model.dart';
import '../../model/shop_category_model.dart';

class CategoryService {
  final ApiClient _api;

  CategoryService(this._api);

  /// الأقسام الرئيسية من `GET /api/catalog/categories`.
  Future<List<ShopCategoryModel>> fetchCategories() {
    return _api.getCatalogCategories();
  }

  /// أقسام فرعية + براندات لقسم من كتالوج الـ API العام.
  Future<CategoryCatalogModel> fetchCategoryCatalog(String categoryId) async {
    ShopCategoryModel? detail;
    try {
      detail = await _api.getCatalogCategoryById(categoryId);
    } catch (_) {
      // نكمل بالطلبات المنفصلة.
    }

    var sections = detail?.sections ?? const <CategorySectionModel>[];
    var brands = detail?.brands ?? const <BrandModel>[];

    if (sections.isEmpty) {
      try {
        sections = await _api.getCatalogSubcategories(categoryId);
      } catch (_) {}
    }

    if (brands.isEmpty) {
      try {
        brands = await _api.getCatalogBrands(categoryId);
      } catch (_) {}
    }

    return CategoryCatalogModel(subSections: sections, brands: brands);
  }

  /// أقسام فرعية بأسماء حقيقية فقط (من المنتجات إذا وُجد subcategoryName).
  List<CategorySectionModel> namedSectionsFromProducts({
    required String categoryId,
    required List<ProductModel> products,
  }) {
    final sectionsById = <String, CategorySectionModel>{};
    var order = 0;

    for (final product in products) {
      if (product.productCategoryId != categoryId) continue;
      final sectionId = product.subcategoryId?.trim();
      final sectionName = product.subcategoryName?.trim();
      if (sectionId == null ||
          sectionId.isEmpty ||
          sectionName == null ||
          sectionName.isEmpty) {
        continue;
      }
      sectionsById.putIfAbsent(
        sectionId,
        () => CategorySectionModel(
          id: sectionId,
          nameAr: sectionName,
          order: order++,
        ),
      );
    }

    return sectionsById.values.toList(growable: false)
      ..sort((a, b) => a.order.compareTo(b.order));
  }
}
