import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/api/api_exception.dart';
import '../model/brand_model.dart';
import '../model/category_model.dart';
import '../model/category_catalog_model.dart';
import '../model/category_section_model.dart';
import '../model/paginated_result.dart';
import '../model/product_model.dart';
import '../model/section_detail_cache_entry.dart';
import '../service_layer/services/brand_service.dart';
import '../service_layer/services/category_service.dart';
import '../service_layer/services/favorites_service.dart';
import '../service_layer/services/product_service.dart';
import '../service_layer/services/section_detail_cache_service.dart';
import '../service_layer/services/shop_service.dart';

class SectionDetailController extends GetxController {
  SectionDetailController({
    required this.category,
    this.shopId,
    this.shopName,
  });

  final CategoryModel category;
  final String? shopId;
  final String? shopName;
  final ProductService _productService = Get.find<ProductService>();
  final BrandService _brandService = Get.find<BrandService>();
  final CategoryService _categoryService = Get.find<CategoryService>();
  final ShopService _shopService = Get.find<ShopService>();
  final FavoritesService _favoritesService = Get.find<FavoritesService>();
  final SectionDetailCacheService _cache = Get.find<SectionDetailCacheService>();

  bool get _isShopScoped =>
      shopId != null && shopId!.isNotEmpty && category.productCategoryId != null;

  bool get _useProductCategoryFilter =>
      _isShopScoped || category.isShopCategory;

  String get _cacheKey =>
      _isShopScoped ? '$shopId:${category.filterId}' : category.filterId;

  final searchController = TextEditingController();
  final selectedTabIndex = 0.obs;

  static const int allProductsTabIndex = 0;
  static const int brandsTabIndex = 1;
  static const int subSectionsStartIndex = 2;

  final subSections = <CategorySectionModel>[].obs;
  final brands = <BrandModel>[].obs;
  final filteredBrands = <BrandModel>[].obs;
  final filteredProducts = <ProductModel>[].obs;
  final sectionProducts = <ProductModel>[].obs;
  final isLoading = false.obs;
  final isRefreshing = false.obs;
  final loadingMore = false.obs;
  final hasNextPage = false.obs;
  final currentPage = 1.obs;
  final loadError = RxnString();
  static const int _pageSize = 12;

  bool get showFullScreenLoading =>
      isLoading.value &&
      sectionProducts.isEmpty &&
      subSections.isEmpty &&
      brands.isEmpty;

  List<String> get tabLabels => [
    'كل المنتجات',
    'البراندات',
    ...subSections.map((section) => section.nameAr),
  ];

  bool get isBrandsTab => selectedTabIndex.value == brandsTabIndex;

  bool get isAllProductsTab => selectedTabIndex.value == allProductsTabIndex;

  bool get isSubSectionTab =>
      selectedTabIndex.value >= subSectionsStartIndex &&
      selectedTabIndex.value < tabLabels.length;

  String get searchHintText {
    if (isBrandsTab) return 'أبحث عن براند محدد ..';
    if (isSubSectionTab) {
      final sectionIndex = selectedTabIndex.value - subSectionsStartIndex;
      if (sectionIndex >= 0 && sectionIndex < subSections.length) {
        return 'أبحث في ${subSections[sectionIndex].nameAr} ..';
      }
      return 'أبحث في القسم الفرعي ..';
    }
    return 'أبحث عن منتج ..';
  }

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_onSearch);
    _initFromCacheOrLoad();
  }

  @override
  void onClose() {
    searchController.removeListener(_onSearch);
    searchController.dispose();
    super.onClose();
  }

  void selectTab(int index) {
    if (index < 0 || index >= tabLabels.length) return;
    if (selectedTabIndex.value == index) return;
    selectedTabIndex.value = index;
    searchController.clear();
    _onSearch();
  }

  void _onSearch() {
    final query = searchController.text.trim().toLowerCase();

    if (isBrandsTab) {
      if (query.isEmpty) {
        filteredBrands.assignAll(brands);
      } else {
        filteredBrands.assignAll(
          brands
              .where((brand) => brand.name.toLowerCase().contains(query))
              .toList(),
        );
      }
      filteredProducts.clear();
      return;
    }

    final baseProducts = _baseProductsForCurrentTab();
    if (query.isEmpty) {
      filteredProducts.assignAll(baseProducts);
      return;
    }

    filteredProducts.assignAll(
      baseProducts
          .where((product) => product.name.toLowerCase().contains(query))
          .toList(),
    );
  }

  List<ProductModel> _baseProductsForCurrentTab() {
    if (isAllProductsTab) return sectionProducts;

    if (isSubSectionTab) {
      final sectionIndex = selectedTabIndex.value - subSectionsStartIndex;
      if (sectionIndex < 0 || sectionIndex >= subSections.length) {
        return sectionProducts;
      }
      final sectionId = subSections[sectionIndex].id;
      return sectionProducts
          .where((product) => product.subcategoryId == sectionId)
          .toList(growable: false);
    }

    return sectionProducts;
  }

  void _initFromCacheOrLoad() {
    final cached = _cache.get(_cacheKey);
    if (cached != null) {
      _restoreFromCache(cached);
      _refreshInBackground();
      return;
    }
    loadSectionData();
  }

  void _restoreFromCache(SectionDetailCacheEntry entry) {
    loadError.value = null;
    sectionProducts.assignAll(
      _favoritesService.applyFavoriteState(entry.products),
    );
    subSections.assignAll(entry.subSections);
    brands.assignAll(entry.brands);
    hasNextPage.value = entry.hasNextPage;
    currentPage.value = entry.currentPage;
    _onSearch();
  }

  void _saveToCache() {
    _cache.put(
      _cacheKey,
      SectionDetailCacheEntry(
        products: List<ProductModel>.from(sectionProducts),
        subSections: List<CategorySectionModel>.from(subSections),
        brands: List<BrandModel>.from(brands),
        hasNextPage: hasNextPage.value,
        currentPage: currentPage.value,
      ),
    );
  }

  Future<void> _applyCatalog(
    CategoryCatalogModel catalog,
    List<ProductModel> products,
  ) async {
    final apiSections = catalog.subSections;
    if (apiSections.isNotEmpty) {
      subSections.assignAll(apiSections);
    } else {
      subSections.assignAll(
        _categoryService.namedSectionsFromProducts(
          categoryId: category.id,
          products: products,
        ),
      );
    }

    if (catalog.brands.isNotEmpty) {
      _applyBrands(catalog.brands);
      return;
    }

    await _syncBrandsFromProducts(products);
  }

  Future<void> _syncBrandsFromProducts(List<ProductModel> products) async {
    try {
      final apiBrands = await _brandService.fetchBrandsByCategory(category.id);
      if (apiBrands.isNotEmpty) {
        _applyBrands(apiBrands);
        return;
      }
    } catch (_) {
      // نكمل باستخراج البراندات من المنتجات.
    }

    _applyBrands(_brandService.brandsFromProducts(products));
  }

  void _applyBrands(List<BrandModel> mappedBrands) {
    brands.assignAll(mappedBrands);
    _onSearch();
  }

  void _mergeBrandsFromProducts(List<ProductModel> products) {
    if (brands.isEmpty) {
      _applyBrands(_brandService.brandsFromProducts(products));
      return;
    }

    final existingIds = brands.map((brand) => brand.id).toSet();
    final merged = List<BrandModel>.from(brands);
    for (final brand in _brandService.brandsFromProducts(products)) {
      if (existingIds.add(brand.id)) {
        merged.add(brand);
      }
    }
    _applyBrands(merged);
  }

  Future<void> _fetchAndApply({
    required bool resetUiState,
    required bool showLoading,
  }) async {
    if (showLoading) {
      isLoading.value = true;
    }
    if (resetUiState) {
      loadError.value = null;
      selectedTabIndex.value = allProductsTabIndex;
      searchController.clear();
      subSections.clear();
      brands.clear();
      filteredBrands.clear();
      filteredProducts.clear();
      sectionProducts.clear();
    }

    try {
      if (_isShopScoped) {
        final productsResult = await _shopService.fetchShopProductsPaginated(
          shopId: shopId!,
          shopName: shopName ?? '',
          page: 1,
          limit: _pageSize,
          productCategoryId: category.filterId,
        );
        final products = _favoritesService.applyFavoriteState(productsResult.items);
        sectionProducts.assignAll(products);
        subSections.clear();
        await _syncBrandsFromProducts(products);
        _onSearch();
        hasNextPage.value = productsResult.hasNextPage;
        currentPage.value = productsResult.page;
        loadError.value = null;
        _saveToCache();
        return;
      }

      final filterId = category.filterId;
      final results = await Future.wait([
        _fetchProductsPage(1),
        if (!_isShopScoped && !category.isShopCategory)
          _categoryService.fetchCategoryCatalog(filterId)
        else
          Future.value(CategoryCatalogModel.empty),
      ]);

      final productsResult = results[0] as PaginatedResult<ProductModel>;
      final catalog = results[1] as CategoryCatalogModel;
      final products = _normalizeProducts(productsResult.items);

      sectionProducts.assignAll(_favoritesService.applyFavoriteState(products));
      await _applyCatalog(catalog, products);
      _onSearch();

      hasNextPage.value = productsResult.hasNextPage;
      currentPage.value = productsResult.page;
      loadError.value = null;
      _saveToCache();
    } on ApiException catch (error) {
      if (resetUiState || sectionProducts.isEmpty) {
        loadError.value = error.message;
        sectionProducts.clear();
        subSections.clear();
        brands.clear();
        filteredBrands.clear();
        filteredProducts.clear();
        hasNextPage.value = false;
      }
    } catch (_) {
      if (resetUiState || sectionProducts.isEmpty) {
        loadError.value = 'تعذر تحميل بيانات القسم';
        sectionProducts.clear();
        subSections.clear();
        brands.clear();
        filteredBrands.clear();
        filteredProducts.clear();
        hasNextPage.value = false;
      }
    } finally {
      if (showLoading) {
        isLoading.value = false;
      }
    }
  }

  Future<void> _refreshInBackground() async {
    if (isRefreshing.value) return;
    isRefreshing.value = true;

    try {
      if (currentPage.value > 1) {
        final catalog = await _categoryService.fetchCategoryCatalog(category.id);
        await _applyCatalog(catalog, sectionProducts.toList(growable: false));
        _saveToCache();
        return;
      }

      await _fetchAndApply(resetUiState: false, showLoading: false);
    } catch (_) {
      // نُبقي البيانات المخزنة عند فشل التحديث بالخلفية.
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<void> loadSectionData() async {
    await _fetchAndApply(resetUiState: true, showLoading: true);
  }

  Future<void> loadMore() async {
    if (loadingMore.value || !hasNextPage.value || isBrandsTab) return;
    loadingMore.value = true;
    try {
      final nextPage = currentPage.value + 1;
      final result = await _fetchProductsPage(nextPage);
      final products = _normalizeProducts(result.items);
      sectionProducts.addAll(_favoritesService.applyFavoriteState(products));
      _mergeBrandsFromProducts(products);

      if (subSections.isEmpty && !_isShopScoped && !category.isShopCategory) {
        subSections.assignAll(
          _categoryService.namedSectionsFromProducts(
            categoryId: category.filterId,
            products: sectionProducts,
          ),
        );
      }
      _onSearch();
      _saveToCache();

      hasNextPage.value = result.hasNextPage;
      currentPage.value = result.page;
    } catch (_) {
      // لا نعرض خطأ في جلب المزيد.
    } finally {
      loadingMore.value = false;
    }
  }

  Future<PaginatedResult<ProductModel>> _fetchProductsPage(int page) {
    if (_isShopScoped) {
      return _shopService.fetchShopProductsPaginated(
        shopId: shopId!,
        shopName: shopName ?? '',
        page: page,
        limit: _pageSize,
        productCategoryId: category.filterId,
      );
    }

    final filterId = category.filterId;
    return _productService.fetchProductsPaginated(
      page: page,
      limit: _pageSize,
      productCategoryId: _useProductCategoryFilter ? filterId : null,
      categoryId: _useProductCategoryFilter ? null : filterId,
    );
  }

  List<ProductModel> _normalizeProducts(List<ProductModel> items) {
    if (_isShopScoped || _useProductCategoryFilter) return items;
    return _productService.filterByCategoryId(items, category.filterId);
  }

  void updateFavoriteState(String productId, bool isFavorite) {
    void patch(RxList<ProductModel> list) {
      final index = list.indexWhere((product) => product.id == productId);
      if (index == -1) return;
      list[index] = list[index].copyWith(isFavorite: isFavorite);
    }

    patch(sectionProducts);
    patch(filteredProducts);
    sectionProducts.refresh();
    filteredProducts.refresh();
  }

  @override
  Future<void> refresh() async {
    await loadSectionData();
  }
}
