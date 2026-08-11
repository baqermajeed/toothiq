import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'auth_controller.dart';
import '../models/product.dart';
import '../models/shop.dart';

/// تحكم شاشة منتجات المحل — Shop من Get.arguments، مع pagination.
class ShopProductsController extends GetxController {
  final Rxn<Shop> shop = Rxn<Shop>();
  final RxList<Product> products = <Product>[].obs;
  final RxBool loading = true.obs;
  final RxBool loadingMore = false.obs;
  final RxBool hasNextPage = false.obs;
  final RxInt currentPage = 1.obs;
  final Rxn<String> error = Rxn<String>();
  final ScrollController scrollController = ScrollController();

  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = ''.obs;

  static const int _pageSize = 20;
  static const double _loadMoreThreshold = 200;

  static Shop _shopFromArguments(dynamic arguments) {
    if (arguments == null) {
      return const Shop(id: '', name: 'محل', category: '');
    }
    if (arguments is Shop) return arguments;
    if (arguments is Map<String, dynamic>) {
      return Shop.fromJson(arguments);
    }
    return Shop.fromJson(Map<String, dynamic>.from(arguments as Map));
  }

  @override
  void onInit() {
    super.onInit();
    shop.value = _shopFromArguments(Get.arguments);
    scrollController.addListener(_onScroll);
    loadProducts();
  }

  @override
  void onClose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    searchController.dispose();
    super.onClose();
  }

  void _onScroll() {
    if (!hasNextPage.value || loadingMore.value) return;
    final pos = scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - _loadMoreThreshold) {
      loadMore();
    }
  }

  Future<void> loadProducts() async {
    final s = shop.value;
    if (s == null || s.id.isEmpty) {
      loading.value = false;
      error.value = 'لم يُحدد المحل';
      return;
    }
    loading.value = true;
    error.value = null;
    currentPage.value = 1;
    try {
      final apiClient = Get.find<AuthController>().apiClient;
      final result = await apiClient.getProductsByShop(
        s.id,
        shopName: s.name,
        page: 1,
        limit: _pageSize,
        query: searchQuery.value,
      );
      products.value = result.items;
      hasNextPage.value = result.hasNextPage;
      currentPage.value = result.page;
    } catch (e) {
      error.value = e.toString().replaceFirst('ApiException', '').trim();
      if (error.value?.isEmpty ?? true) error.value = 'فشل تحميل المنتجات';
      products.clear();
      hasNextPage.value = false;
    } finally {
      loading.value = false;
    }
  }

  Future<void> loadMore() async {
    final s = shop.value;
    if (s == null || s.id.isEmpty || loadingMore.value || !hasNextPage.value) return;
    loadingMore.value = true;
    final nextPage = currentPage.value + 1;
    try {
      final apiClient = Get.find<AuthController>().apiClient;
      final result = await apiClient.getProductsByShop(
        s.id,
        shopName: s.name,
        page: nextPage,
        limit: _pageSize,
        query: searchQuery.value,
      );
      products.addAll(result.items);
      hasNextPage.value = result.hasNextPage;
      currentPage.value = result.page;
    } catch (_) {}
    finally {
      loadingMore.value = false;
    }
  }

  List<Product> get productsToShow => products;

  Future<void> applySearch(String value) async {
    searchQuery.value = value.trim();
    await loadProducts();
  }

  Future<void> clearSearch() async {
    if (searchQuery.value.isEmpty) return;
    searchQuery.value = '';
    searchController.clear();
    await loadProducts();
  }
}
