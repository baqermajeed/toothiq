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
  final offerProducts = <ProductModel>[].obs;
  final selectedFeed = HomeFeedTab.all.obs;
  final isLoading = false.obs;
  final feedLoading = false.obs;
  final loadingMore = false.obs;
  final hasNextPage = false.obs;
  final currentPage = 1.obs;
  final loadError = RxnString();
  static const int _pageSize = 12;
  int _feedRequestId = 0;

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
    isLoading.value = true;
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
      await Future.wait([
        _loadProductsFirstPage(),
        _loadOfferProducts(),
      ]);
    } on ApiException catch (error) {
      loadError.value = error.message;
      banners.clear();
      categories.clear();
      brands.clear();
      products.clear();
      shops.clear();
      offerProducts.clear();
      hasNextPage.value = false;
    } catch (_) {
      loadError.value = 'تعذر تحميل بيانات الصفحة الرئيسية';
      banners.clear();
      categories.clear();
      brands.clear();
      products.clear();
      shops.clear();
      offerProducts.clear();
      hasNextPage.value = false;
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

  Future<void> _loadProductsFirstPage() async {
    await _loadFeedFirstPage();
  }

  Future<void> selectFeed(HomeFeedTab tab) async {
    if (selectedFeed.value == tab) return;
    selectedFeed.value = tab;
    products.clear();
    shops.clear();
    hasNextPage.value = false;
    await _loadFeedFirstPage();
  }

  Future<void> _loadFeedFirstPage() async {
    final requestId = ++_feedRequestId;
    currentPage.value = 1;
    feedLoading.value = true;
    try {
      if (selectedFeed.value.showsShops) {
        final result = await _shopService.fetchTopRatedShops(
          page: 1,
          limit: _pageSize,
        );
        if (requestId != _feedRequestId) return;
        shops.assignAll(result.items);
        products.clear();
        hasNextPage.value = result.hasNextPage;
        currentPage.value = result.page;
        return;
      }
      shops.clear();
      final result = await _fetchFeedProducts(page: 1);
      if (requestId != _feedRequestId) return;
      products.assignAll(_favoritesService.applyFavoriteState(result.items));
      hasNextPage.value = result.hasNextPage;
      currentPage.value = result.page;
    } catch (_) {
      if (requestId != _feedRequestId) return;
      products.clear();
      shops.clear();
      hasNextPage.value = false;
    } finally {
      if (requestId == _feedRequestId) {
        feedLoading.value = false;
      }
    }
  }

  Future<PaginatedResult<ProductModel>> _fetchFeedProducts({required int page}) {
    switch (selectedFeed.value) {
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

  Future<void> _loadOfferProducts() async {
    try {
      final result = await _productService.fetchOffers(page: 1, limit: 10);
      offerProducts.assignAll(
        _favoritesService.applyFavoriteState(result.items),
      );
    } catch (_) {
      offerProducts.clear();
    }
  }

  Future<void> loadMoreProducts() async {
    if (loadingMore.value || !hasNextPage.value) return;
    loadingMore.value = true;
    try {
      final nextPage = currentPage.value + 1;
      if (selectedFeed.value.showsShops) {
        final result = await _shopService.fetchTopRatedShops(
          page: nextPage,
          limit: _pageSize,
        );
        shops.addAll(result.items);
        hasNextPage.value = result.hasNextPage;
        currentPage.value = result.page;
      } else {
        final result = await _fetchFeedProducts(page: nextPage);
        products.addAll(_favoritesService.applyFavoriteState(result.items));
        hasNextPage.value = result.hasNextPage;
        currentPage.value = result.page;
      }
    } catch (_) {
      // لا نعرض خطأ لجلب المزيد.
    } finally {
      loadingMore.value = false;
    }
  }

  Future<void> toggleFavorite(String productId) async {
    final index = products.indexWhere((p) => p.id == productId);
    if (index == -1) return;
    final isFavorite = await _favoritesService.toggle(products[index]);
    products[index] = products[index].copyWith(isFavorite: isFavorite);
    products.refresh();
  }

  void updateFavoriteState(String productId, bool isFavorite) {
    final index = products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      products[index] = products[index].copyWith(isFavorite: isFavorite);
      products.refresh();
    }
    final offerIndex = offerProducts.indexWhere((p) => p.id == productId);
    if (offerIndex != -1) {
      offerProducts[offerIndex] =
          offerProducts[offerIndex].copyWith(isFavorite: isFavorite);
      offerProducts.refresh();
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
