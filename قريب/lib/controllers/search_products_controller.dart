import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app_location_controller.dart';
import 'auth_controller.dart';
import '../models/product.dart';

/// تحكم شاشة نتائج البحث — إدارة حالة البحث وعرض المنتجات من الـ API مع pagination.
class SearchProductsController extends GetxController {
  final TextEditingController searchController = TextEditingController();
  final Rx<String> query = ''.obs;
  final RxList<Product> products = <Product>[].obs;
  final RxBool loading = false.obs;
  final RxBool loadingMore = false.obs;
  final RxBool hasNextPage = false.obs;
  final RxInt currentPage = 1.obs;
  final RxBool hasSearched = false.obs;
  final Rxn<String> error = Rxn<String>();
  final ScrollController scrollController = ScrollController();

  static const int _pageSize = 12;
  static const double _loadMoreThreshold = 200;

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!hasNextPage.value || loadingMore.value) return;
    final pos = scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - _loadMoreThreshold) {
      loadMore();
    }
  }

  /// تعيين نص البحث (مزامنة مع الحقل).
  void setQuery(String value) {
    query.value = value.trim();
  }

  (double?, double?) _getLocationCoords() {
    final auth = Get.find<AuthController>();
    final user = auth.user.value;
    if (user?.location is Map<String, dynamic>) {
      final loc = user!.location as Map<String, dynamic>;
      final coords = loc['coordinates'];
      if (coords is List && coords.length >= 2) {
        return ((coords[0] as num).toDouble(), (coords[1] as num).toDouble());
      }
    }
    final appLoc = Get.find<AppLocationController>();
    if (appLoc.hasLocation) return (appLoc.lng, appLoc.lat);
    return (null, null);
  }

  /// تشغيل البحث — يجلب الصفحة الأولى من الـ API.
  Future<void> search() async {
    final q = query.value;
    if (q.isEmpty) {
      products.clear();
      hasSearched.value = true;
      error.value = null;
      hasNextPage.value = false;
      return;
    }
    loading.value = true;
    error.value = null;
    hasSearched.value = true;
    currentPage.value = 1;
    try {
      final auth = Get.find<AuthController>();
      final apiClient = auth.apiClient;
      // ملاحظة: لا نرسل الإحداثيات في البحث العام حتى لا يفلتر السيرفر النتائج حسب المنطقة
      // لأن هذا سبب اختلاف النتائج بين macOS (بدون إحداثيات) والجوال (بإحداثيات حقيقية).
      final result = await apiClient.searchProducts(
        q,
        page: 1,
        limit: _pageSize,
      );
      products.value = result.items;
      hasNextPage.value = result.hasNextPage;
      currentPage.value = result.page;
    } catch (e) {
      error.value = e.toString().replaceFirst('ApiException', '').trim();
      if (error.value?.isEmpty ?? true) error.value = 'فشل البحث';
      products.clear();
      hasNextPage.value = false;
    } finally {
      loading.value = false;
    }
  }

  /// جلب المزيد من نتائج البحث.
  Future<void> loadMore() async {
    final q = query.value;
    if (q.isEmpty || loadingMore.value || !hasNextPage.value) return;
    loadingMore.value = true;
    final nextPage = currentPage.value + 1;
    try {
      final auth = Get.find<AuthController>();
      final result = await auth.apiClient.searchProducts(
        q,
        page: nextPage,
        limit: _pageSize,
      );
      products.addAll(result.items);
      hasNextPage.value = result.hasNextPage;
      currentPage.value = result.page;
    } catch (_) {}
    finally {
      loadingMore.value = false;
    }
  }

  /// مسح البحث وإعادة الحالة الابتدائية.
  void clear() {
    searchController.clear();
    query.value = '';
    products.clear();
    hasSearched.value = false;
    error.value = null;
    hasNextPage.value = false;
    currentPage.value = 1;
  }

  @override
  void onReady() {
    super.onReady();
    final initialQuery = Get.arguments is String ? Get.arguments as String? : null;
    if (initialQuery != null && initialQuery.isNotEmpty) {
      searchController.text = initialQuery;
      query.value = initialQuery;
      search();
    }
  }

  @override
  @override
  void onClose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    searchController.dispose();
    super.onClose();
  }
}
