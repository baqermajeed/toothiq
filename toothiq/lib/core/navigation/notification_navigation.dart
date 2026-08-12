import '../../model/order_model.dart';
import '../../model/product_model.dart';
import '../../model/store_model.dart';
import '../../view/orders/order_detail_page.dart';
import '../../view/product/product_details_page.dart';
import '../../view/stores/store_detail_page.dart';

const _orderNotificationTypes = {
  'order_accepted',
  'order_preparing',
  'order_on_the_way',
  'order_delivered',
  'order_canceled',
  'order_postponed',
  'new_order',
};

bool isOrderNotificationType(String? type) {
  if (type == null || type.isEmpty) return false;
  return _orderNotificationTypes.contains(type) || type.startsWith('order_');
}

/// توجيه الإشعارات حسب النوع: طلب / منتج / متجر.
void navigateFromNotificationPayload(
  String? type, {
  String? orderId,
  String? productId,
  String? shopId,
  String? storeId,
  Map<String, String?>? data,
}) {
  final resolvedType = type ?? data?['type'];
  final resolvedOrderId = orderId ?? data?['orderId'];
  final resolvedProductId = productId ?? data?['productId'];
  final resolvedShopId = shopId ?? data?['shopId'] ?? data?['storeId'];
  final resolvedStoreId = storeId ?? data?['storeId'] ?? data?['shopId'];

  if (resolvedType == 'product' &&
      resolvedProductId != null &&
      resolvedProductId.isNotEmpty) {
    ProductDetailsPage.open(
      ProductModel(
        id: resolvedProductId,
        name: '',
        storeName: '',
        description: '',
        price: 0,
        imageAsset: 'assets/images/products/product_1.png',
        shopId: resolvedShopId,
      ),
    );
    return;
  }

  if (resolvedType == 'store' &&
      resolvedStoreId != null &&
      resolvedStoreId.isNotEmpty) {
    StoreDetailPage.open(
      StoreModel(
        id: resolvedStoreId,
        name: '',
        description: '',
      ),
    );
    return;
  }

  if (resolvedOrderId == null || resolvedOrderId.isEmpty) return;
  if (!isOrderNotificationType(resolvedType) && resolvedType != null) return;

  OrderDetailPage.open(
    OrderModel(
      id: resolvedOrderId,
      orderName: 'طلب #$resolvedOrderId',
      storeName: 'متجر',
      price: 0,
      imageAsset: 'assets/images/products/product_1.png',
      status: OrderStatus.pending,
    ),
  );
}
