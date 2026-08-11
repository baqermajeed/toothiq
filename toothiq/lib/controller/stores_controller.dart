import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/api/api_exception.dart';
import '../core/errors/api_error_handler.dart';
import '../model/store_model.dart';
import '../service_layer/services/shop_service.dart';
import '../view/search/search_results_page.dart';
import '../widget/stores/store_filter_sheet.dart';
import '../view/stores/store_detail_page.dart';

class StoresController extends GetxController {
  final ShopService _shopService = Get.find<ShopService>();

  final searchController = TextEditingController();
  final scrollController = ScrollController();
  final filteredStores = <StoreModel>[].obs;
  final minRating = Rxn<double>();
  final isLoading = false.obs;
  final loadingMore = false.obs;
  final hasNextPage = false.obs;
  final currentPage = 1.obs;
  final loadError = RxnString();

  final stores = <StoreModel>[].obs;
  static const int _pageSize = 12;
  static const double _loadMoreThreshold = 200;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_applyFilters);
    scrollController.addListener(_onScroll);
    ever(stores, (_) => _applyFilters());
    loadStores();
  }

  @override
  void onClose() {
    searchController.removeListener(_applyFilters);
    scrollController.removeListener(_onScroll);
    searchController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  void _onScroll() {
    if (!hasNextPage.value || loadingMore.value) return;
    final pos = scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - _loadMoreThreshold) {
      loadMore();
    }
  }

  Future<void> loadStores() async {
    isLoading.value = true;
    loadError.value = null;
    currentPage.value = 1;

    try {
      final items = await _shopService.fetchShops(page: 1, limit: _pageSize);
      stores.assignAll(items);
      hasNextPage.value = items.length >= _pageSize;
      _applyFilters();
    } on ApiException catch (error) {
      loadError.value = error.message;
      stores.clear();
      filteredStores.clear();
      hasNextPage.value = false;
    } catch (error) {
      loadError.value = ApiErrorHandler.loadMessage(
        error,
        fallback: 'تعذر تحميل المحلات',
      );
      stores.clear();
      filteredStores.clear();
      hasNextPage.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (loadingMore.value || !hasNextPage.value) return;
    loadingMore.value = true;
    final nextPage = currentPage.value + 1;
    try {
      final items = await _shopService.fetchShops(
        page: nextPage,
        limit: _pageSize,
      );
      if (items.isEmpty) {
        hasNextPage.value = false;
      } else {
        stores.addAll(items);
        currentPage.value = nextPage;
        hasNextPage.value = items.length >= _pageSize;
      }
    } catch (_) {
      // لا نعرض خطأ هنا؛ نفس سلوك قريب في جلب المزيد.
    } finally {
      loadingMore.value = false;
    }
  }

  @override
  Future<void> refresh() async {
    await loadStores();
  }

  void _applyFilters() {
    final query = searchController.text.trim().toLowerCase();
    filteredStores.assignAll(
      stores.where((store) {
        final matchesQuery =
            query.isEmpty ||
            store.name.toLowerCase().contains(query) ||
            store.description.toLowerCase().contains(query) ||
            store.address.toLowerCase().contains(query);
        final matchesRating =
            minRating.value == null || store.rating >= minRating.value!;
        return matchesQuery && matchesRating;
      }).toList(),
    );
  }

  void submitSearch() {
    final query = searchController.text.trim();
    if (query.isEmpty) return;
    SearchResultsPage.open(query: query);
  }

  Future<void> onFilterTap() async {
    final result = await StoreFilterSheet.show(selectedRating: minRating.value);
    if (result == null) return;
    minRating.value = result.minRating;
    _applyFilters();
  }

  void onViewStore(String storeId) {
    final store = stores.firstWhere((s) => s.id == storeId);
    StoreDetailPage.open(store);
  }
}
