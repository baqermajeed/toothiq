/// إعدادات عنوان الـ API.
/// للمحاكي Android استخدم 10.0.2.2 بدلاً من localhost.
abstract final class ApiConfig {
  static const String baseUrl = _baseUrlDev;


  //   static const String baseUrlAndroid = 'http://192.168.0.59:3000';

  // static const String _baseUrlDev = 'http://192.168.0.59:3000';
    static const String baseUrlAndroid = 'https://api.qarreb.online';

  static const String _baseUrlDev = 'https://api.qarreb.online';
  static const String authPrefix = '/api/auth';
  static const String usersPrefix = '/api/users';
  static const String shopsPrefix = '/api/shops';
  static const String productsPrefix = '/api/products';
  static const String ordersPrefix = '/api/orders';
  static const String zonesPrefix = '/api/zones';
  static const String appContactPrefix = '/api/app-contact';
  static const String appVersionPrefix = '/api/app-version';
  static const String categoriesPrefix = '/api/categories';







  /// يُعيد الرابط الكامل لصورة المنتج (المسار من API مثل /uploads/products/xxx).
  static String? productImageUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final base = baseUrl.endsWith('/') ? baseUrl : '$baseUrl';
    final p = path.startsWith('/') ? path : '/$path';
    return '$base$p';
  }

  /// يُعيد الرابط الكامل لصورة المحل (المسار من API مثل /uploads/shops/xxx).
  static String? shopImageUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final base = baseUrl.endsWith('/') ? baseUrl : '$baseUrl';
    final p = path.startsWith('/') ? path : '/$path';
    return '$base$p';
  }

  /// يُعيد الرابط الكامل لصورة المستخدم/السائق (المسار من API مثل /uploads/users/xxx).
  static String? userImageUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final base = baseUrl.endsWith('/') ? baseUrl : '$baseUrl';
    final p = path.startsWith('/') ? path : '/$path';
    return '$base$p';
  }
}
