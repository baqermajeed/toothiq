import '../../model/order_model.dart';
import '../../view/orders/order_detail_page.dart';

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

/// توجيه إشعارات الطلب إلى صفحة تفاصيل الطلب.
void navigateFromNotificationPayload(String? type, String? orderId) {
  if (orderId == null || orderId.isEmpty) return;
  if (!isOrderNotificationType(type) && type != null) return;

  OrderDetailPage.open(
    OrderModel(
      id: orderId,
      orderName: 'طلب #$orderId',
      storeName: 'متجر',
      price: 0,
      imageAsset: 'assets/images/products/product_1.png',
      status: OrderStatus.pending,
    ),
  );
}
