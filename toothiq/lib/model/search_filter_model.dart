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
  static const double defaultMinPrice = 60000;
  static const double defaultMaxPrice = 100000;
  static const double priceSliderMin = 10000;
  static const double priceSliderMax = 150000;

  static const List<String> brandOptions = [
    'الكل',
    'تنظيف أسنان',
    'تنظيف أسنان خاص',
    'حشوات',
    'تقويم شفاف',
    'تقويم شفاف',
    'حشوات',
  ];

  static const List<String> departmentOptions = [
    'الكل',
    'تنظيف أسنان',
    'تنظيف أسنان خاص',
    'حشوات',
    'تقويم شفاف',
    'تقويم شفاف',
    'حشوات',
  ];

  final String? category;
  final String? brand;
  final String? department;
  final double minPrice;
  final double maxPrice;
  final DateTime? expiryDate;
  final SearchSortOption sort;
  final SearchResultType resultType;
  final double? minStoreRating;

  const SearchFilterModel({
    this.category,
    this.brand,
    this.department,
    this.minPrice = defaultMinPrice,
    this.maxPrice = defaultMaxPrice,
    this.expiryDate,
    this.sort = SearchSortOption.relevance,
    this.resultType = SearchResultType.all,
    this.minStoreRating,
  });

  bool get hasActiveFilters =>
      category != null ||
      brand != null ||
      department != null ||
      minPrice != defaultMinPrice ||
      maxPrice != defaultMaxPrice ||
      expiryDate != null ||
      sort != SearchSortOption.relevance ||
      resultType != SearchResultType.all ||
      minStoreRating != null;

  SearchFilterModel copyWith({
    String? category,
    bool clearCategory = false,
    String? brand,
    bool clearBrand = false,
    String? department,
    bool clearDepartment = false,
    double? minPrice,
    double? maxPrice,
    DateTime? expiryDate,
    bool clearExpiryDate = false,
    SearchSortOption? sort,
    SearchResultType? resultType,
    double? minStoreRating,
    bool clearMinStoreRating = false,
  }) {
    return SearchFilterModel(
      category: clearCategory ? null : (category ?? this.category),
      brand: clearBrand ? null : (brand ?? this.brand),
      department: clearDepartment ? null : (department ?? this.department),
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      expiryDate: clearExpiryDate ? null : (expiryDate ?? this.expiryDate),
      sort: sort ?? this.sort,
      resultType: resultType ?? this.resultType,
      minStoreRating: clearMinStoreRating
          ? null
          : (minStoreRating ?? this.minStoreRating),
    );
  }

  SearchFilterModel clearAll() => const SearchFilterModel();

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
    if (minPrice != defaultMinPrice || maxPrice != defaultMaxPrice) {
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
