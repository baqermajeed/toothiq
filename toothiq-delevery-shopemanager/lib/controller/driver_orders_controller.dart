import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import '../bindings/app_binding.dart';
import '../model/partner_order.dart';
import '../service_layer/services/driver_tracking_socket_service.dart';
import '../service_layer/services/order_service.dart';

enum DriverOrderTab { pending, inProgress, finished }

class DriverOrdersController extends GetxController {
  DriverOrdersController({
    required OrderService orderService,
    required DriverTrackingSocketService socketService,
  }) : _orderService = orderService,
       _socketService = socketService;

  final OrderService _orderService;
  final DriverTrackingSocketService _socketService;

  final orders = <PartnerOrder>[].obs;
  final selectedTab = DriverOrderTab.pending.obs;
  final acceptedOrderIds = <String>{}.obs;
  final pickedUpOrderIds = <String>{}.obs;
  final activeOrderId = RxnString();
  final isSharingLocation = false.obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final currentLat = RxnDouble();
  final currentLng = RxnDouble();

  Timer? _locationTimer;

  @override
  void onInit() {
    super.onInit();
    loadOrders();
  }

  @override
  void onClose() {
    _stopSharing();
    super.onClose();
  }

  Future<void> loadOrders() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final list = await _orderService.fetchOrders();
      orders.assignAll(list);
      _syncAcceptedFromOrders();
    } catch (error) {
      errorMessage.value = apiErrorMessage(error);
    } finally {
      isLoading.value = false;
    }
  }

  void changeTab(DriverOrderTab tab) => selectedTab.value = tab;

  List<PartnerOrder> get pendingOrders => orders
      .where(
        (o) =>
            o.status == PartnerOrderStatus.pending ||
            o.status == PartnerOrderStatus.accepted ||
            o.status == PartnerOrderStatus.preparing,
      )
      .where(
        (o) =>
            !pickedUpOrderIds.contains(o.id) &&
            o.status != PartnerOrderStatus.onTheWay,
      )
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<PartnerOrder> get inProgressOrders => orders
      .where(
        (o) =>
            o.status == PartnerOrderStatus.onTheWay ||
            pickedUpOrderIds.contains(o.id),
      )
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<PartnerOrder> get finishedOrders => orders
      .where(
        (o) =>
            o.status == PartnerOrderStatus.delivered ||
            o.status == PartnerOrderStatus.canceled,
      )
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<PartnerOrder> get currentTabOrders {
    switch (selectedTab.value) {
      case DriverOrderTab.pending:
        return pendingOrders;
      case DriverOrderTab.inProgress:
        return inProgressOrders;
      case DriverOrderTab.finished:
        return finishedOrders;
    }
  }

  int countForTab(DriverOrderTab tab) {
    switch (tab) {
      case DriverOrderTab.pending:
        return pendingOrders.length;
      case DriverOrderTab.inProgress:
        return inProgressOrders.length;
      case DriverOrderTab.finished:
        return finishedOrders.length;
    }
  }

  PartnerOrder? get activeOrder {
    final id = activeOrderId.value;
    if (id == null) return null;
    return orders.firstWhereOrNull((o) => o.id == id);
  }

  bool isPickedUp(String orderId) => pickedUpOrderIds.contains(orderId);

  Future<void> acceptOrder(String orderId) async {
    try {
      final updated = await _orderService.updateStatus(
        orderId: orderId,
        status: PartnerOrderStatus.accepted.apiValue,
      );
      acceptedOrderIds.add(orderId);
      _replaceOrder(updated);
      selectedTab.value = DriverOrderTab.inProgress;
      acceptedOrderIds.refresh();
    } catch (error) {
      Get.snackbar('خطأ', apiErrorMessage(error));
    }
  }

  Future<void> markPickedUp(String orderId) async {
    try {
      final updated = await _orderService.updateStatus(
        orderId: orderId,
        status: PartnerOrderStatus.onTheWay.apiValue,
      );
      pickedUpOrderIds.add(orderId);
      _replaceOrder(updated);
      activeOrderId.value = orderId;
      pickedUpOrderIds.refresh();

      await _socketService.connect();
      await _startSharing(orderId);
    } catch (error) {
      Get.snackbar('خطأ', apiErrorMessage(error));
    }
  }

  Future<void> completeDelivery(String orderId) async {
    try {
      final updated = await _orderService.updateStatus(
        orderId: orderId,
        status: PartnerOrderStatus.delivered.apiValue,
      );
      _replaceOrder(updated);
      if (activeOrderId.value == orderId) {
        activeOrderId.value = null;
        _stopSharing();
      }
      selectedTab.value = DriverOrderTab.finished;
    } catch (error) {
      Get.snackbar('خطأ', apiErrorMessage(error));
    }
  }

  Future<void> startDelivery(String orderId) => markPickedUp(orderId);

  void _replaceOrder(PartnerOrder order) {
    final index = orders.indexWhere((o) => o.id == order.id);
    if (index >= 0) {
      orders[index] = order;
    } else {
      orders.insert(0, order);
    }
    orders.refresh();
  }

  void _syncAcceptedFromOrders() {
    acceptedOrderIds.clear();
    pickedUpOrderIds.clear();
    for (final order in orders) {
      if (order.status == PartnerOrderStatus.onTheWay) {
        acceptedOrderIds.add(order.id);
        pickedUpOrderIds.add(order.id);
        activeOrderId.value ??= order.id;
      } else if (order.status == PartnerOrderStatus.accepted ||
          order.status == PartnerOrderStatus.preparing) {
        acceptedOrderIds.add(order.id);
      }
    }
  }

  Future<void> _startSharing(String orderId) async {
    final permission = await _ensureLocationPermission();
    if (!permission) return;

    isSharingLocation.value = true;
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        currentLat.value = pos.latitude;
        currentLng.value = pos.longitude;
        _socketService.sendDriverLocation(orderId, pos.latitude, pos.longitude);
      } catch (_) {}
    });
  }

  void _stopSharing() {
    _locationTimer?.cancel();
    _locationTimer = null;
    isSharingLocation.value = false;
  }

  Future<bool> _ensureLocationPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      Get.snackbar('الموقع', 'يلزم تفعيل صلاحية الموقع لمشاركة مسار التوصيل');
      return false;
    }

    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      Get.snackbar('الموقع', 'فعّل خدمة الموقع من إعدادات الجهاز');
      return false;
    }
    return true;
  }
}
