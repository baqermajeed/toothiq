import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'auth_controller.dart';
import '../core/errors/api_exception.dart';
import '../core/theme/app_colors.dart';
import '../models/order.dart';
import '../services/directions_service.dart';
import '../services/driver_tracking_socket_service.dart';
import '../utils/map_debug_logger.dart';
import '../utils/map_marker_helper.dart';

/// Controller لشاشة تفاصيل الطلب — يجلب طلباً واحداً ويعرضه مع موقع التوصيل.
class OrderDetailController extends GetxController {
  final order = Rxn<Order>();
  final isLoading = true.obs;
  final error = Rxn<String>();

  final driverIcon = Rxn<BitmapDescriptor>();
  final customerIcon = Rxn<BitmapDescriptor>();
  final routePoints = <LatLng>[].obs;
  final isLoadingRoute = false.obs;

  /// موقع السائق المباشر من السوكيت — الخريطة تعتمد عليها حتى تتحرك أيقونة الدراجة عند كل driver:location.
  final driverLat = Rxn<double>();
  final driverLng = Rxn<double>();

  String? _orderId;
  final DirectionsService _directionsService = DirectionsService();
  late final DriverTrackingSocketService _trackingService;
  StreamSubscription<DriverLocationUpdate>? _driverLocationSub;
  StreamSubscription<String>? _trackingEndedSub;
  /// تجنّب إعادة الاشتراك عند كل تحديث لـ order (مثل استلام driver:location).
  bool _isTrackingSubscribed = false;

  static const String _orderSenderIconPath = 'assets/icons/user-hand-up-svgrepo-com.svg';

  @override
  void onInit() {
    super.onInit();
    _trackingService = Get.find<DriverTrackingSocketService>();
    _orderId = Get.arguments is String ? Get.arguments as String : Get.arguments?.toString();
    if (_orderId != null && _orderId!.isNotEmpty) {
      loadOrder(_orderId!);
      _loadMapIcons();
    } else {
      isLoading.value = false;
      error.value = 'معرّف الطلب غير صحيح';
    }
  }

  @override
  void onReady() {
    super.onReady();
    ever(order, (_) => _loadRouteWhenReady());
    ever(order, (_) => _onOrderChangedForTracking());
    _driverLocationSub = _trackingService.driverLocationUpdates.listen(_onDriverLocationUpdate);
    _trackingEndedSub = _trackingService.trackingEnded.listen(_onTrackingEnded);
  }

  @override
  void onClose() {
    if (_orderId != null) {
      _trackingService.unsubscribeFromOrderTracking(_orderId!);
    }
    _driverLocationSub?.cancel();
    _trackingEndedSub?.cancel();
    super.onClose();
  }

  void _onOrderChangedForTracking() {
    final o = order.value;
    if (_orderId == null) return;
    if (o == null) {
      _trackingService.unsubscribeFromOrderTracking(_orderId!);
      _isTrackingSubscribed = false;
      return;
    }
    final canTrackAsCustomer = o.status == OrderStatus.onTheWay;
    if (canTrackAsCustomer) {
      if (!_isTrackingSubscribed) {
        _isTrackingSubscribed = true;
        _trackingService.subscribeToOrderTracking(_orderId!);
      }
    } else {
      if (_isTrackingSubscribed) {
        _isTrackingSubscribed = false;
        _trackingService.unsubscribeFromOrderTracking(_orderId!);
      }
    }
  }

  void _onDriverLocationUpdate(DriverLocationUpdate update) {
    if (update.orderId != _orderId) return;
    final o = order.value;
    if (o == null) return;
    order.value = o.copyWithDriverLocation(driverLat: update.lat, driverLng: update.lng);
    // تحديث مباشر لموقع السائق حتى تتجدّد الخريطة فوراً (اعتماد Obx على driverLat/driverLng).
    driverLat.value = update.lat;
    driverLng.value = update.lng;
  }

  void _onTrackingEnded(String orderId) {
    if (orderId != _orderId) return;
    _trackingService.unsubscribeFromOrderTracking(orderId);
    loadOrder(orderId);
  }

  Future<void> _loadMapIcons() async {
    MapDebugLogger.iconsLoadStart();
    final driver = await MapMarkerHelper.getBitmapDescriptorFromIcon(
      Icons.two_wheeler,
      color: AppColors.primaryDark,
      size: 40.w,
      backgroundColor: Colors.white,
      padding: 8.r,
    );
    final customer = await MapMarkerHelper.getBitmapDescriptorFromSvg(
      _orderSenderIconPath,
      width: 48.w,
      height: 48.h,
      addPinPoint: true,
    );
    driverIcon.value = driver;
    customerIcon.value = customer;
    MapDebugLogger.iconsLoadEnd();
  }

  Future<void> _loadRouteWhenReady() async {
    final o = order.value;
    if (o == null ||
        o.deliveryLat == null ||
        o.deliveryLng == null ||
        o.driverLat == null ||
        o.driverLng == null) {
      return;
    }
    isLoadingRoute.value = true;
    try {
      final points = await _directionsService.getRouteBetweenPoints(
        origin: LatLng(o.driverLat!, o.driverLng!),
        destination: LatLng(o.deliveryLat!, o.deliveryLng!),
      );
      routePoints.assignAll(points ?? []);
    } catch (_) {
      routePoints.clear();
    } finally {
      isLoadingRoute.value = false;
    }
  }

  /// جلب الطلب من الـ API وحفظه في [order].
  Future<void> loadOrder(String orderId) async {
    isLoading.value = true;
    error.value = null;
    final auth = Get.find<AuthController>();
    if (!auth.isAuthenticated) {
      isLoading.value = false;
      error.value = 'يرجى تسجيل الدخول';
      return;
    }
    try {
      final o = await auth.apiClient.getOrderById(orderId);
      order.value = o;
      // مزامنة موقع السائق من الطلب (أو من آخر موقع أُرسل عند الاشتراك).
      if (o.driverLat != null && o.driverLng != null) {
        driverLat.value = o.driverLat;
        driverLng.value = o.driverLng;
      }
    } on ApiException catch (e) {
      error.value = e.message;
      order.value = null;
      driverLat.value = null;
      driverLng.value = null;
    } catch (_) {
      error.value = 'فشل تحميل الطلب';
      order.value = null;
      driverLat.value = null;
      driverLng.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  /// هل الطلب يملك إحداثيات توصيل للعرض على الخريطة؟
  bool get hasDeliveryLocation {
    final o = order.value;
    if (o == null) return false;
    return o.deliveryLat != null && o.deliveryLng != null;
  }

  /// هل الطلب يملك إحداثيات موقع السائق للعرض؟
  bool get hasDriverLocation {
    final o = order.value;
    if (o == null) return false;
    return o.driverLat != null && o.driverLng != null;
  }
}
