import '../../model/order_model.dart';
import '../../view/orders/order_detail_page.dart';

/// توجيه الإشعارات إلى صفحة تفاصيل الطلب (مثل قريب).
void navigateFromNotificationPayload(String? type, String? orderId) {
  if ((type == 'order_on_the_way' || type == 'new_order') &&
      orderId != null &&
      orderId.isNotEmpty) {
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
}
