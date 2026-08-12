import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/api/api_exception.dart';
import '../model/brand_model.dart';
import '../model/product_model.dart';
import '../service_layer/services/favorites_service.dart';
import '../service_layer/services/product_service.dart';

class BrandProductsController extends GetxController {
  BrandProductsController({
    required this.brand,
    required List<ProductModel> initialProducts,
    this.categoryId,
  }) : _initialProducts = initialProducts;

  final BrandModel brand;
  final String? categoryId;
  final List<ProductModel> _initialProducts;
  final ProductService _productService = Get.find<ProductService>();
  final FavoritesService _favoritesService = Get.find<FavoritesService>();

  final searchController = TextEditingController();
  final allProducts = <ProductModel>[].obs;
  final filteredProducts = <ProductModel>[].obs;
  final scrollController = ScrollController();
  final isLoading = false.obs;
  final loadingMore = false.obs;
  final hasNextPage = false.obs;
  final currentPage = 1.obs;
  final loadError = RxnString();

  static const int _pageSize = 12;
  static const double _loadMoreThreshold = 200;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_onSearch);
    scrollController.addListener(_onScroll);
    loadProducts();
  }

  @override
  void onClose() {
    searchController.removeListener(_onSearch);
    searchController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  void _onSearch() {
    final query = searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      filteredProducts.assignAll(allProducts);
      return;
    }

    filteredProducts.assignAll(
      allProducts
          .where((product) => product.name.toLowerCase().contains(query))
          .toList(),
    );
  }

  void _onScroll() {
    if (!scrollController.hasClients) return;
    final position = scrollController.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
      loadMore();
    }
  }

  List<ProductModel> _filterByBrand(List<ProductModel> source) {
    final brandId = brand.id.trim();
    if (brandId.isEmpty) return [];

    return source
        .where((product) => product.brandId?.trim() == brandId)
        .toList(growable: false);
  }

  void _setProducts(List<ProductModel> items) {
    allProducts.assignAll(_favoritesService.applyFavoriteState(items));
    _onSearch();
  }

  Future<void> loadProducts() async {
    isLoading.value = true;
    loadError.value = null;
    currentPage.value = 1;
    searchController.clear();

    final cached = _filterByBrand(_initialProducts);
    if (cached.isNotEmpty) {
      _setProducts(cached);
    }

    try {
      final result = await _productService.fetchProductsPaginated(
        page: 1,
        limit: _pageSize,
        productCategoryId: categoryId,
        brandId: brand.id,
      );
      final filtered = _filterByBrand(
        _productService.filterByCategoryId(result.items, categoryId),
      );
      if (filtered.isNotEmpty) {
        _setProducts(filtered);
      } else if (cached.isEmpty) {
        allProducts.clear();
        filteredProducts.clear();
      }
      hasNextPage.value = result.hasNextPage;
      currentPage.value = result.page;
    } on ApiException catch (error) {
      if (allProducts.isEmpty) loadError.value = error.message;
    } catch (_) {
      if (allProducts.isEmpty) {
        loadError.value = 'تعذر تحميل منتجات البراند';
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (loadingMore.value || !hasNextPage.value) return;
    loadingMore.value = true;
    try {
      final nextPage = currentPage.value + 1;
      final result = await _productService.fetchProductsPaginated(
        page: nextPage,
        limit: _pageSize,
        productCategoryId: categoryId,
        brandId: brand.id,
      );
      allProducts.addAll(
        _favoritesService.applyFavoriteState(
          _filterByBrand(
            _productService.filterByCategoryId(result.items, categoryId),
          ),
        ),
      );
      _onSearch();
      hasNextPage.value = result.hasNextPage;
      currentPage.value = result.page;
    } catch (_) {
      // لا نعرض خطأ في جلب المزيد.
    } finally {
      loadingMore.value = false;
    }
  }

  void updateFavoriteState(String productId, bool isFavorite) {
    void patch(RxList<ProductModel> list) {
      final index = list.indexWhere((product) => product.id == productId);
      if (index == -1) return;
      list[index] = list[index].copyWith(isFavorite: isFavorite);
    }

    patch(allProducts);
    patch(filteredProducts);
    allProducts.refresh();
    filteredProducts.refresh();
  }

  @override
  Future<void> refresh() async {
    await loadProducts();
  }
}
