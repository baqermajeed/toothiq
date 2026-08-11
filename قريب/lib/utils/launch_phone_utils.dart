import 'package:url_launcher/url_launcher.dart';

/// فتح تطبيق الهاتف للاتصال بالرقم المعطى.
Future<bool> launchPhoneCall(String phone) async {
  final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
  if (cleaned.isEmpty) return false;
  final uri = Uri.parse('tel:$cleaned');
  if (await canLaunchUrl(uri)) {
    return launchUrl(uri);
  }
  return false;
}

/// فتح واتساب للتواصل مع الرقم المعطى (رقم الدعم).
/// الرقم يُنظّف إلى أرقام فقط (مع كود الدولة).
Future<bool> launchWhatsApp(String phone) async {
  final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
  if (cleaned.isEmpty) return false;
  final uri = Uri.parse('https://wa.me/$cleaned');
  if (await canLaunchUrl(uri)) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
  return false;
}

/// فتح رابط في المتصفح أو التطبيق المناسب.
Future<bool> launchUrlString(String url) async {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return false;
  Uri? uri = Uri.tryParse(trimmed);
  if (uri == null || (!uri.hasScheme && trimmed.isNotEmpty)) {
    uri = Uri.parse('https://$trimmed');
  }
  if (await canLaunchUrl(uri)) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
  return false;
}
