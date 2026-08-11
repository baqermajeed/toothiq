import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/api/api_exception.dart';
import '../model/brand_model.dart';
import '../model/product_model.dart';
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

  final products = <ProductModel>[].obs;
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
    scrollController.addListener(_onScroll);
    loadProducts();
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
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

  Future<void> loadProducts() async {
    isLoading.value = true;
    loadError.value = null;
    currentPage.value = 1;

    final cached = _filterByBrand(_initialProducts);
    if (cached.isNotEmpty) {
      products.assignAll(cached);
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
        products.assignAll(filtered);
      }
      hasNextPage.value = result.hasNextPage;
      currentPage.value = result.page;
    } on ApiException catch (error) {
      if (products.isEmpty) loadError.value = error.message;
    } catch (_) {
      if (products.isEmpty) {
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
      products.addAll(
        _filterByBrand(
          _productService.filterByCategoryId(result.items, categoryId),
        ),
      );
      hasNextPage.value = result.hasNextPage;
      currentPage.value = result.page;
    } catch (_) {
      // لا نعرض خطأ في جلب المزيد.
    } finally {
      loadingMore.value = false;
    }
  }

  @override
  Future<void> refresh() async {
    await loadProducts();
  }
}
