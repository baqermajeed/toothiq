import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../core/config/api_config.dart';
import 'token_storage.dart';

const String _socketLogPrefix = '[Socket]';

/// تحديث موقع السائق من WebSocket.
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

/// خدمة WebSocket لتتبع موقع السائق في الوقت الفعلي.
/// - العميل: subscribe / unsubscribe، استقبال driver:location و tracking:ended.
/// - السائق: sendDriverLocation.
/// لا تعتمد على GetX؛ يمكن حقن TokenStorage و baseUrl.
class DriverTrackingSocketService {
  DriverTrackingSocketService({
    required TokenStorage tokenStorage,
    String? baseUrl,
  })  : _tokenStorage = tokenStorage,
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

  /// تدفق تحديثات موقع السائق (orderId, lat, lng).
  Stream<DriverLocationUpdate> get driverLocationUpdates =>
      _driverLocationController.stream;

  /// تدفق إنهاء التتبع (orderId).
  Stream<String> get trackingEnded => _trackingEndedController.stream;

  bool get isConnected => _socket?.connected ?? false;

  /// الاتصال باستخدام التوكن الحالي. يُستدعى تلقائياً عند أول اشتراك.
  /// يُرجع عندما يصبح السوكيت متصلاً (أو بعد انتهاء المهلة).
  Future<void> connect() async {
    if (_socket?.connected == true) {
      if (kDebugMode) debugPrint('$_socketLogPrefix الاتصال موجود مسبقاً.');
      return;
    }
    final token = await _tokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      if (kDebugMode) debugPrint('$_socketLogPrefix فشل الاتصال: لا يوجد توكن.');
      return;
    }
    if (kDebugMode) debugPrint('$_socketLogPrefix جاري الاتصال بـ $_baseUrl ...');

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
      if (kDebugMode) debugPrint('$_socketLogPrefix الاتصال نجح.');
      if (!(_connectionCompleter?.isCompleted ?? true)) {
        _connectionCompleter?.complete();
      }
      for (final orderId in _subscribedOrderIds.toList()) {
        _socket!.emit('tracking:subscribe', {'orderId': orderId});
      }
    });

    _socket!.onDisconnect((reason) {
      if (kDebugMode) debugPrint('$_socketLogPrefix انقطع الاتصال: $reason');
    });

    _socket!.onConnectError((err) {
      if (kDebugMode) debugPrint('$_socketLogPrefix فشل الاتصال: $err');
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
      if (kDebugMode) {
        debugPrint('$_socketLogPrefix استلام موقع السائق للطلب $orderId: lat=$lat, lng=$lng');
      }
      if (!_driverLocationController.isClosed) {
        _driverLocationController.add(DriverLocationUpdate(
          orderId: orderId,
          lat: lat.toDouble(),
          lng: lng.toDouble(),
        ));
      }
    });

    _socket!.on('tracking:ended', (data) {
      if (data is! Map) return;
      final orderId = data['orderId'] as String?;
      if (orderId == null || orderId.isEmpty) return;
      _subscribedOrderIds.remove(orderId);
      if (kDebugMode) debugPrint('$_socketLogPrefix انتهى التتبع للطلب: $orderId');
      if (!_trackingEndedController.isClosed) {
        _trackingEndedController.add(orderId);
      }
    });

    _socket!.on('tracking:error', (data) {
      if (kDebugMode) {
        final msg = data is Map ? (data['message'] ?? data) : data;
        debugPrint('$_socketLogPrefix خطأ تتبع: $msg');
      }
    });

    _socket!.connect();
    try {
      await _connectionCompleter!.future.timeout(
        _connectionTimeout,
        onTimeout: () {
          if (kDebugMode) debugPrint('$_socketLogPrefix انتهت مهلة انتظار الاتصال.');
        },
      );
    } catch (_) {}
  }

  /// قطع الاتصال.
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _subscribedOrderIds.clear();
  }

  /// الاشتراك في تتبع طلب (للعميل). ينتظر اكتمال الاتصال ثم يرسل الاشتراك.
  Future<void> subscribeToOrderTracking(String orderId) async {
    if (orderId.isEmpty) return;
    _subscribedOrderIds.add(orderId);
    if (_socket?.connected != true) {
      await connect();
    }
    if (_socket?.connected == true) {
      _socket!.emit('tracking:subscribe', {'orderId': orderId});
      if (kDebugMode) debugPrint('$_socketLogPrefix تم إرسال اشتراك تتبع للطلب: $orderId');
    } else {
      if (kDebugMode) debugPrint('$_socketLogPrefix لم يُرسل الاشتراك (الاتصال فشل أو انتهت المهلة) للطلب: $orderId');
    }
  }

  /// إلغاء الاشتراك في تتبع طلب.
  void unsubscribeFromOrderTracking(String orderId) {
    if (orderId.isEmpty) return;
    _subscribedOrderIds.remove(orderId);
    if (_socket?.connected == true) {
      _socket!.emit('tracking:unsubscribe', {'orderId': orderId});
    }
  }

  /// إرسال موقع السائق (للتطبيق جانب السائق).
  void sendDriverLocation(String orderId, double lat, double lng) {
    if (_socket?.connected != true) return;
    _socket!.emit('driver:location', {
      'orderId': orderId,
      'lat': lat,
      'lng': lng,
    });
  }

  /// تحرير الموارد.
  void dispose() {
    disconnect();
    _driverLocationController.close();
    _trackingEndedController.close();
  }
}
