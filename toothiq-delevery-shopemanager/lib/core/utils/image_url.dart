import '../api/api_config.dart';

class ImageUrl {
  static String resolve(String? value, {String fallback = ''}) {
    if (value == null || value.trim().isEmpty) return fallback;
    final image = value.trim();
    if (image.startsWith('http') || image.startsWith('assets/')) return image;
    final path = image.startsWith('/') ? image : '/$image';
    return '${ApiConfig.baseUrl}$path';
  }

  static bool isNetwork(String source) => source.startsWith('http');
  static bool isLocalFile(String source) =>
      source.isNotEmpty && !isNetwork(source) && !source.startsWith('assets/');
}
