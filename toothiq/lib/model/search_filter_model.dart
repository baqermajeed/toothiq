import 'search_filter_options_model.dart';

enum SearchSortOption {
  relevance('الأكثر صلة'),
  priceLow('السعر: من الأقل'),
  priceHigh('السعر: من الأعلى'),
  name('الاسم');

  final String label;
  const SearchSortOption(this.label);
}

enum SearchResultType {
  all('الكل'),
  products('المنتجات'),
  stores('المتاجر');

  final String label;
  const SearchResultType(this.label);
}

class SearchFilterModel {
  static const double fallbackMinPrice = SearchFilterOptionsModel.fallbackMinPrice;
  static const double fallbackMaxPrice = SearchFilterOptionsModel.fallbackMaxPrice;

  final String? category;
  final String? categoryId;
  final String? brand;
  final String? brandId;
  final String? department;
  final double minPrice;
  final double maxPrice;
  final double catalogMinPrice;
  final double catalogMaxPrice;
  final DateTime? expiryDate;
  final SearchSortOption sort;
  final SearchResultType resultType;
  final double? minStoreRating;

  const SearchFilterModel({
    this.category,
    this.categoryId,
    this.brand,
    this.brandId,
    this.department,
    this.minPrice = fallbackMinPrice,
    this.maxPrice = fallbackMaxPrice,
    this.catalogMinPrice = fallbackMinPrice,
    this.catalogMaxPrice = fallbackMaxPrice,
    this.expiryDate,
    this.sort = SearchSortOption.relevance,
    this.resultType = SearchResultType.all,
    this.minStoreRating,
  });

  factory SearchFilterModel.withCatalogBounds({
    required double catalogMinPrice,
    required double catalogMaxPrice,
    String? category,
    String? categoryId,
    String? brand,
    String? brandId,
    String? department,
    double? minPrice,
    double? maxPrice,
    DateTime? expiryDate,
    SearchSortOption sort = SearchSortOption.relevance,
    SearchResultType resultType = SearchResultType.all,
    double? minStoreRating,
  }) {
    return SearchFilterModel(
      category: category,
      categoryId: categoryId,
      brand: brand,
      brandId: brandId,
      department: department,
      minPrice: minPrice ?? catalogMinPrice,
      maxPrice: maxPrice ?? catalogMaxPrice,
      catalogMinPrice: catalogMinPrice,
      catalogMaxPrice: catalogMaxPrice,
      expiryDate: expiryDate,
      sort: sort,
      resultType: resultType,
      minStoreRating: minStoreRating,
    );
  }

  bool get hasPriceFilter =>
      minPrice > catalogMinPrice || maxPrice < catalogMaxPrice;

  bool get hasActiveFilters =>
      category != null ||
      categoryId != null ||
      brand != null ||
      brandId != null ||
      department != null ||
      hasPriceFilter ||
      expiryDate != null ||
      sort != SearchSortOption.relevance ||
      resultType != SearchResultType.all ||
      minStoreRating != null;

  SearchFilterModel copyWith({
    String? category,
    bool clearCategory = false,
    String? categoryId,
    bool clearCategoryId = false,
    String? brand,
    bool clearBrand = false,
    String? brandId,
    bool clearBrandId = false,
    String? department,
    bool clearDepartment = false,
    double? minPrice,
    double? maxPrice,
    double? catalogMinPrice,
    double? catalogMaxPrice,
    DateTime? expiryDate,
    bool clearExpiryDate = false,
    SearchSortOption? sort,
    SearchResultType? resultType,
    double? minStoreRating,
    bool clearMinStoreRating = false,
  }) {
    return SearchFilterModel(
      category: clearCategory ? null : (category ?? this.category),
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      brand: clearBrand ? null : (brand ?? this.brand),
      brandId: clearBrandId ? null : (brandId ?? this.brandId),
      department: clearDepartment ? null : (department ?? this.department),
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      catalogMinPrice: catalogMinPrice ?? this.catalogMinPrice,
      catalogMaxPrice: catalogMaxPrice ?? this.catalogMaxPrice,
      expiryDate: clearExpiryDate ? null : (expiryDate ?? this.expiryDate),
      sort: sort ?? this.sort,
      resultType: resultType ?? this.resultType,
      minStoreRating: clearMinStoreRating
          ? null
          : (minStoreRating ?? this.minStoreRating),
    );
  }

  SearchFilterModel clearAll({
    double? catalogMinPrice,
    double? catalogMaxPrice,
  }) {
    final min = catalogMinPrice ?? this.catalogMinPrice;
    final max = catalogMaxPrice ?? this.catalogMaxPrice;
    return SearchFilterModel.withCatalogBounds(
      catalogMinPrice: min,
      catalogMaxPrice: max,
    );
  }

  String formatPrice(double value) {
    return '${_formatPriceNumber(value)} د.ع';
  }

  String get expiryDateLabel {
    if (expiryDate == null) return '2026 / 00 / 00';
    final d = expiryDate!;
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year} / $month / $day';
  }

  /// شارات الفلاتر النشطة لصفحة نتائج الفلترة.
  List<String> get activeFilterLabels {
    final labels = <String>[];
    if (hasPriceFilter) {
      labels.add(
        'السعر ( ${_formatPriceNumber(minPrice)} - ${_formatPriceNumber(maxPrice)} )',
      );
    }
    if (brand != null) labels.add(brand!);
    if (department != null) labels.add(department!);
    if (expiryDate != null) {
      labels.add('تاريخ $expiryDateLabel');
    }
    return labels;
  }

  static String _formatPriceNumber(double value) {
    return value.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
}
