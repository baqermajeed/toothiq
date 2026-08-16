import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../model/banner_model.dart';
import '../model/brand_model.dart';
import '../model/category_model.dart';
import '../model/home_feed_tab.dart';
import '../model/paginated_result.dart';
import '../model/product_model.dart';
import '../model/search_filter_model.dart';
import '../model/shop_category_model.dart';
import '../model/store_model.dart';
import '../core/api/api_exception.dart';
import '../service_layer/services/banner_service.dart';
import '../service_layer/services/brand_service.dart';
import '../service_layer/services/category_service.dart';
import '../service_layer/services/favorites_service.dart';
import '../service_layer/services/product_service.dart';
import '../service_layer/services/shop_service.dart';
import '../view/search/search_filter_page.dart';
import '../view/search/search_results_page.dart';

class HomeController extends GetxController {
  final BannerService _bannerService = Get.find<BannerService>();
  final CategoryService _categoryService = Get.find<CategoryService>();
  final BrandService _brandService = Get.find<BrandService>();
  final ProductService _productService = Get.find<ProductService>();
  final ShopService _shopService = Get.find<ShopService>();
  final FavoritesService _favoritesService = Get.find<FavoritesService>();

  final searchController = TextEditingController();
  final bannerPageController = PageController();
  final bannerIndex = 0.obs;

  final banners = <BannerModel>[].obs;
  final categories = <CategoryModel>[].obs;
  final brands = <BrandModel>[].obs;
  final products = <ProductModel>[].obs;
  final shops = <StoreModel>[].obs;
  final selectedFeed = HomeFeedTab.all.obs;
  final isLoading = false.obs;
  final feedLoading = false.obs;
  final loadingMore = false.obs;
  final hasNextPage = false.obs;
  final currentPage = 1.obs;
  final loadError = RxnString();
  static const int _pageSize = 12;
  final _feedCaches = <HomeFeedTab, _HomeFeedCache>{};
  final _feedRequestIds = <HomeFeedTab, int>{};

  @override
  void onInit() {
    super.onInit();
    loadHome();
  }

  @override
  void onClose() {
    searchController.dispose();
    bannerPageController.dispose();
    super.onClose();
  }

  Future<void> loadHome() async {
    final hasVisibleData =
        products.isNotEmpty || shops.isNotEmpty || banners.isNotEmpty;
    if (!hasVisibleData) isLoading.value = true;
    loadError.value = null;

    try {
      final results = await Future.wait([
        _bannerService.fetchActiveBanners(),
        _categoryService.fetchCategories(),
        _fetchBrandsSafely(),
      ]);

      banners.assignAll(results[0] as List<BannerModel>);
      _applyCategories(results[1] as List<ShopCategoryModel>);
      brands.assignAll(results[2] as List<BrandModel>);
      await _refreshTab(
        selectedFeed.value,
        silent: _feedCaches.containsKey(selectedFeed.value),
        replace: true,
      );
    } on ApiException catch (error) {
      loadError.value = error.message;
      if (!hasVisibleData) {
        banners.clear();
        categories.clear();
        brands.clear();
        products.clear();
        shops.clear();
        hasNextPage.value = false;
      }
    } catch (_) {
      loadError.value = 'تعذر تحميل بيانات الصفحة الرئيسية';
      if (!hasVisibleData) {
        banners.clear();
        categories.clear();
        brands.clear();
        products.clear();
        shops.clear();
        hasNextPage.value = false;
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<BrandModel>> _fetchBrandsSafely() async {
    try {
      final data = await _brandService.fetchAllBrands();
      return data.where((brand) => brand.name.trim().isNotEmpty).toList();
    } catch (_) {
      return const [];
    }
  }

  void _applyCategories(List<ShopCategoryModel> apiCategories) {
    final mapped = apiCategories
        .asMap()
        .entries
        .where((entry) => entry.value.nameAr.isNotEmpty)
        .map(
          (entry) => CategoryModel.fromShopCategory(
            entry.value,
            index: entry.key,
          ),
        )
        .toList();

    categories.assignAll(mapped);
  }

  @override
  Future<void> refresh() async {
    await loadHome();
  }

  Future<void> selectFeed(HomeFeedTab tab) async {
    if (selectedFeed.value == tab) return;
    selectedFeed.value = tab;
    loadingMore.value = false;
    final cached = _feedCaches[tab];
    if (cached != null) {
      _applyCacheToUi(tab);
      feedLoading.value = false;
      final rotateAll = tab == HomeFeedTab.all &&
          cached.rotationKey != _baghdadDayKey();
      await _refreshTab(tab, silent: true, replace: rotateAll);
      return;
    }
    products.clear();
    shops.clear();
    hasNextPage.value = false;
    currentPage.value = 1;
    await _refreshTab(tab, silent: false);
  }

  void _applyCacheToUi(HomeFeedTab tab) {
    if (selectedFeed.value != tab) return;
    final cache = _feedCaches[tab];
    if (cache == null) {
      products.clear();
      shops.clear();
      currentPage.value = 1;
      hasNextPage.value = false;
      return;
    }
    if (tab.showsShops) {
      shops.assignAll(cache.shops);
      products.clear();
    } else {
      products.assignAll(
        _favoritesService.applyFavoriteState(cache.products),
      );
      shops.clear();
    }
    currentPage.value = cache.page;
    hasNextPage.value = cache.hasNextPage;
  }

  Future<void> _refreshTab(
    HomeFeedTab tab, {
    required bool silent,
    bool replace = false,
  }) async {
    final requestId = (_feedRequestIds[tab] ?? 0) + 1;
    _feedRequestIds[tab] = requestId;
    if (!silent && selectedFeed.value == tab) {
      feedLoading.value = true;
    }
    try {
      if (tab.showsShops) {
        final result = await _shopService.fetchTopRatedShops(
          page: 1,
          limit: _pageSize,
        );
        if (_feedRequestIds[tab] != requestId) return;
        _storeShopPage(tab, result, replace: replace);
      } else {
        final result = await _fetchFeedProducts(tab, page: 1);
        if (_feedRequestIds[tab] != requestId) return;
        _storeProductPage(tab, result, replace: replace);
      }
      if (selectedFeed.value == tab) _applyCacheToUi(tab);
    } catch (_) {
      if (!silent &&
          selectedFeed.value == tab &&
          !_feedCaches.containsKey(tab)) {
        products.clear();
        shops.clear();
        hasNextPage.value = false;
      }
    } finally {
      if (selectedFeed.value == tab && _feedRequestIds[tab] == requestId) {
        feedLoading.value = false;
      }
    }
  }

  void _storeProductPage(
    HomeFeedTab tab,
    PaginatedResult<ProductModel> result, {
    required bool replace,
  }) {
    final fresh = _favoritesService.applyFavoriteState(result.items);
    final cache = _feedCaches.putIfAbsent(tab, () => _HomeFeedCache());
    if (replace || cache.products.length <= _pageSize) {
      cache.products = List<ProductModel>.from(fresh);
      cache.page = result.page;
      cache.hasNextPage = result.hasNextPage;
      cache.rotationKey = _baghdadDayKey();
      return;
    }
    final freshIds = fresh.map((item) => item.id).toSet();
    final extras = cache.products
        .skip(_pageSize)
        .where((item) => !freshIds.contains(item.id));
    cache.products = [...fresh, ...extras];
    cache.hasNextPage = result.hasNextPage || cache.hasNextPage;
    cache.rotationKey = _baghdadDayKey();
  }

  void _storeShopPage(
    HomeFeedTab tab,
    PaginatedResult<StoreModel> result, {
    required bool replace,
  }) {
    final cache = _feedCaches.putIfAbsent(tab, () => _HomeFeedCache());
    if (replace || cache.shops.length <= _pageSize) {
      cache.shops = List<StoreModel>.from(result.items);
      cache.page = result.page;
      cache.hasNextPage = result.hasNextPage;
      return;
    }
    final freshIds = result.items.map((item) => item.id).toSet();
    final extras = cache.shops
        .skip(_pageSize)
        .where((item) => !freshIds.contains(item.id));
    cache.shops = [...result.items, ...extras];
    cache.hasNextPage = result.hasNextPage || cache.hasNextPage;
  }

  Future<PaginatedResult<ProductModel>> _fetchFeedProducts(
    HomeFeedTab tab, {
    required int page,
  }) {
    switch (tab) {
      case HomeFeedTab.all:
        return _productService.fetchProductsPaginated(page: page, limit: _pageSize);
      case HomeFeedTab.offers:
        return _productService.fetchOffers(page: page, limit: _pageSize);
      case HomeFeedTab.bestSellers:
        return _productService.fetchBestSellers(page: page, limit: _pageSize);
      case HomeFeedTab.forYou:
        return _productService.fetchForYou(page: page, limit: _pageSize);
      case HomeFeedTab.newest:
        return _productService.fetchNewProducts(page: page, limit: _pageSize);
      case HomeFeedTab.topRated:
        return _productService.fetchProductsPaginated(page: page, limit: _pageSize);
    }
  }

  Future<void> loadMoreProducts() async {
    final tab = selectedFeed.value;
    if (loadingMore.value || !hasNextPage.value) return;
    loadingMore.value = true;
    try {
      final nextPage = currentPage.value + 1;
      final cache = _feedCaches.putIfAbsent(tab, () => _HomeFeedCache());
      if (tab.showsShops) {
        final result = await _shopService.fetchTopRatedShops(
          page: nextPage,
          limit: _pageSize,
        );
        final existingIds = cache.shops.map((item) => item.id).toSet();
        cache.shops.addAll(
          result.items.where((item) => existingIds.add(item.id)),
        );
        cache.page = result.page;
        cache.hasNextPage = result.hasNextPage;
      } else {
        final result = await _fetchFeedProducts(tab, page: nextPage);
        final fresh = _favoritesService.applyFavoriteState(result.items);
        final existingIds = cache.products.map((item) => item.id).toSet();
        cache.products.addAll(
          fresh.where((item) => existingIds.add(item.id)),
        );
        cache.page = result.page;
        cache.hasNextPage = result.hasNextPage;
      }
      if (selectedFeed.value == tab) _applyCacheToUi(tab);
    } catch (_) {
      // لا نعرض خطأ لجلب المزيد.
    } finally {
      if (selectedFeed.value == tab) loadingMore.value = false;
    }
  }

  Future<void> toggleFavorite(String productId) async {
    final index = products.indexWhere((p) => p.id == productId);
    if (index == -1) return;
    final isFavorite = await _favoritesService.toggle(products[index]);
    updateFavoriteState(productId, isFavorite);
  }

  void updateFavoriteState(String productId, bool isFavorite) {
    final index = products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      products[index] = products[index].copyWith(isFavorite: isFavorite);
      products.refresh();
    }
    for (final cache in _feedCaches.values) {
      final cachedIndex = cache.products.indexWhere((p) => p.id == productId);
      if (cachedIndex != -1) {
        cache.products[cachedIndex] =
            cache.products[cachedIndex].copyWith(isFavorite: isFavorite);
      }
    }
  }

  void onBannerChanged(int index) {
    bannerIndex.value = index;
  }

  void submitSearch() {
    final query = searchController.text.trim();
    if (query.isEmpty) return;
    SearchResultsPage.open(query: query);
  }

  Future<void> onFilterTap() async {
    final result = await SearchFilterPage.open(
      initialFilter: const SearchFilterModel(),
      searchQuery: searchController.text.trim(),
      navigateToResultsOnApply: true,
    );
    if (result == null) return;
  }
}

String _baghdadDayKey() {
  final day = DateTime.now().toUtc().add(const Duration(hours: 3));
  final y = day.year.toString().padLeft(4, '0');
  final m = day.month.toString().padLeft(2, '0');
  final d = day.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

class _HomeFeedCache {
  List<ProductModel> products = [];
  List<StoreModel> shops = [];
  int page = 1;
  bool hasNextPage = false;
  String? rotationKey;
}
