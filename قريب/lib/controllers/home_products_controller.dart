import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app_location_controller.dart';
import 'auth_controller.dart';
import 'home_shops_controller.dart';
import '../models/product.dart';

/// تحكم قسم «منتجات متنوعة» في الصفحة الرئيسية — يدعم pagination وجلب المزيد.
class HomeProductsController extends GetxController {
  final RxList<Product> products = <Product>[].obs;
  final RxBool loading = true.obs;
  final RxBool loadingMore = false.obs;
  final RxBool hasNextPage = false.obs;
  final RxInt currentPage = 1.obs;
  final Rxn<String> error = Rxn<String>();
  final ScrollController scrollController = ScrollController();

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
    scrollController.removeListener(_onScroll);
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

  /// إحداثيات الموقع للفلترة حسب المنطقة.
  List<double>? _getLocationCoords() {
    final auth = Get.find<AuthController>();
    final user = auth.user.value;
    if (user?.location is Map<String, dynamic>) {
      final loc = user!.location as Map<String, dynamic>;
      final coords = loc['coordinates'];
      if (coords is List && coords.length >= 2) {
        return [(coords[0] as num).toDouble(), (coords[1] as num).toDouble()];
      }
    }
    final appLoc = Get.find<AppLocationController>();
    if (appLoc.hasLocation) {
      return [appLoc.lng!, appLoc.lat!];
    }
    return null;
  }

  /// التحقق من دعم المنطقة — إن كانت المحلات فارغة مع وجود موقع، فالمنطقة غير مدعومة.
  bool get _isZoneNotSupported {
    final coords = _getLocationCoords();
    if (coords == null) return false;
    final shopsCtrl = Get.find<HomeShopsController>();
    return !shopsCtrl.loading.value &&
        shopsCtrl.shops.isEmpty &&
        shopsCtrl.error.value == null;
  }

  /// التحميل الأول — صفحة 1.
  /// لا يُحمّل المنتجات إن كانت المنطقة غير مدعومة.
  Future<void> loadProducts() async {
    loading.value = true;
    error.value = null;
    currentPage.value = 1;
    try {
      final shopsCtrl = Get.find<HomeShopsController>();
      var attempts = 0;
      while (shopsCtrl.loading.value && attempts < 50) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
      if (_isZoneNotSupported) {
        products.clear();
        hasNextPage.value = false;
        loading.value = false;
        return;
      }
      final coords = _getLocationCoords();
      final apiClient = Get.find<AuthController>().apiClient;
      final result = await apiClient.getProducts(
        page: 1,
        limit: _pageSize,
        lng: (coords != null && coords.length >= 2) ? coords[0] : null,
        lat: (coords != null && coords.length >= 2) ? coords[1] : null,
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

  /// جلب المزيد — الصفحة التالية.
  Future<void> loadMore() async {
    if (loadingMore.value || !hasNextPage.value || _isZoneNotSupported) return;
    loadingMore.value = true;
    final nextPage = currentPage.value + 1;
    final coords = _getLocationCoords();
    try {
      final apiClient = Get.find<AuthController>().apiClient;
      final result = await apiClient.getProducts(
        page: nextPage,
        limit: _pageSize,
        lng: (coords != null && coords.length >= 2) ? coords[0] : null,
        lat: (coords != null && coords.length >= 2) ? coords[1] : null,
      );
      products.addAll(result.items);
      hasNextPage.value = result.hasNextPage;
      currentPage.value = result.page;
    } catch (_) {
      // لا نعرض خطأ لجلب المزيد — يمكن إظهار snackbar لاحقاً
    } finally {
      loadingMore.value = false;
    }
  }
}
