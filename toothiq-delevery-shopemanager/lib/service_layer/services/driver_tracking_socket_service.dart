import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../core/api/api_config.dart';
import 'token_storage.dart';

/// Socket للتوصيل: استقبال تتبع + إرسال موقع السائق (مثل قريب / ToothIQ).
class DriverTrackingSocketService {
  DriverTrackingSocketService({
    required TokenStorage tokenStorage,
    String? baseUrl,
  }) : _tokenStorage = tokenStorage,
       _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final TokenStorage _tokenStorage;
  final String _baseUrl;

  io.Socket? _socket;

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect() async {
    if (_socket?.connected == true) return;

    final token = await _tokenStorage.getAccessToken();
    if (token == null || token.isEmpty) return;

    _socket = io.io(
      _baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(1000)
          .setAuth({'token': 'Bearer $token'})
          .build(),
    );

    _socket!.onConnect((_) {
      if (kDebugMode) debugPrint('[Socket] connected');
    });

    _socket!.connect();
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
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void dispose() => disconnect();
}
