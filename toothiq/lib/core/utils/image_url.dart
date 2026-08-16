import '../api/api_config.dart';

class ImageUrl {
  static const String productPlaceholder = 'assets/images/products/product_1.png';
  static const String bannerPlaceholder = 'assets/images/banners/promo_banner.png';

  /// صورة افتراضية قديمة من الـ API — الملف غير موجود على السيرفر (404).
  static bool _isMissingRemotePlaceholder(String image) {
    return image.contains('photo_2026-03-18 00.25.48') ||
        image.contains('photo_2026-03-18%2000.25.48');
  }

  static String resolve(String? value, {String fallback = productPlaceholder}) {
    if (value == null || value.trim().isEmpty) return fallback;
    final image = value.trim();
    if (_isMissingRemotePlaceholder(image)) return fallback;
    if (image.startsWith('assets/')) return image;
    if (image.startsWith('http')) return image;
    final path = image.startsWith('/') ? image : '/$image';
    return '${ApiConfig.baseUrl}$path';
  }

  static bool isNetwork(String source) => source.startsWith('http');
}
