import 'driver_review_model.dart';
import 'order_line_item_model.dart';
import 'order_model.dart';
import '../core/utils/image_url.dart';

class OrderDetailModel {
  final String id;
  final String shopId;
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
  final OrderStatus status;
  final double? deliveryLat;
  final double? deliveryLng;
  final String? driverId;
  final String? driverName;
  final String? driverPhone;
  final double? driverLat;
  final double? driverLng;
  final DriverReviewModel? driverReview;

  const OrderDetailModel({
    required this.id,
    required this.shopId,
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
    this.status = OrderStatus.pending,
    this.deliveryLat,
    this.deliveryLng,
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.driverLat,
    this.driverLng,
    this.driverReview,
  });

  bool get canTrackOnMap =>
      status == OrderStatus.onTheWay &&
      ((deliveryLat != null && deliveryLng != null) ||
          (driverLat != null && driverLng != null));

  int get itemCount => items.length;

  bool get canRateDriver =>
      status == OrderStatus.delivered &&
      driverId != null &&
      driverId!.trim().isNotEmpty;

  bool get hasDriverReview =>
      driverReview != null && driverReview!.rating > 0;

  String formatPrice(int amount) {
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$formatted د.ع';
  }

  String get formattedOrderPrice => formatPrice(orderPrice);
  String get formattedTotalPrice => formatPrice(totalPrice);

  OrderDetailModel copyWithDriverLocation({
    double? driverLat,
    double? driverLng,
  }) {
    return OrderDetailModel(
      id: id,
      shopId: shopId,
      customerName: customerName,
      phone: phone,
      altPhone: altPhone,
      deliveryTime: deliveryTime,
      deliveryAddress: deliveryAddress,
      orderDate: orderDate,
      storeName: storeName,
      storeAddress: storeAddress,
      items: items,
      paymentMethod: paymentMethod,
      orderPrice: orderPrice,
      deliveryPriceLabel: deliveryPriceLabel,
      totalPrice: totalPrice,
      status: status,
      deliveryLat: deliveryLat,
      deliveryLng: deliveryLng,
      driverId: driverId,
      driverName: driverName,
      driverPhone: driverPhone,
      driverLat: driverLat ?? this.driverLat,
      driverLng: driverLng ?? this.driverLng,
      driverReview: driverReview,
    );
  }

  OrderDetailModel copyWithDriverReview(DriverReviewModel? review) {
    return OrderDetailModel(
      id: id,
      shopId: shopId,
      customerName: customerName,
      phone: phone,
      altPhone: altPhone,
      deliveryTime: deliveryTime,
      deliveryAddress: deliveryAddress,
      orderDate: orderDate,
      storeName: storeName,
      storeAddress: storeAddress,
      items: items,
      paymentMethod: paymentMethod,
      orderPrice: orderPrice,
      deliveryPriceLabel: deliveryPriceLabel,
      totalPrice: totalPrice,
      status: status,
      deliveryLat: deliveryLat,
      deliveryLng: deliveryLng,
      driverId: driverId,
      driverName: driverName,
      driverPhone: driverPhone,
      driverLat: driverLat,
      driverLng: driverLng,
      driverReview: review,
    );
  }

  factory OrderDetailModel.fromApi(Map<String, dynamic> json) {
    final parsedItems = <OrderLineItemModel>[];

    for (final raw in OrderJsonParser.lineItems(json)) {
      final product = raw['productId'];
      final productMap = product is Map<String, dynamic> ? product : null;
      final image = ImageUrl.resolve(
        raw['image']?.toString() ?? productMap?['image']?.toString(),
        fallback: ImageUrl.productPlaceholder,
      );

      parsedItems.add(
        OrderLineItemModel(
          id: raw['_id']?.toString() ?? raw['id']?.toString() ?? '',
          productId: productMap?['_id']?.toString() ??
              (product is String ? product : raw['productId']?.toString()),
          name: raw['name']?.toString() ??
              productMap?['name']?.toString() ??
              'منتج',
          quantity: (raw['quantity'] as num?)?.toInt() ?? 1,
          unitPrice: OrderJsonParser.lineItemUnitPrice(raw),
          imageAsset: image,
        ),
      );
    }

    final subtotal = OrderJsonParser.orderSubtotal(json);
    if (parsedItems.length == 1) {
      final item = parsedItems.first;
      if (item.unitPrice == 0 && subtotal > 0) {
        final qty = item.quantity > 0 ? item.quantity : 1;
        parsedItems[0] = OrderLineItemModel(
          id: item.id,
          productId: item.productId,
          name: item.name,
          quantity: item.quantity,
          unitPrice: subtotal ~/ qty,
          imageAsset: item.imageAsset,
        );
      }
    }

    final deliveryLocation = json['deliveryLocation'];
    String deliveryAddress = '';
    double? deliveryLat;
    double? deliveryLng;
    if (deliveryLocation is Map<String, dynamic>) {
      deliveryAddress = deliveryLocation['address']?.toString() ??
          deliveryLocation['governorate']?.toString() ??
          '';
      final coords = deliveryLocation['coordinates'];
      if (coords is List && coords.length >= 2) {
        final lng = (coords[0] is num) ? (coords[0] as num).toDouble() : null;
        final lat = (coords[1] is num) ? (coords[1] as num).toDouble() : null;
        if (lng != null && lat != null) {
          deliveryLat = lat;
          deliveryLng = lng;
        }
      }
    }
    final notes = json['notes']?.toString().trim();
    if (deliveryAddress.isEmpty && notes != null && notes.isNotEmpty) {
      deliveryAddress = notes;
    }

    final customer = json['customerId'];
    final customerMap = customer is Map<String, dynamic> ? customer : null;
    final shopMap = OrderJsonParser.shopMap(json);
    final createdAt = DateTime.tryParse(json['createdAt']?.toString() ?? '');

    final deliveryFee = OrderJsonParser.deliveryFee(json);

    String? driverId;
    String? driverName;
    String? driverPhone;
    double? driverLat;
    double? driverLng;
    final driver = json['driverId'];
    if (driver is Map<String, dynamic>) {
      driverId = (driver['_id'] ?? driver['id'])?.toString();
      driverName = driver['name']?.toString();
      driverPhone = driver['phone']?.toString();
      final driverLoc = driver['location'];
      if (driverLoc is Map<String, dynamic> && driverLoc['coordinates'] is List) {
        final coords = driverLoc['coordinates'] as List;
        if (coords.length >= 2) {
          final lng = (coords[0] is num) ? (coords[0] as num).toDouble() : null;
          final lat = (coords[1] is num) ? (coords[1] as num).toDouble() : null;
          if (lng != null && lat != null) {
            driverLat = lat;
            driverLng = lng;
          }
        }
      }
    } else if (driver != null) {
      driverId = driver.toString();
    }
    driverId ??= json['driverUserId']?.toString();

    DriverReviewModel? driverReview;
    final rawReview = json['driverReview'];
    if (rawReview is Map && rawReview.isNotEmpty) {
      final parsed = DriverReviewModel.fromJson(
        Map<String, dynamic>.from(rawReview),
      );
      if (parsed.rating > 0) driverReview = parsed;
    }

    return OrderDetailModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      shopId: OrderJsonParser.shopId(json) ?? '',
      customerName: customerMap?['name']?.toString() ?? 'غير متوفر',
      phone: customerMap?['phone']?.toString() ?? 'غير متوفر',
      altPhone: 'لا يوجد',
      deliveryTime: 'حسب توفر المندوب',
      deliveryAddress: deliveryAddress.isNotEmpty ? deliveryAddress : 'غير متوفر',
      orderDate: createdAt != null
          ? '${createdAt.year} - ${createdAt.month} - ${createdAt.day}'
          : 'غير متوفر',
      storeName: OrderJsonParser.storeName(json) ?? 'المتجر',
      storeAddress: _shopAddress(shopMap),
      items: parsedItems,
      paymentMethod: 'عند الأستلام',
      orderPrice: subtotal,
      deliveryPriceLabel: deliveryFee == 0 ? 'مجاني' : formatAmount(deliveryFee),
      totalPrice: subtotal + deliveryFee,
      status: _mapStatus(json['status']?.toString()),
      deliveryLat: deliveryLat,
      deliveryLng: deliveryLng,
      driverId: driverId,
      driverName: driverName,
      driverPhone: driverPhone,
      driverLat: driverLat,
      driverLng: driverLng,
      driverReview: driverReview,
    );
  }

  static String _shopAddress(Map<String, dynamic>? shopMap) {
    if (shopMap == null) return 'غير متوفر';

    final directAddress = shopMap['address']?.toString().trim();
    if (directAddress != null && directAddress.isNotEmpty) {
      return directAddress;
    }

    final location = shopMap['location'];
    if (location is Map<String, dynamic>) {
      final address = location['address']?.toString().trim();
      if (address != null && address.isNotEmpty) return address;

      final parts = <String>[
        location['governorate']?.toString().trim() ?? '',
        location['area']?.toString().trim() ?? '',
        location['landmark']?.toString().trim() ?? '',
      ].where((part) => part.isNotEmpty).toList(growable: false);
      if (parts.isNotEmpty) {
        return parts.join(' ، ');
      }
    }

    return 'غير متوفر';
  }

  static OrderStatus _mapStatus(String? raw) {
    final value = raw?.trim().toLowerCase();
    switch (value) {
      case 'on_the_way':
      case 'on the way':
        return OrderStatus.onTheWay;
      case 'preparing':
        return OrderStatus.inDelivery;
      case 'accepted':
        return OrderStatus.accepted;
      case 'postponed':
        return OrderStatus.inDelivery;
      case 'delivered':
        return OrderStatus.delivered;
      case 'canceled':
      case 'cancelled':
        return OrderStatus.canceled;
      case 'pending':
        return OrderStatus.pending;
      default:
        return OrderStatus.pending;
    }
  }

  static String formatAmount(int amount) {
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$formatted د.ع';
  }
}
