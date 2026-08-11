import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../model/cart_item_model.dart';
import '../../model/order_detail_model.dart';
import '../../model/order_model.dart';

class OrderService {
  final ApiClient _api;

  OrderService(this._api);

  Future<List<OrderModel>> listOrders({
    String? status,
    int page = 1,
    int limit = 20,
  }) {
    return _api.getOrders(status: status, page: page, limit: limit);
  }

  Future<void> createOrder({
    required String shopId,
    required List<Map<String, dynamic>> items,
    required List<double> deliveryCoordinates,
    String? deliveryAddress,
    String? notes,
  }) {
    return _api.createOrder(
      shopId: shopId,
      items: items,
      deliveryCoordinates: deliveryCoordinates,
      deliveryAddress: deliveryAddress,
      notes: notes,
    );
  }

  /// نفس فكرة قريب: تحويل عناصر السلة إلى shopPortions وإرسالها بطلب واحد.
  Future<String?> createOrderFromCart({
    required List<CartItemModel> items,
    required String deliveryAddress,
    List<double>? deliveryCoordinates,
    String? notes,
  }) async {
    if (items.isEmpty) {
      throw const ApiException('السلة فارغة');
    }

    final byShop = <String, List<CartItemModel>>{};
    for (final item in items) {
      final shopId = (item.product.shopId ?? '').trim();
      final productId = item.product.id.trim();
      if (shopId.isEmpty || productId.isEmpty) continue;
      byShop.putIfAbsent(shopId, () => []).add(item);
    }

    if (byShop.isEmpty) {
      throw const ApiException(
        'لا يمكن إنشاء الطلب: بيانات المتجر/المنتج غير مكتملة',
      );
    }

    if (deliveryCoordinates == null || deliveryCoordinates.length < 2) {
      throw const ApiException('يرجى تحديد موقع التوصيل على الخريطة');
    }

    final shopPortions = byShop.entries
        .map(
          (entry) => {
            'shopId': entry.key,
            'items': entry.value
                .map(
                  (item) => {
                    'productId': item.product.id,
                    'name': item.product.name,
                    'price': item.product.price,
                    'quantity': item.quantity,
                  },
                )
                .toList(growable: false),
          },
        )
        .toList(growable: false);

    return _api.createOrderFromCart(
      shopPortions: shopPortions,
      deliveryCoordinates: deliveryCoordinates,
      deliveryAddress: deliveryAddress,
      notes: notes,
    );
  }

  Future<OrderDetailModel> getOrderById(String id) {
    return _api.getOrderById(id);
  }
}
