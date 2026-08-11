import 'brand_model.dart';
import 'shop_category_model.dart';

class SearchFilterOptionsModel {
  final double priceMin;
  final double priceMax;
  final List<ShopCategoryModel> categories;
  final List<BrandModel> brands;

  const SearchFilterOptionsModel({
    required this.priceMin,
    required this.priceMax,
    this.categories = const [],
    this.brands = const [],
  });

  static const double fallbackMinPrice = 0.0;
  static const double fallbackMaxPrice = 200000.0;

  factory SearchFilterOptionsModel.fallback() {
    return const SearchFilterOptionsModel(
      priceMin: fallbackMinPrice,
      priceMax: fallbackMaxPrice,
    );
  }

  bool get hasCategories => categories.isNotEmpty;
  bool get hasBrands => brands.isNotEmpty;
}
