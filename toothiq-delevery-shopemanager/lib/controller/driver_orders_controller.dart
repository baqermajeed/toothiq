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

  final pendingOrders = <PartnerOrder>[].obs;
  final inProgressOrders = <PartnerOrder>[].obs;
  final finishedOrders = <PartnerOrder>[].obs;
  final selectedTab = DriverOrderTab.pending.obs;
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
      final results = await Future.wait([
        _orderService.fetchDriverOrders(tab: 'pending'),
        _orderService.fetchDriverOrders(tab: 'in_progress'),
        _orderService.fetchDriverOrders(tab: 'completed'),
      ]);
      pendingOrders.assignAll(results[0]);
      inProgressOrders.assignAll(results[1]);
      finishedOrders.assignAll(results[2]);
      _syncPickedUpFromOrders();
    } catch (error) {
      errorMessage.value = apiErrorMessage(error);
    } finally {
      isLoading.value = false;
    }
  }

  void changeTab(DriverOrderTab tab) => selectedTab.value = tab;

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

  PartnerOrder? findOrder(String id) {
    return pendingOrders.firstWhereOrNull((o) => o.id == id) ??
        inProgressOrders.firstWhereOrNull((o) => o.id == id) ??
        finishedOrders.firstWhereOrNull((o) => o.id == id);
  }

  PartnerOrder? get activeOrder {
    final id = activeOrderId.value;
    if (id == null) return null;
    return findOrder(id);
  }

  bool isPickedUp(String orderId) =>
      pickedUpOrderIds.contains(orderId) ||
      inProgressOrders.any(
        (o) => o.id == orderId && o.status == PartnerOrderStatus.onTheWay,
      );

  Future<void> acceptOrder(String orderId) async {
    try {
      final updated = await _orderService.acceptDriverOrder(orderId);
      pendingOrders.removeWhere((o) => o.id == orderId);
      _upsert(inProgressOrders, updated);
      if (updated.status == PartnerOrderStatus.onTheWay) {
        pickedUpOrderIds.add(orderId);
        activeOrderId.value = orderId;
      }
      selectedTab.value = DriverOrderTab.inProgress;
      pickedUpOrderIds.refresh();
    } catch (error) {
      Get.snackbar('خطأ', apiErrorMessage(error));
    }
  }

  Future<void> markPickedUp(String orderId) async {
    try {
      final updated = await _orderService.updateDriverStatus(
        orderId: orderId,
        status: PartnerOrderStatus.onTheWay.apiValue,
      );
      pickedUpOrderIds.add(orderId);
      _upsert(inProgressOrders, updated);
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
      final updated = await _orderService.updateDriverStatus(
        orderId: orderId,
        status: PartnerOrderStatus.delivered.apiValue,
      );
      inProgressOrders.removeWhere((o) => o.id == orderId);
      _upsert(finishedOrders, updated);
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

  void _upsert(RxList<PartnerOrder> list, PartnerOrder order) {
    final index = list.indexWhere((o) => o.id == order.id);
    if (index >= 0) {
      list[index] = order;
    } else {
      list.insert(0, order);
    }
    list.refresh();
  }

  void _syncPickedUpFromOrders() {
    pickedUpOrderIds.clear();
    for (final order in inProgressOrders) {
      if (order.status == PartnerOrderStatus.onTheWay) {
        pickedUpOrderIds.add(order.id);
        activeOrderId.value ??= order.id;
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
