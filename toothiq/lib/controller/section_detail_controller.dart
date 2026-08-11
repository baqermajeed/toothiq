import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/api/api_exception.dart';
import '../model/brand_model.dart';
import '../model/category_model.dart';
import '../model/product_model.dart';
import '../service_layer/services/brand_service.dart';
import '../service_layer/services/product_service.dart';

class SectionDetailController extends GetxController {
  final CategoryModel category;
  final ProductService _productService = Get.find<ProductService>();
  final BrandService _brandService = Get.find<BrandService>();

  SectionDetailController({required this.category});

  final brandSearchController = TextEditingController();
  final selectedTabIndex = 0.obs;

  static const List<String> tabs = [
    'كل المنتجات',
    'البراندات',
    'أدوات التبييض',
  ];

  final brands = <BrandModel>[].obs;
  final filteredBrands = <BrandModel>[].obs;
  final sectionProducts = <ProductModel>[].obs;
  final whiteningProducts = <ProductModel>[].obs;
  final isLoading = false.obs;
  final loadingMore = false.obs;
  final hasNextPage = false.obs;
  final currentPage = 1.obs;
  final loadError = RxnString();
  static const int _pageSize = 12;

  @override
  void onInit() {
    super.onInit();
    brandSearchController.addListener(_onBrandSearch);
    loadSectionData();
  }

  @override
  void onClose() {
    brandSearchController.removeListener(_onBrandSearch);
    brandSearchController.dispose();
    super.onClose();
  }

  void selectTab(int index) {
    selectedTabIndex.value = index;
  }

  void _onBrandSearch() {
    final query = brandSearchController.text.trim();
    if (query.isEmpty) {
      filteredBrands.assignAll(brands);
      return;
    }
    filteredBrands.assignAll(
      brands.where((b) => b.name.contains(query)).toList(),
    );
  }

  Future<void> _syncBrands(List<ProductModel> products) async {
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
    _onBrandSearch();
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

  Future<void> loadSectionData() async {
    isLoading.value = true;
    loadError.value = null;
    try {
      final result = await _productService.fetchProductsPaginated(
        page: 1,
        limit: _pageSize,
        productCategoryId: category.id,
      );
      final products = _productService.filterByCategoryId(
        result.items,
        category.id,
      );

      sectionProducts.assignAll(products);
      whiteningProducts.assignAll(
        products.where((p) => p.name.contains('تبييض')).toList(growable: false),
      );

      await _syncBrands(products);
      hasNextPage.value = result.hasNextPage;
      currentPage.value = result.page;
    } on ApiException catch (error) {
      loadError.value = error.message;
      sectionProducts.clear();
      whiteningProducts.clear();
      brands.clear();
      filteredBrands.clear();
      hasNextPage.value = false;
    } catch (_) {
      loadError.value = 'تعذر تحميل بيانات القسم';
      sectionProducts.clear();
      whiteningProducts.clear();
      brands.clear();
      filteredBrands.clear();
      hasNextPage.value = false;
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
        productCategoryId: category.id,
      );
      final products = _productService.filterByCategoryId(
        result.items,
        category.id,
      );
      sectionProducts.addAll(products);

      whiteningProducts.addAll(
        products.where((p) => p.name.contains('تبييض')).toList(growable: false),
      );

      _mergeBrandsFromProducts(products);

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
    await loadSectionData();
  }
}
