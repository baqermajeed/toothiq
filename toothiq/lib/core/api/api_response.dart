class ApiErrorBody {
  final String code;
  final String message;

  const ApiErrorBody({
    required this.code,
    required this.message,
  });

  factory ApiErrorBody.fromJson(Map<String, dynamic> json) {
    return ApiErrorBody(
      code: json['code']?.toString() ?? 'UNKNOWN',
      message: json['message']?.toString() ?? 'حدث خطأ غير متوقع',
    );
  }
}

class ApiEnvelope<T> {
  final bool success;
  final T? data;
  final ApiErrorBody? error;

  const ApiEnvelope({
    required this.success,
    this.data,
    this.error,
  });

  factory ApiEnvelope.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json)? parseData,
  ) {
    return ApiEnvelope(
      success: json['success'] == true,
      data: parseData != null && json['data'] != null
          ? parseData(json['data'])
          : json['data'] as T?,
      error: json['error'] is Map<String, dynamic>
          ? ApiErrorBody.fromJson(json['error'] as Map<String, dynamic>)
          : null,
    );
  }
}
