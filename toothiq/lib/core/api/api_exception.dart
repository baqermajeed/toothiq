class ApiException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;

  const ApiException(
    this.message, {
    this.code,
    this.statusCode,
  });

  factory ApiException.fromResponse(
    Map<String, dynamic> body,
    int statusCode,
  ) {
    final error = body['error'];
    if (error is Map<String, dynamic>) {
      return ApiException(
        error['message']?.toString() ?? 'حدث خطأ غير متوقع',
        code: error['code']?.toString(),
        statusCode: statusCode,
      );
    }
    return ApiException(
      body['message']?.toString() ?? 'حدث خطأ غير متوقع',
      statusCode: statusCode,
    );
  }

  /// يُرجع true إن كانت الرسالة تشير إلى أن الموقع خارج منطقة التوصيل.
  static bool isZoneError(ApiException error) {
    final msg = error.message.toLowerCase();
    return msg.contains('outside the delivery zone') ||
        msg.contains('خارج منطقة التوصيل') ||
        msg.contains('not in a voice-order-only zone');
  }

  /// يُرجع true إن كانت المنطقة تدعم طلبات خاصة فقط (مثل قريب).
  static bool isVoiceOrderOnlyError(ApiException error) {
    final msg = error.message.toLowerCase();
    return msg.contains('voice-order-only') ||
        msg.contains('voice order only') ||
        msg.contains('طلبات صوتية فقط');
  }

  @override
  String toString() => message;
}
