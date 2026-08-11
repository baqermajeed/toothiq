import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../model/banner_model.dart';
import '../model/home_category_model.dart';
import '../model/product_model.dart';
import '../model/search_filter_model.dart';
import '../model/shop_category_model.dart';
import '../core/api/api_exception.dart';
import '../service_layer/services/banner_service.dart';
import '../service_layer/services/category_service.dart';
import '../service_layer/services/product_service.dart';
import '../view/search/search_filter_page.dart';
import '../view/search/search_results_page.dart';

class HomeController extends GetxController {
  final BannerService _bannerService = Get.find<BannerService>();
  final CategoryService _categoryService = Get.find<CategoryService>();
  final ProductService _productService = Get.find<ProductService>();

  final searchController = TextEditingController();
  final bannerPageController = PageController();
  final productsScrollController = ScrollController();
  final bannerIndex = 0.obs;
  final selectedCategoryIndex = 0.obs;
  final hasNotification = true.obs;

  final banners = <BannerModel>[].obs;
  final categories = <HomeCategoryModel>[const HomeCategoryModel.all()].obs;
  final products = <ProductModel>[].obs;
  final isLoading = false.obs;
  final isCategoryLoading = false.obs;
  final loadingMore = false.obs;
  final hasNextPage = false.obs;
  final currentPage = 1.obs;
  final loadError = RxnString();
  static const int _pageSize = 12;
  static const double _loadMoreThreshold = 200;

  @override
  void onInit() {
    super.onInit();
    productsScrollController.addListener(_onProductsScroll);
    loadHome();
  }

  @override
  void onClose() {
    searchController.dispose();
    bannerPageController.dispose();
    productsScrollController.removeListener(_onProductsScroll);
    productsScrollController.dispose();
    super.onClose();
  }

  void _onProductsScroll() {
    if (!hasNextPage.value || loadingMore.value) return;
    final pos = productsScrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - _loadMoreThreshold) {
      loadMoreProducts();
    }
  }

  Future<void> loadHome() async {
    isLoading.value = true;
    loadError.value = null;

    try {
      final results = await Future.wait([
        _bannerService.fetchActiveBanners(),
        _categoryService.fetchCategories(),
      ]);

      banners.assignAll(results[0] as List<BannerModel>);
      _applyCategories(results[1] as List<ShopCategoryModel>);
      await _loadProductsFirstPage();
    } on ApiException catch (error) {
      loadError.value = error.message;
      banners.clear();
      categories.assignAll([const HomeCategoryModel.all()]);
      products.clear();
      hasNextPage.value = false;
    } catch (_) {
      loadError.value = 'تعذر تحميل بيانات الصفحة الرئيسية';
      banners.clear();
      categories.assignAll([const HomeCategoryModel.all()]);
      products.clear();
      hasNextPage.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  void _applyCategories(List<ShopCategoryModel> apiCategories) {
    final mapped = apiCategories
        .where((category) => category.nameAr.isNotEmpty)
        .map(
          (category) =>
              HomeCategoryModel(id: category.id, name: category.nameAr),
        )
        .toList();

    categories.assignAll([const HomeCategoryModel.all(), ...mapped]);

    if (selectedCategoryIndex.value >= categories.length) {
      selectedCategoryIndex.value = 0;
    }
  }

  Future<void> selectCategory(int index) async {
    selectedCategoryIndex.value = index;
    if (index >= categories.length) return;

    isCategoryLoading.value = true;
    loadError.value = null;

    try {
      await _loadProductsFirstPage();
    } on ApiException catch (error) {
      loadError.value = error.message;
      products.clear();
      hasNextPage.value = false;
    } catch (_) {
      loadError.value = 'تعذر تحميل منتجات هذا القسم';
      products.clear();
      hasNextPage.value = false;
    } finally {
      isCategoryLoading.value = false;
    }
  }

  @override
  Future<void> refresh() async {
    await loadHome();
  }

  Future<void> _loadProductsFirstPage() async {
    currentPage.value = 1;
    final category = categories[selectedCategoryIndex.value];
    final result = await _productService.fetchProductsPaginated(
      page: 1,
      limit: _pageSize,
      productCategoryId: category.isAll ? null : category.id,
    );
    products.assignAll(
      _productService.filterByCategoryId(
        result.items,
        category.isAll ? null : category.id,
      ),
    );
    hasNextPage.value = result.hasNextPage;
    currentPage.value = result.page;
  }

  Future<void> loadMoreProducts() async {
    if (loadingMore.value || !hasNextPage.value) return;
    loadingMore.value = true;
    try {
      final nextPage = currentPage.value + 1;
      final category = categories[selectedCategoryIndex.value];
      final result = await _productService.fetchProductsPaginated(
        page: nextPage,
        limit: _pageSize,
        productCategoryId: category.isAll ? null : category.id,
      );
      products.addAll(
        _productService.filterByCategoryId(
          result.items,
          category.isAll ? null : category.id,
        ),
      );
      hasNextPage.value = result.hasNextPage;
      currentPage.value = result.page;
    } catch (_) {
      // لا نعرض خطأ لجلب المزيد.
    } finally {
      loadingMore.value = false;
    }
  }

  void toggleFavorite(String productId) {
    final index = products.indexWhere((p) => p.id == productId);
    if (index == -1) return;
    products[index] = products[index].copyWith(
      isFavorite: !products[index].isFavorite,
    );
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
