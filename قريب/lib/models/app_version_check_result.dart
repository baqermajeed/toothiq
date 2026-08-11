/// نتيجة التحقق من إصدار التطبيق من الـ API.
class AppVersionCheckResult {
  const AppVersionCheckResult({
    required this.updateRequired,
    required this.forceUpdate,
    required this.storeUrl,
    required this.currentVersion,
    required this.minimumVersion,
  });

  final bool updateRequired;
  final bool forceUpdate;
  final String storeUrl;
  final String currentVersion;
  final String minimumVersion;

  factory AppVersionCheckResult.fromJson(Map<String, dynamic> json) {
    return AppVersionCheckResult(
      updateRequired: json['updateRequired'] as bool? ?? false,
      forceUpdate: json['forceUpdate'] as bool? ?? false,
      storeUrl: json['storeUrl'] as String? ?? '',
      currentVersion: json['currentVersion'] as String? ?? '',
      minimumVersion: json['minimumVersion'] as String? ?? '',
    );
  }
}
