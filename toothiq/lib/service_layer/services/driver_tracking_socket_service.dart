import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../core/api/api_config.dart';
import 'token_storage.dart';

const String _socketLogPrefix = '[Socket]';

class DriverLocationUpdate {
  const DriverLocationUpdate({
    required this.orderId,
    required this.lat,
    required this.lng,
  });

  final String orderId;
  final double lat;
  final double lng;
}

/// خدمة WebSocket لتتبع موقع السائق في الوقت الفعلي (مثل قريب).
class DriverTrackingSocketService {
  DriverTrackingSocketService({
    required TokenStorage tokenStorage,
    String? baseUrl,
  }) : _tokenStorage = tokenStorage,
       _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final TokenStorage _tokenStorage;
  final String _baseUrl;

  io.Socket? _socket;
  final Set<String> _subscribedOrderIds = {};
  static const int _maxReconnectAttempts = 5;
  Completer<void>? _connectionCompleter;
  static const Duration _connectionTimeout = Duration(seconds: 15);

  final StreamController<DriverLocationUpdate> _driverLocationController =
      StreamController<DriverLocationUpdate>.broadcast();
  final StreamController<String> _trackingEndedController =
      StreamController<String>.broadcast();

  Stream<DriverLocationUpdate> get driverLocationUpdates =>
      _driverLocationController.stream;

  Stream<String> get trackingEnded => _trackingEndedController.stream;

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect() async {
    if (_socket?.connected == true) return;

    final token = await _tokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      if (kDebugMode) {
        debugPrint('$_socketLogPrefix فشل الاتصال: لا يوجد توكن.');
      }
      return;
    }

    _connectionCompleter = Completer<void>();
    _socket = io.io(
      _baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(_maxReconnectAttempts)
          .setReconnectionDelay(1000)
          .setAuth({'token': 'Bearer $token'})
          .build(),
    );

    _socket!.onConnect((_) {
      if (!(_connectionCompleter?.isCompleted ?? true)) {
        _connectionCompleter?.complete();
      }
      for (final orderId in _subscribedOrderIds.toList()) {
        _socket!.emit('tracking:subscribe', {'orderId': orderId});
      }
    });

    _socket!.onConnectError((_) {
      if (!(_connectionCompleter?.isCompleted ?? true)) {
        _connectionCompleter?.complete();
      }
    });

    _socket!.on('driver:location', (data) {
      if (data is! Map) return;
      final orderId = data['orderId'] as String?;
      final lat = data['lat'];
      final lng = data['lng'];
      if (orderId == null || orderId.isEmpty) return;
      if (lat is! num || lng is! num) return;
      if (!_driverLocationController.isClosed) {
        _driverLocationController.add(
          DriverLocationUpdate(
            orderId: orderId,
            lat: lat.toDouble(),
            lng: lng.toDouble(),
          ),
        );
      }
    });

    _socket!.on('tracking:ended', (data) {
      if (data is! Map) return;
      final orderId = data['orderId'] as String?;
      if (orderId == null || orderId.isEmpty) return;
      _subscribedOrderIds.remove(orderId);
      if (!_trackingEndedController.isClosed) {
        _trackingEndedController.add(orderId);
      }
    });

    _socket!.connect();
    try {
      await _connectionCompleter!.future.timeout(
        _connectionTimeout,
        onTimeout: () {},
      );
    } catch (_) {}
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _subscribedOrderIds.clear();
  }

  Future<void> subscribeToOrderTracking(String orderId) async {
    if (orderId.isEmpty) return;
    _subscribedOrderIds.add(orderId);
    if (_socket?.connected != true) {
      await connect();
    }
    if (_socket?.connected == true) {
      _socket!.emit('tracking:subscribe', {'orderId': orderId});
    }
  }

  void unsubscribeFromOrderTracking(String orderId) {
    if (orderId.isEmpty) return;
    _subscribedOrderIds.remove(orderId);
    if (_socket?.connected == true) {
      _socket!.emit('tracking:unsubscribe', {'orderId': orderId});
    }
  }

  void dispose() {
    disconnect();
    _driverLocationController.close();
    _trackingEndedController.close();
  }
}
