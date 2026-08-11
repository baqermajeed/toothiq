import '../../model/brand_model.dart';
import '../../model/search_filter_options_model.dart';
import '../../model/shop_category_model.dart';
import 'brand_service.dart';
import 'category_service.dart';
import 'product_service.dart';

class SearchFilterOptionsService {
  final CategoryService _categoryService;
  final BrandService _brandService;
  final ProductService _productService;

  SearchFilterOptionsModel? _cache;

  SearchFilterOptionsService(
    this._categoryService,
    this._brandService,
    this._productService,
  );

  Future<SearchFilterOptionsModel> fetch({bool forceRefresh = false}) async {
    if (!forceRefresh && _cache != null) return _cache!;

    final results = await Future.wait([
      _categoryService.fetchCategories(),
      _productService.fetchPriceBounds(),
    ]);

    final categories = results[0] as List<ShopCategoryModel>;
    final priceBounds = results[1] as ({double min, double max});

    final brands = await _fetchAllBrands(categories);

    final options = SearchFilterOptionsModel(
      priceMin: priceBounds.min,
      priceMax: priceBounds.max,
      categories: categories,
      brands: brands,
    );
    _cache = options;
    return options;
  }

  Future<List<BrandModel>> _fetchAllBrands(
    List<ShopCategoryModel> categories,
  ) async {
    if (categories.isEmpty) return const [];

    final brandsById = <String, BrandModel>{};
    final results = await Future.wait(
      categories.map((category) => _brandService.fetchBrandsByCategory(category.id)),
    );

    for (final list in results) {
      for (final brand in list) {
        brandsById[brand.id] = brand;
      }
    }

    final brands = brandsById.values.toList(growable: false)
      ..sort((a, b) => a.name.compareTo(b.name));
    return brands;
  }
}
