class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;

  const ApiResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json, {
    T Function(dynamic raw)? mapData,
  }) {
    return ApiResponse<T>(
      success: json['success'] == true || json['status'] == 'success',
      message: json['message']?.toString(),
      data: mapData != null && json['data'] != null
          ? mapData(json['data'])
          : json['data'] as T?,
    );
  }
}
