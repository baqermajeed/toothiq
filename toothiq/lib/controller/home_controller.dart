import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../model/banner_model.dart';
import '../model/brand_model.dart';
import '../model/category_model.dart';
import '../model/product_model.dart';
import '../model/search_filter_model.dart';
import '../model/shop_category_model.dart';
import '../core/api/api_exception.dart';
import '../service_layer/services/banner_service.dart';
import '../service_layer/services/brand_service.dart';
import '../service_layer/services/category_service.dart';
import '../service_layer/services/favorites_service.dart';
import '../service_layer/services/product_service.dart';
import '../view/search/search_filter_page.dart';
import '../view/search/search_results_page.dart';

class HomeController extends GetxController {
  final BannerService _bannerService = Get.find<BannerService>();
  final CategoryService _categoryService = Get.find<CategoryService>();
  final BrandService _brandService = Get.find<BrandService>();
  final ProductService _productService = Get.find<ProductService>();
  final FavoritesService _favoritesService = Get.find<FavoritesService>();

  final searchController = TextEditingController();
  final bannerPageController = PageController();
  final bannerIndex = 0.obs;

  final banners = <BannerModel>[].obs;
  final categories = <CategoryModel>[].obs;
  final brands = <BrandModel>[].obs;
  final products = <ProductModel>[].obs;
  final isLoading = false.obs;
  final loadingMore = false.obs;
  final hasNextPage = false.obs;
  final currentPage = 1.obs;
  final loadError = RxnString();
  static const int _pageSize = 12;

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
      await _loadProductsFirstPage();
    } on ApiException catch (error) {
      loadError.value = error.message;
      banners.clear();
      categories.clear();
      brands.clear();
      products.clear();
      hasNextPage.value = false;
    } catch (_) {
      loadError.value = 'تعذر تحميل بيانات الصفحة الرئيسية';
      banners.clear();
      categories.clear();
      brands.clear();
      products.clear();
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
    currentPage.value = 1;
    final result = await _productService.fetchProductsPaginated(
      page: 1,
      limit: _pageSize,
    );
    products.assignAll(
      _favoritesService.applyFavoriteState(result.items),
    );
    hasNextPage.value = result.hasNextPage;
    currentPage.value = result.page;
  }

  Future<void> loadMoreProducts() async {
    if (loadingMore.value || !hasNextPage.value) return;
    loadingMore.value = true;
    try {
      final nextPage = currentPage.value + 1;
      final result = await _productService.fetchProductsPaginated(
        page: nextPage,
        limit: _pageSize,
      );
      products.addAll(
        _favoritesService.applyFavoriteState(result.items),
      );
      hasNextPage.value = result.hasNextPage;
      currentPage.value = result.page;
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
    if (index == -1) return;
    products[index] = products[index].copyWith(isFavorite: isFavorite);
    products.refresh();
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
