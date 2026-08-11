import 'package:get/get.dart';

import '../core/errors/api_exception.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../controllers/auth_controller.dart';

/// خدمة مشتركة لإتمام الطلب من السلة — طلب واحد موحّد (قد يشمل محلات متعددة).
abstract final class OrderService {
  /// إنشاء طلب واحد من عناصر السلة (موحّد لجميع المحلات). يتطلب مصادقة.
  /// [items] عناصر السلة، [lng] و [lat] إحداثيات عنوان التوصيل.
  /// [notes] ملاحظة كتابية، [notesAudioUrl] رابط ملاحظة صوتية (بعد رفع الملف).
  /// يُرجع الطلب المُنشأ. يرمي [ApiException] عند فشل الـ API.
  static Future<Order> createOrderFromCart({
    required List<CartItem> items,
    required double lng,
    required double lat,
    String? notes,
    String? notesAudioUrl,
  }) async {
    if (items.isEmpty) {
      throw const ApiException(message: 'السلة فارغة');
    }
    final api = Get.find<AuthController>().apiClient;

    final byShop = <String, List<CartItem>>{};
    for (final item in items) {
      final shopId = item.product.shopId;
      if (shopId == null || shopId.isEmpty) continue;
      if (item.product.id == null || item.product.id!.isEmpty) continue;
      byShop.putIfAbsent(shopId, () => []).add(item);
    }

    if (byShop.isEmpty) {
      throw const ApiException(message: 'جميع المنتجات تحتاج إلى محل ومعرّف منتج صحيح');
    }

    final shopPortions = byShop.entries
        .map((entry) => {
              'shopId': entry.key,
              'items': entry.value
                  .map((e) => {
                        'productId': e.product.id!,
                        'name': e.product.name,
                        'price': e.product.price.toDouble(),
                        'quantity': e.quantity,
                      })
                  .toList(),
            })
        .toList();

    final coordinates = [lng, lat];
    return api.createOrder(
      shopPortions: shopPortions,
      deliveryCoordinates: coordinates,
      notes: notes,
      notesAudioUrl: notesAudioUrl,
    );
  }

  /// إنشاء طلب صوتي فقط لمحل معيّن (بدون منتجات). يتطلب مصادقة وعنوان توصيل.
  static Future<Order> createVoiceOrder({
    required String shopId,
    required double lng,
    required double lat,
    required String notesAudioUrl,
  }) async {
    final api = Get.find<AuthController>().apiClient;
    final coordinates = [lng, lat];
    return api.createVoiceOrder(
      shopId: shopId,
      deliveryCoordinates: coordinates,
      notesAudioUrl: notesAudioUrl,
    );
  }

  /// إنشاء طلب صوتي عام بدون محل (لمناطق الطلب الصوتي فقط). يتطلب مصادقة وعنوان توصيل.
  static Future<Order> createVoiceOrderWithoutShop({
    required double lng,
    required double lat,
    required String notesAudioUrl,
  }) async {
    final api = Get.find<AuthController>().apiClient;
    final coordinates = [lng, lat];
    return api.createVoiceOrderWithoutShop(
      deliveryCoordinates: coordinates,
      notesAudioUrl: notesAudioUrl,
    );
  }
}
