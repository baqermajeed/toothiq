import 'package:flutter/material.dart';

import '../core/utils/order_json_parser.dart';
import '../utils/app_colors.dart';

enum PartnerOrderStatus {
  pending('قيد المراجعة', 'pending'),
  accepted('مقبول', 'accepted'),
  preparing('قيد التحضير', 'preparing'),
  onTheWay('في الطريق', 'on_the_way'),
  delivered('تم التوصيل', 'delivered'),
  canceled('ملغي', 'canceled'),
  postponed('مؤجل', 'postponed');

  final String label;
  final String apiValue;

  const PartnerOrderStatus(this.label, this.apiValue);

  Color get backgroundColor {
    switch (this) {
      case PartnerOrderStatus.pending:
        return AppColors.orderStatusPendingBg;
      case PartnerOrderStatus.accepted:
      case PartnerOrderStatus.preparing:
        return AppColors.orderStatusAcceptedBg;
      case PartnerOrderStatus.onTheWay:
        return AppColors.orderStatusPendingBg;
      case PartnerOrderStatus.delivered:
        return AppColors.orderStatusDeliveredBg;
      case PartnerOrderStatus.canceled:
      case PartnerOrderStatus.postponed:
        return AppColors.orderStatusCanceledBg;
    }
  }

  Color get textColor {
    switch (this) {
      case PartnerOrderStatus.pending:
        return AppColors.orderStatusPendingText;
      case PartnerOrderStatus.accepted:
      case PartnerOrderStatus.preparing:
        return AppColors.orderStatusAcceptedText;
      case PartnerOrderStatus.onTheWay:
        return AppColors.orderStatusPendingText;
      case PartnerOrderStatus.delivered:
        return AppColors.orderStatusDeliveredText;
      case PartnerOrderStatus.canceled:
      case PartnerOrderStatus.postponed:
        return AppColors.orderStatusCanceledText;
    }
  }

  static PartnerOrderStatus fromApi(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'accepted':
        return PartnerOrderStatus.accepted;
      case 'preparing':
        return PartnerOrderStatus.preparing;
      case 'on_the_way':
        return PartnerOrderStatus.onTheWay;
      case 'delivered':
        return PartnerOrderStatus.delivered;
      case 'canceled':
      case 'cancelled':
        return PartnerOrderStatus.canceled;
      case 'postponed':
        return PartnerOrderStatus.postponed;
      default:
        return PartnerOrderStatus.pending;
    }
  }
}

class PartnerOrder {
  final String id;
  final String orderNumber;
  final String customerName;
  final String customerPhone;
  final String shopName;
  final String shopAddress;
  final String customerAddress;
  final int totalPrice;
  final int deliveryFee;
  final String? shopPhone;
  final String? shopId;
  final int itemCount;
  final PartnerOrderStatus status;
  final double? shopLat;
  final double? shopLng;
  final double? customerLat;
  final double? customerLng;
  final List<PartnerOrderItem> items;
  final DateTime createdAt;

  const PartnerOrder({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.customerPhone,
    required this.shopName,
    required this.shopAddress,
    required this.customerAddress,
    required this.totalPrice,
    this.deliveryFee = 2000,
    this.shopPhone,
    this.shopId,
    required this.itemCount,
    required this.status,
    this.shopLat,
    this.shopLng,
    this.customerLat,
    this.customerLng,
    this.items = const [],
    required this.createdAt,
  });

  int get amountToCollectFromCustomer => totalPrice;

  int get amountToGiveShop => totalPrice - deliveryFee;

  String get formattedTotal => _formatPrice(totalPrice);

  String get formattedDeliveryFee => _formatPrice(deliveryFee);

  String get formattedShopAmount => _formatPrice(amountToGiveShop);

  String get formattedCreatedAt {
    final d = createdAt;
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '$day-$month-${d.year} $hour:$minute';
  }

  static String _formatPrice(int value) {
    final formatted = value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$formatted د.ع';
  }

  PartnerOrder copyWith({
    PartnerOrderStatus? status,
    int? deliveryFee,
    String? shopPhone,
    String? shopId,
  }) {
    return PartnerOrder(
      id: id,
      orderNumber: orderNumber,
      customerName: customerName,
      customerPhone: customerPhone,
      shopName: shopName,
      shopAddress: shopAddress,
      customerAddress: customerAddress,
      totalPrice: totalPrice,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      shopPhone: shopPhone ?? this.shopPhone,
      shopId: shopId ?? this.shopId,
      itemCount: itemCount,
      status: status ?? this.status,
      shopLat: shopLat,
      shopLng: shopLng,
      customerLat: customerLat,
      customerLng: customerLng,
      items: items,
      createdAt: createdAt,
    );
  }

  factory PartnerOrder.fromApi(Map<String, dynamic> json) {
    final shopMap = OrderJsonParser.shopMap(json);
    final customerRaw = json['customerId'] ?? json['customer'];
    final customerMap =
        customerRaw is Map<String, dynamic> ? customerRaw : null;
    final deliveryLocation = json['deliveryLocation'];
    final (customerLat, customerLng) =
        OrderJsonParser.readCoordinates(deliveryLocation);
    final (shopLat, shopLng) = OrderJsonParser.readCoordinates(
      shopMap?['location'],
    );

    var deliveryAddress = json['deliveryAddress']?.toString().trim() ?? '';
    if (deliveryAddress.isEmpty && deliveryLocation is Map<String, dynamic>) {
      deliveryAddress = deliveryLocation['address']?.toString() ??
          deliveryLocation['governorate']?.toString() ??
          '';
    }
    final notes = json['notes']?.toString().trim();
    if (deliveryAddress.isEmpty && notes != null && notes.isNotEmpty) {
      deliveryAddress = notes;
    }

    final lineItems = OrderJsonParser.lineItems(json);
    final items = lineItems
        .map(
          (raw) => PartnerOrderItem(
            name: raw['name']?.toString() ??
                (raw['productId'] is Map<String, dynamic>
                    ? (raw['productId'] as Map<String, dynamic>)['name']
                        ?.toString()
                    : null) ??
                'منتج',
            quantity: (raw['quantity'] as num?)?.toInt() ?? 1,
            price: OrderJsonParser.lineItemUnitPrice(raw),
          ),
        )
        .toList(growable: false);

    final orderId = json['_id']?.toString() ?? json['id']?.toString() ?? '';
    final orderNumber = json['orderNumber']?.toString() ??
        (orderId.length > 6 ? orderId.substring(orderId.length - 6) : orderId);
    final createdAt =
        DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now();

    return PartnerOrder(
      id: orderId,
      orderNumber: orderNumber,
      customerName: customerMap?['name']?.toString() ??
          json['customerName']?.toString() ??
          'عميل',
      customerPhone: customerMap?['phone']?.toString() ??
          json['customerPhone']?.toString() ??
          '',
      shopName: OrderJsonParser.storeName(json) ?? 'المتجر',
      shopAddress: _shopAddress(shopMap),
      customerAddress:
          deliveryAddress.isNotEmpty ? deliveryAddress : 'غير متوفر',
      totalPrice: OrderJsonParser.orderSubtotal(json),
      deliveryFee: OrderJsonParser.deliveryFee(json),
      shopPhone: shopMap?['phone']?.toString(),
      shopId: OrderJsonParser.shopId(json),
      itemCount: items.fold<int>(0, (sum, item) => sum + item.quantity),
      status: PartnerOrderStatus.fromApi(json['status']?.toString()),
      shopLat: shopLat,
      shopLng: shopLng,
      customerLat: customerLat,
      customerLng: customerLng,
      items: items,
      createdAt: createdAt,
    );
  }

  static String _shopAddress(Map<String, dynamic>? shopMap) {
    if (shopMap == null) return 'غير متوفر';
    final direct = shopMap['address']?.toString().trim();
    if (direct != null && direct.isNotEmpty) return direct;
    final location = shopMap['location'];
    if (location is Map<String, dynamic>) {
      final address = location['address']?.toString().trim();
      if (address != null && address.isNotEmpty) return address;
    }
    return shopMap['description']?.toString() ?? 'غير متوفر';
  }
}

class PartnerOrderItem {
  final String name;
  final int quantity;
  final int price;

  const PartnerOrderItem({
    required this.name,
    required this.quantity,
    required this.price,
  });
}
