import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/api/api_exception.dart';
import '../model/paginated_result.dart';
import '../model/product_model.dart';
import '../model/search_filter_model.dart';
import '../model/store_model.dart';
import '../service_layer/services/product_service.dart';
import '../service_layer/services/shop_service.dart';

class SearchProductsController extends GetxController {
  final ProductService _productService = Get.find<ProductService>();
  final ShopService _shopService = Get.find<ShopService>();

  final searchFieldController = TextEditingController();
  final scrollController = ScrollController();

  final query = ''.obs;
  final products = <ProductModel>[].obs;
  final stores = <StoreModel>[].obs;
  final loading = false.obs;
  final loadingMore = false.obs;
  final hasNextPage = false.obs;
  final currentPage = 1.obs;
  final loadError = RxnString();
  final hasSearched = false.obs;
  final filter = const SearchFilterModel().obs;
  static const int _pageSize = 12;
  static const double _loadMoreThreshold = 200;

  static const List<String> categoryOptions = [
    'الكل',
    'حشوات',
    'تقويم',
    'تعقيم',
    'أدوات',
  ];

  @override
  void onInit() {
    super.onInit();
    searchFieldController.addListener(() {
      query.value = searchFieldController.text.trim();
    });
    scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!hasNextPage.value || loadingMore.value) return;
    final pos = scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - _loadMoreThreshold) {
      loadMore();
    }
  }

  void setQuery(String value) {
    query.value = value.trim();
  }

  void applyFilter(SearchFilterModel value) {
    filter.value = value;
    if (hasSearched.value) {
      Future.microtask(search);
    }
  }

  void clearFilter() {
    filter.value = const SearchFilterModel();
    if (hasSearched.value) {
      Future.microtask(search);
    }
  }

  bool _isSearching = false;

  Future<void> search() async {
    if (_isSearching) return;
    _isSearching = true;

    final q = query.value.trim();
    hasSearched.value = true;
    final activeFilter = filter.value;

    if (q.isEmpty && !activeFilter.hasActiveFilters) {
      products.clear();
      stores.clear();
      loadError.value = null;
      hasNextPage.value = false;
      currentPage.value = 1;
      loading.value = false;
      _isSearching = false;
      return;
    }

    loading.value = true;
    loadError.value = null;
    currentPage.value = 1;

    try {
      final includeStores = activeFilter.resultType != SearchResultType.products;
      final includeProducts = activeFilter.resultType != SearchResultType.stores;

      final paginatedFuture = q.isNotEmpty
          ? _productService.searchProductsPaginated(
              q,
              page: 1,
              limit: _pageSize,
            )
          : _productService.fetchProductsPaginated(
              page: 1,
              limit: _pageSize,
            );
      final storesFuture = q.isNotEmpty && includeStores
          ? _shopService.searchStoresByQuery(q)
          : Future<List<StoreModel>>.value(const []);

      final results = await Future.wait([
        paginatedFuture,
        storesFuture,
      ]);
      final paginated = results[0] as PaginatedResult<ProductModel>;
      final allStores = results[1] as List<StoreModel>;

      var matchedProducts =
          includeProducts ? paginated.items : <ProductModel>[];
      var matchedStores = allStores;

      if (activeFilter.hasActiveFilters) {
        matchedProducts = matchedProducts
            .where((product) => _matchesProductFilters(product, activeFilter, q))
            .toList();
        matchedStores = matchedStores
            .where((store) => _matchesStoreFilters(store, activeFilter, q))
            .toList();
      }

      matchedProducts = _sortProducts(matchedProducts, activeFilter.sort);

      products.assignAll(matchedProducts);
      stores.assignAll(matchedStores);
      hasNextPage.value = includeProducts ? paginated.hasNextPage : false;
      currentPage.value = paginated.page;
    } on ApiException catch (error) {
      loadError.value = error.message;
      products.clear();
      stores.clear();
      hasNextPage.value = false;
    } catch (_) {
      loadError.value = 'تعذر إكمال البحث حالياً';
      products.clear();
      stores.clear();
      hasNextPage.value = false;
    } finally {
      loading.value = false;
      _isSearching = false;
    }
  }

  Future<void> loadMore() async {
    if (loadingMore.value || !hasNextPage.value) return;
    final q = query.value.trim();
    loadingMore.value = true;
    try {
      final nextPage = currentPage.value + 1;
      final paginated = q.isNotEmpty
          ? await _productService.searchProductsPaginated(
              q,
              page: nextPage,
              limit: _pageSize,
            )
          : await _productService.fetchProductsPaginated(
              page: nextPage,
              limit: _pageSize,
            );
      final activeFilter = filter.value;
      var incoming = paginated.items;
      if (activeFilter.hasActiveFilters) {
        incoming = incoming
            .where((product) => _matchesProductFilters(product, activeFilter, q))
            .toList();
      }
      incoming = _sortProducts(incoming, activeFilter.sort);
      products.addAll(incoming);
      hasNextPage.value = paginated.hasNextPage;
      currentPage.value = paginated.page;
    } catch (_) {
      // لا نعرض خطأ أثناء جلب المزيد.
    } finally {
      loadingMore.value = false;
    }
  }

  void clear() {
    searchFieldController.clear();
    query.value = '';
    products.clear();
    stores.clear();
    hasSearched.value = false;
    loadError.value = null;
    hasNextPage.value = false;
    currentPage.value = 1;
    filter.value = const SearchFilterModel();
  }

  @override
  void onReady() {
    super.onReady();
    final args = Get.arguments;
    if (args is! Map) return;

    final initialQuery = args['query'] as String?;
    final initialFilter = args['filter'] as SearchFilterModel?;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isClosed) {
        initializeFromArguments(
          initialQuery: initialQuery,
          initialFilter: initialFilter,
        );
      }
    });
  }

  void initializeFromArguments({
    String? initialQuery,
    SearchFilterModel? initialFilter,
  }) {
    if (initialFilter != null) {
      filter.value = initialFilter;
    }
    if (initialQuery != null && initialQuery.isNotEmpty) {
      searchFieldController.text = initialQuery;
      query.value = initialQuery;
    }
    if ((initialQuery != null && initialQuery.isNotEmpty) ||
        (initialFilter != null && initialFilter.hasActiveFilters)) {
      Future.microtask(search);
    }
  }

  bool _matchesQuery(String q, List<String> fields) {
    final normalized = q.toLowerCase();
    return fields.any((field) => field.toLowerCase().contains(normalized));
  }

  bool _matchesProductFilters(
    ProductModel product,
    SearchFilterModel activeFilter,
    String q,
  ) {
    if (q.isNotEmpty &&
        !_matchesQuery(q, [
          product.name,
          product.storeName,
          product.description,
        ])) {
      return false;
    }
    if (activeFilter.categoryId != null &&
        activeFilter.categoryId!.isNotEmpty) {
      if (product.productCategoryId != activeFilter.categoryId) return false;
    } else if (!_matchesCategory(
      product,
      activeFilter.department ?? activeFilter.category,
    )) {
      return false;
    }
    if (activeFilter.brandId != null && activeFilter.brandId!.isNotEmpty) {
      if (product.brandId != activeFilter.brandId) return false;
    } else if (!_matchesBrand(product, activeFilter.brand)) {
      return false;
    }
    if (activeFilter.hasPriceFilter &&
        (product.price < activeFilter.minPrice ||
            product.price > activeFilter.maxPrice)) {
      return false;
    }
    if (!_matchesExpiry(product, activeFilter.expiryDate)) return false;
    return true;
  }

  bool _matchesStoreFilters(
    StoreModel store,
    SearchFilterModel activeFilter,
    String q,
  ) {
    if (q.isNotEmpty &&
        !_matchesQuery(q, [store.name, store.description, store.address])) {
      return false;
    }
    if (activeFilter.minStoreRating != null &&
        store.rating < activeFilter.minStoreRating!) {
      return false;
    }
    return true;
  }

  bool _matchesCategory(ProductModel product, String? category) {
    if (category == null || category == 'الكل') return true;

    final text = '${product.name} ${product.description} ${product.storeName}'
        .toLowerCase();

    switch (category) {
      case 'حشوات':
        return text.contains('حشو');
      case 'تقويم':
      case 'تقويم شفاف':
        return text.contains('تقويم');
      case 'تعقيم':
        return text.contains('تعقيم');
      case 'أدوات':
        return text.contains('أداة') ||
            text.contains('أدوات') ||
            text.contains('فرشاة');
      case 'تنظيف أسنان':
      case 'تنظيف أسنان خاص':
        return text.contains('تنظيف') || text.contains('فرشاة');
      default:
        return text.contains(category.toLowerCase());
    }
  }

  bool _matchesBrand(ProductModel product, String? brand) {
    if (brand == null || brand == 'الكل') return true;
    return _matchesCategory(product, brand);
  }

  bool _matchesExpiry(ProductModel product, DateTime? expiryDate) {
    if (expiryDate == null) return true;
    final parts = product.expirationDate
        .split('/')
        .map((e) => e.trim())
        .toList();
    if (parts.length < 3) return true;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return true;
    final productDate = DateTime(year, month, day);
    return !productDate.isAfter(expiryDate);
  }

  List<ProductModel> _sortProducts(
    List<ProductModel> items,
    SearchSortOption sort,
  ) {
    final sorted = List<ProductModel>.from(items);
    switch (sort) {
      case SearchSortOption.priceLow:
        sorted.sort((a, b) => a.price.compareTo(b.price));
      case SearchSortOption.priceHigh:
        sorted.sort((a, b) => b.price.compareTo(a.price));
      case SearchSortOption.name:
        sorted.sort((a, b) => a.name.compareTo(b.name));
      case SearchSortOption.relevance:
        break;
    }
    return sorted;
  }

  int get totalResults => products.length + stores.length;

  @override
  void onClose() {
    searchFieldController.dispose();
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.onClose();
  }
}
