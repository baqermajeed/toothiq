import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/main_controller.dart';
import '../model/order_model.dart';
import '../service_layer/services/order_service.dart';
import '../core/api/api_exception.dart';
import '../core/errors/api_error_handler.dart';
import '../widget/orders/order_status_filter_sheet.dart';

class OrdersController extends GetxController with WidgetsBindingObserver {
  final OrderService _orderService = Get.find<OrderService>();

  final searchController = TextEditingController();
  final scrollController = ScrollController();
  final filteredOrders = <OrderModel>[].obs;
  final selectedStatus = Rxn<OrderStatus>();
  final orders = <OrderModel>[].obs;
  final isLoading = false.obs;
  final isRefreshing = false.obs;
  final loadingMore = false.obs;
  final hasNextPage = false.obs;
  final currentPage = 1.obs;
  final loadError = RxnString();
  static const int _pageSize = 20;
  static const double _loadMoreThreshold = 200;
  static const int ordersTabIndex = 3;

  Worker? _tabWorker;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    searchController.addListener(_applyFilters);
    scrollController.addListener(_onScroll);
    _listenOrdersTabFocus();
    loadOrders();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshIfOrdersTabActive();
    });
  }

  void _listenOrdersTabFocus() {
    if (!Get.isRegistered<MainController>()) return;
    final main = Get.find<MainController>();
    _tabWorker = ever<int>(main.currentIndex, (index) {
      if (index == ordersTabIndex) {
        refreshSilently();
      }
    });
  }

  void _refreshIfOrdersTabActive() {
    if (!Get.isRegistered<MainController>()) return;
    if (Get.find<MainController>().currentIndex.value == ordersTabIndex) {
      refreshSilently();
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabWorker?.dispose();
    searchController.removeListener(_applyFilters);
    scrollController.removeListener(_onScroll);
    searchController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _refreshIfOrdersTabActive();
  }

  void _onScroll() {
    if (!hasNextPage.value || loadingMore.value) return;
    if (scrollController.positions.length != 1) return;
    final pos = scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - _loadMoreThreshold) {
      loadMore();
    }
  }

  void _applyFilters() {
    final query = searchController.text.trim();
    filteredOrders.assignAll(
      orders.where((order) {
        final matchesQuery =
            query.isEmpty ||
            order.orderName.contains(query) ||
            order.storeName.contains(query);
        final matchesStatus =
            selectedStatus.value == null ||
            order.status == selectedStatus.value;
        return matchesQuery && matchesStatus;
      }).toList(),
    );
    filteredOrders.refresh();
  }

  Future<void> loadOrders() async {
    isLoading.value = true;
    loadError.value = null;
    currentPage.value = 1;
    try {
      await _fetchFirstPage();
    } on ApiException catch (error) {
      loadError.value = error.message;
      orders.clear();
      filteredOrders.clear();
      hasNextPage.value = false;
    } catch (error) {
      loadError.value = ApiErrorHandler.loadMessage(
        error,
        fallback: 'تعذر تحميل الطلبات',
      );
      orders.clear();
      filteredOrders.clear();
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
      final data = await _orderService.listOrders(
        status: _apiStatusFromFilter(selectedStatus.value),
        page: nextPage,
        limit: _pageSize,
      );
      if (data.isEmpty) {
        hasNextPage.value = false;
      } else {
        orders.addAll(data);
        currentPage.value = nextPage;
        hasNextPage.value = data.length >= _pageSize;
        _applyFilters();
        orders.refresh();
      }
    } catch (_) {
      // لا نعرض خطأ في جلب المزيد.
    } finally {
      loadingMore.value = false;
    }
  }

  @override
  Future<void> refresh() async {
    if (isRefreshing.value) return;
    isRefreshing.value = true;
    loadError.value = null;
    try {
      await _fetchFirstPage();
    } on ApiException catch (error) {
      loadError.value = error.message;
    } catch (error) {
      loadError.value = ApiErrorHandler.loadMessage(
        error,
        fallback: 'تعذر تحديث الطلبات',
      );
    } finally {
      isRefreshing.value = false;
    }
  }

  /// تحديث القائمة بدون شاشة تحميل كاملة.
  Future<void> refreshSilently() async {
    if (isRefreshing.value) return;
    try {
      await _fetchFirstPage();
      loadError.value = null;
    } catch (_) {
      // نُبقي القائمة الحالية عند فشل التحديث الخلفي.
    }
  }

  Future<void> _fetchFirstPage() async {
    currentPage.value = 1;
    final data = await _orderService.listOrders(
      status: _apiStatusFromFilter(selectedStatus.value),
      page: 1,
      limit: _pageSize,
    );
    orders.assignAll(data);
    orders.refresh();
    hasNextPage.value = data.length >= _pageSize;
    _applyFilters();
  }

  Future<void> onFilterTap() async {
    final result = await OrderStatusFilterSheet.show(
      selectedStatus: selectedStatus.value,
    );
    if (result == null) return;
    selectedStatus.value = result.status;
    await loadOrders();
  }

  String? _apiStatusFromFilter(OrderStatus? status) {
    switch (status) {
      case null:
        return null;
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.accepted:
        return 'accepted';
      case OrderStatus.inDelivery:
        return 'preparing';
      case OrderStatus.onTheWay:
        return 'on_the_way';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.canceled:
        return 'canceled';
    }
  }
}
