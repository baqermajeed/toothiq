/// استثناء يرمى عند فشل طلب الـ API.
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.code,
    this.statusCode,
  });

  factory ApiException.fromResponse(Map<String, dynamic> body, int statusCode) {
    final error = body['error'];
    if (error is Map<String, dynamic>) {
      return ApiException(
        message: error['message'] as String? ?? 'Unknown error',
        code: error['code'] as String?,
        statusCode: statusCode,
      );
    }
    return ApiException(
      message: body['message'] as String? ?? 'Unknown error',
      statusCode: statusCode,
    );
  }

  final String message;
  final String? code;
  final int? statusCode;

  @override
  String toString() => 'ApiException($code, $statusCode): $message';
}
