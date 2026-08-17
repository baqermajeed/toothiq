import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../controller/driver_orders_controller.dart';
import '../../controller/shop_orders_controller.dart';
import '../../core/api/api_config.dart';
import 'local_notifications_service.dart';
import 'token_storage.dart';

/// Socket مشترك للتاجر والسائق: طلبات جديدة + تتبع موقع السائق.
class DriverTrackingSocketService {
  DriverTrackingSocketService({
    required TokenStorage tokenStorage,
    String? baseUrl,
  }) : _tokenStorage = tokenStorage,
       _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final TokenStorage _tokenStorage;
  final String _baseUrl;

  io.Socket? _socket;
  bool _listenersAttached = false;

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect() async {
    if (_socket?.connected == true) return;

    final token = await _tokenStorage.getAccessToken();
    if (token == null || token.isEmpty) return;

    disconnect();

    _socket = io.io(
      _baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableForceNew()
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(999)
          .setReconnectionDelay(1000)
          .setAuth({'token': 'Bearer $token'})
          .build(),
    );

    _attachListeners();
    _socket!.connect();
  }

  void _attachListeners() {
    if (_listenersAttached || _socket == null) return;
    _listenersAttached = true;
    final socket = _socket!;

    socket.onConnect((_) {
      if (kDebugMode) debugPrint('[Socket] connected');
    });
    socket.onConnectError((error) {
      if (kDebugMode) debugPrint('[Socket] connect error: $error');
    });
    socket.onDisconnect((_) {
      if (kDebugMode) debugPrint('[Socket] disconnected');
    });
    socket.on('new_order', (data) {
      _handleIncomingOrder(
        data,
        type: 'shop_new_order',
        title: 'ToothIQ',
        body: 'لديك طلب جديد بانتظار القبول',
        isShop: true,
      );
    });
    socket.on('driver:new_order', (data) {
      _handleIncomingOrder(
        data,
        type: 'driver_new_order',
        title: 'ToothIQ',
        body: 'طلب جديد جاهز للتوصيل',
        isShop: false,
      );
    });
  }

  void _handleIncomingOrder(
    dynamic data, {
    required String type,
    required String title,
    required String body,
    required bool isShop,
  }) {
    final order = _asMap(data)?['order'] ?? _asMap(data);
    final map = _asMap(order);
    final orderId = map?['_id']?.toString() ??
        map?['id']?.toString() ??
        map?['orderId']?.toString() ??
        '';
    final number = map?['orderNumber']?.toString() ?? '';
    final alertBody = number.isEmpty ? body : '$body #$number';

    if (kDebugMode) {
      debugPrint('[Socket] $type orderId=$orderId');
    }

    unawaited(
      LocalNotificationsService.instance().showNotification(
        title: title,
        body: alertBody,
        payload: jsonEncode({
          'type': type,
          'orderId': orderId,
          'role': isShop ? 'shop' : 'driver',
        }),
      ),
    );

    if (isShop && Get.isRegistered<ShopOrdersController>()) {
      Get.find<ShopOrdersController>().loadOrders(silent: true);
    }
    if (!isShop && Get.isRegistered<DriverOrdersController>()) {
      Get.find<DriverOrdersController>().loadOrders(silent: true);
    }
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return null;
  }

  void sendDriverLocation(String orderId, double lat, double lng) {
    if (_socket?.connected != true) return;
    _socket!.emit('driver:location', {
      'orderId': orderId,
      'lat': lat,
      'lng': lng,
    });
  }

  void disconnect() {
    _listenersAttached = false;
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void dispose() => disconnect();
}
