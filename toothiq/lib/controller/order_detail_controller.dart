import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../model/order_detail_model.dart';
import '../model/order_model.dart';
import '../service_layer/services/driver_tracking_socket_service.dart';
import '../service_layer/services/order_service.dart';
import '../widget/common/app_toast.dart';
import '../bindings/checkout_binding.dart';
import 'cart_controller.dart';
import 'checkout_controller.dart';
import '../core/api/api_exception.dart';
import '../model/product_model.dart';
import '../model/store_model.dart';
import '../view/orders/order_tracking_page.dart';
import '../view/stores/store_detail_page.dart';

class OrderDetailController extends GetxController with WidgetsBindingObserver {
  final OrderService _orderService = Get.find<OrderService>();
  final CartController _cart = Get.find<CartController>();
  final OrderModel order;
  final detail = Rxn<OrderDetailModel>();
  final isLoading = false.obs;
  final loadError = RxnString();
  final isReordering = false.obs;

  final driverLat = Rxn<double>();
  final driverLng = Rxn<double>();

  late final DriverTrackingSocketService _trackingService;
  StreamSubscription<DriverLocationUpdate>? _driverLocationSub;
  StreamSubscription<String>? _trackingEndedSub;
  bool _isTrackingSubscribed = false;

  OrderDetailController({required this.order});

  String get orderId => order.id;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _trackingService = Get.find<DriverTrackingSocketService>();
    loadDetail();
  }

  @override
  void onReady() {
    super.onReady();
    ever(detail, (_) => _onOrderChangedForTracking());
    _driverLocationSub =
        _trackingService.driverLocationUpdates.listen(_onDriverLocationUpdate);
    _trackingEndedSub = _trackingService.trackingEnded.listen(_onTrackingEnded);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _trackingService.unsubscribeFromOrderTracking(orderId);
    _driverLocationSub?.cancel();
    _trackingEndedSub?.cancel();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      loadDetail();
    }
  }

  Future<void> loadDetail() async {
    isLoading.value = true;
    loadError.value = null;
    try {
      final loaded = await _orderService.getOrderById(orderId);
      detail.value = loaded;
      if (loaded.driverLat != null && loaded.driverLng != null) {
        driverLat.value = loaded.driverLat;
        driverLng.value = loaded.driverLng;
      }
    } on ApiException catch (error) {
      loadError.value = error.message;
    } catch (_) {
      loadError.value = 'تعذر تحميل تفاصيل الطلب';
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Future<void> refresh() async {
    await loadDetail();
  }

  void _onOrderChangedForTracking() {
    final current = detail.value;
    if (current == null) {
      _trackingService.unsubscribeFromOrderTracking(orderId);
      _isTrackingSubscribed = false;
      return;
    }
    final canTrack = current.status == OrderStatus.onTheWay;
    if (canTrack) {
      if (!_isTrackingSubscribed) {
        _isTrackingSubscribed = true;
        _trackingService.subscribeToOrderTracking(orderId);
      }
    } else if (_isTrackingSubscribed) {
      _isTrackingSubscribed = false;
      _trackingService.unsubscribeFromOrderTracking(orderId);
    }
  }

  void _onDriverLocationUpdate(DriverLocationUpdate update) {
    if (update.orderId != orderId) return;
    final current = detail.value;
    if (current == null) return;
    detail.value = current.copyWithDriverLocation(
      driverLat: update.lat,
      driverLng: update.lng,
    );
    driverLat.value = update.lat;
    driverLng.value = update.lng;
  }

  void _onTrackingEnded(String endedOrderId) {
    if (endedOrderId != orderId) return;
    _trackingService.unsubscribeFromOrderTracking(orderId);
    _isTrackingSubscribed = false;
    loadDetail();
  }

  void openLiveTracking() {
    final current = detail.value;
    if (current == null || !current.canTrackOnMap) return;
    OrderTrackingPage.open(
      orderId: orderId,
      detail: current,
      driverLat: driverLat,
      driverLng: driverLng,
    );
  }

  Future<void> onReorder() async {
    final current = detail.value;
    if (current == null || current.items.isEmpty) return;
    if (isReordering.value) return;

    isReordering.value = true;
    try {
      _cart.clearCart();

      for (final line in current.items) {
        final productId = (line.productId ?? '').trim();
        if (productId.isEmpty) continue;

        _cart.addProduct(
          ProductModel(
            id: productId,
            name: line.name,
            storeName: current.storeName,
            description: '',
            price: line.unitPrice,
            imageAsset: line.imageAsset,
            shopId: current.shopId,
          ),
          quantity: line.quantity,
          showFeedback: false,
        );
      }

      if (_cart.isEmpty) {
        AppToast.show(
          'تعذر إعادة الطلب',
          'لا توجد منتجات قابلة للإضافة لإعادة الطلب.',
          type: ToastType.warning,
        );
        return;
      }

      CheckoutBinding().dependencies();
      Get.find<CheckoutController>().startCheckout();
    } finally {
      isReordering.value = false;
    }
  }

  void onViewStore() {
    final current = detail.value;
    if (current == null) return;

    StoreDetailPage.open(
      StoreModel(
        id: current.shopId.isNotEmpty ? current.shopId : 'store_${current.id}',
        name: current.storeName,
        description: '',
        address: current.storeAddress.replaceAll(' - ', ' ، '),
      ),
    );
  }
}
