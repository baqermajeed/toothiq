import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'auth_controller.dart';
import '../core/errors/api_exception.dart';
import '../models/order.dart';

/// Controller للطلبات — يجلب طلبات المستخدم المسجّل من الـ API مع pagination.
class OrdersController extends GetxController {
  final orders = <Order>[].obs;
  final isLoading = false.obs;
  final loadingMore = false.obs;
  final hasNextPage = false.obs;
  final currentPage = 1.obs;
  final error = Rxn<String>();
  final ScrollController scrollController = ScrollController();

  static const int _pageSize = 20;
  static const double _loadMoreThreshold = 200;

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
    loadOrders();
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

  /// تحميل الطلبات من الصفحة الأولى.
  Future<void> loadOrders() async {
    isLoading.value = true;
    error.value = null;
    currentPage.value = 1;
    final auth = Get.find<AuthController>();
    if (!auth.isAuthenticated) {
      orders.clear();
      error.value = 'يرجى تسجيل الدخول لعرض الطلبات';
      hasNextPage.value = false;
      isLoading.value = false;
      return;
    }
    try {
      final result = await auth.apiClient.getOrders(page: 1, limit: _pageSize);
      orders.value = result.items;
      hasNextPage.value = result.hasNextPage;
      currentPage.value = result.page;
    } on ApiException catch (e) {
      error.value = e.message;
      orders.clear();
      hasNextPage.value = false;
    } catch (_) {
      error.value = 'فشل تحميل الطلبات';
      orders.clear();
      hasNextPage.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  /// جلب الصفحة التالية من الطلبات.
  Future<void> loadMore() async {
    if (loadingMore.value || !hasNextPage.value) return;
    final auth = Get.find<AuthController>();
    if (!auth.isAuthenticated) return;
    loadingMore.value = true;
    final nextPage = currentPage.value + 1;
    try {
      final result = await auth.apiClient.getOrders(page: nextPage, limit: _pageSize);
      orders.addAll(result.items);
      hasNextPage.value = result.hasNextPage;
      currentPage.value = result.page;
    } catch (_) {
      // لا نعرض خطأ لجلب المزيد
    } finally {
      loadingMore.value = false;
    }
  }

  /// تحديث القائمة من الـ API (سحب للتحديث).
  @override
  Future<void> refresh() async {
    await loadOrders();
  }

  List<Order> get ordersByNewest => List<Order>.from(orders)..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));

  List<Order> get pendingOrders => orders.where((o) => o.status == OrderStatus.pending).toList();
  List<Order> get activeOrders => orders.where((o) => _isActiveStatus(o.status)).toList();
  List<Order> get completedOrders => orders.where((o) => o.status == OrderStatus.delivered).toList();
  List<Order> get canceledOrders => orders.where((o) => o.status == OrderStatus.canceled).toList();

  static bool _isActiveStatus(OrderStatus s) =>
      s == OrderStatus.accepted || s == OrderStatus.preparing || s == OrderStatus.onTheWay;
}
