import '../api/api_config.dart';

class ImageUrl {
  static const String productPlaceholder = 'assets/images/products/product_1.png';
  static const String bannerPlaceholder = 'assets/images/banners/promo_banner.png';

  static String resolve(String? value, {String fallback = productPlaceholder}) {
    if (value == null || value.trim().isEmpty) return fallback;
    final image = value.trim();
    if (image.startsWith('http') || image.startsWith('assets/')) return image;
    final path = image.startsWith('/') ? image : '/$image';
    return '${ApiConfig.baseUrl}$path';
  }

  static bool isNetwork(String source) => source.startsWith('http');
}
