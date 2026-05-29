import 'order_line_item_model.dart';
import 'order_model.dart';

class OrderDetailModel {
  final String id;
  final String customerName;
  final String phone;
  final String altPhone;
  final String deliveryTime;
  final String deliveryAddress;
  final String orderDate;
  final String storeName;
  final String storeAddress;
  final List<OrderLineItemModel> items;
  final String paymentMethod;
  final int orderPrice;
  final String deliveryPriceLabel;
  final int totalPrice;

  const OrderDetailModel({
    required this.id,
    required this.customerName,
    required this.phone,
    required this.altPhone,
    required this.deliveryTime,
    required this.deliveryAddress,
    required this.orderDate,
    required this.storeName,
    required this.storeAddress,
    required this.items,
    required this.paymentMethod,
    required this.orderPrice,
    required this.deliveryPriceLabel,
    required this.totalPrice,
  });

  int get itemCount => items.length;

  String formatPrice(int amount) {
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$formatted د.ع';
  }

  String get formattedOrderPrice => formatPrice(orderPrice);
  String get formattedTotalPrice => formatPrice(totalPrice);

  /// بيانات تجريبية مطابقة لتصميم Check_Order
  factory OrderDetailModel.fromOrder(OrderModel order) {
    return OrderDetailModel(
      id: order.id,
      customerName: 'د. مهجة مصطفى',
      phone: '0700 000 000',
      altPhone: 'لا يوجد',
      deliveryTime: '10:26 مساءً',
      deliveryAddress: 'بابل - شارع 40',
      orderDate: '2026 - 2 - 6',
      storeName: order.storeName == 'أسم المتجر' ? 'ستروبيري' : order.storeName,
      storeAddress: 'بابل - شارع الجمعية',
      items: [
        OrderLineItemModel(
          id: '${order.id}_1',
          name: 'فرشاة أسنان خشبية',
          quantity: 1,
          unitPrice: order.price,
          imageAsset: order.imageAsset,
        ),
        OrderLineItemModel(
          id: '${order.id}_2',
          name: 'فرشاة أسنان خشبية',
          quantity: 1,
          unitPrice: order.price,
          imageAsset: 'assets/images/products/product_2.png',
        ),
      ],
      paymentMethod: 'ماستر كارد ( أسم البطاقة )',
      orderPrice: order.price * 2,
      deliveryPriceLabel: 'مجاني',
      totalPrice: order.price * 2,
    );
  }
}
