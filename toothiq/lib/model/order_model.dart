import 'package:flutter/material.dart';

import '../core/utils/image_url.dart';
import '../utils/app_colors.dart';

enum OrderStatus {
  pending('قيد المراجعة'),
  accepted('مقبول'),
  inDelivery('قيد التحضير'),
  onTheWay('في الطريق'),
  delivered('تم التوصيل'),
  canceled('ملغي');

  final String label;
  const OrderStatus(this.label);

  Color get backgroundColor {
    switch (this) {
      case OrderStatus.accepted:
      case OrderStatus.inDelivery:
        return AppColors.orderStatusInDeliveryBg;
      case OrderStatus.onTheWay:
        return AppColors.orderStatusInDeliveryBg;
      case OrderStatus.delivered:
        return AppColors.orderStatusDeliveredBg;
      case OrderStatus.canceled:
        return AppColors.orderStatusCanceledBg;
      case OrderStatus.pending:
        return AppColors.orderStatusInDeliveryBg;
    }
  }

  Color get textColor {
    switch (this) {
      case OrderStatus.pending:
        return AppColors.orderStatusInDeliveryText;
      case OrderStatus.accepted:
      case OrderStatus.inDelivery:
        return AppColors.orderStatusInDeliveryText;
      case OrderStatus.onTheWay:
        return AppColors.orderStatusInDeliveryText;
      case OrderStatus.delivered:
        return AppColors.orderStatusDeliveredText;
      case OrderStatus.canceled:
        return AppColors.orderStatusCanceledText;
    }
  }
}

class OrderModel {
  final String id;
  final String orderName;
  final String storeName;
  final int price;
  final String imageAsset;
  final OrderStatus status;

  const OrderModel({
    required this.id,
    required this.orderName,
    required this.storeName,
    required this.price,
    required this.imageAsset,
    required this.status,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final firstItem = OrderJsonParser.firstLineItem(json);
    final image = ImageUrl.resolve(
      firstItem?['image']?.toString() ??
          (firstItem?['productId'] is Map<String, dynamic>
              ? (firstItem!['productId'] as Map<String, dynamic>)['image']
                  ?.toString()
              : null),
      fallback: ImageUrl.productPlaceholder,
    );

    final total = OrderJsonParser.orderSubtotal(json);
    final orderNumber = json['orderNumber'];
    final itemName = firstItem?['name']?.toString().trim();
    final orderId = json['_id']?.toString() ?? json['id']?.toString() ?? '';

    return OrderModel(
      id: orderId,
      orderName: itemName?.isNotEmpty == true
          ? itemName!
          : orderNumber != null
          ? 'طلب #$orderNumber'
          : 'طلب #${orderId.length > 6 ? orderId.substring(orderId.length - 6) : orderId}',
      storeName: OrderJsonParser.storeName(json) ?? 'متجر',
      price: total,
      imageAsset: image,
      status: _mapStatus(json['status']?.toString()),
    );
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

  String get formattedPrice {
    final formatted = price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$formatted د.ع';
  }
}

/// استخراج حقول الطلب من رد الباكند (يدعم shopPortions).
abstract final class OrderJsonParser {
  static List<Map<String, dynamic>> lineItems(Map<String, dynamic> json) {
    final direct = json['items'];
    if (direct is List && direct.isNotEmpty) {
      return direct.whereType<Map<String, dynamic>>().toList(growable: false);
    }

    final portions = json['shopPortions'];
    if (portions is! List) return const [];

    final merged = <Map<String, dynamic>>[];
    for (final portion in portions.whereType<Map<String, dynamic>>()) {
      final portionItems = portion['items'];
      if (portionItems is List) {
        merged.addAll(portionItems.whereType<Map<String, dynamic>>());
      }
    }
    return merged;
  }

  static Map<String, dynamic>? firstLineItem(Map<String, dynamic> json) {
    final items = lineItems(json);
    return items.isEmpty ? null : items.first;
  }

  static String? storeName(Map<String, dynamic> json) {
    final direct = json['shopName']?.toString().trim();
    if (direct != null && direct.isNotEmpty) return direct;

    final shop = json['shopId'];
    if (shop is Map<String, dynamic>) {
      final name = shop['name']?.toString().trim();
      if (name != null && name.isNotEmpty) return name;
    }

    final shopObj = json['shop'];
    if (shopObj is Map<String, dynamic>) {
      final name = shopObj['name']?.toString().trim();
      if (name != null && name.isNotEmpty) return name;
    }

    final portions = json['shopPortions'];
    if (portions is List) {
      for (final portion in portions.whereType<Map<String, dynamic>>()) {
        final shopRef = portion['shopId'];
        if (shopRef is Map<String, dynamic>) {
          final name = shopRef['name']?.toString().trim();
          if (name != null && name.isNotEmpty) return name;
        }
      }
    }

    return null;
  }

  static String? shopId(Map<String, dynamic> json) {
    final shop = json['shopId'];
    if (shop is Map<String, dynamic>) {
      return shop['_id']?.toString() ?? shop['id']?.toString();
    }
    if (shop != null) return shop.toString();

    final portions = json['shopPortions'];
    if (portions is List && portions.isNotEmpty) {
      final first = portions.first;
      if (first is Map<String, dynamic>) {
        final shopRef = first['shopId'];
        if (shopRef is Map<String, dynamic>) {
          return shopRef['_id']?.toString() ?? shopRef['id']?.toString();
        }
        return shopRef?.toString();
      }
    }
    return null;
  }

  static Map<String, dynamic>? shopMap(Map<String, dynamic> json) {
    final shop = json['shopId'];
    if (shop is Map<String, dynamic>) return shop;

    final portions = json['shopPortions'];
    if (portions is List && portions.isNotEmpty) {
      final first = portions.first;
      if (first is Map<String, dynamic>) {
        final shopRef = first['shopId'];
        if (shopRef is Map<String, dynamic>) return shopRef;
      }
    }
    return null;
  }

  static int orderSubtotal(Map<String, dynamic> json) {
    final totalPrice = (json['totalPrice'] as num?)?.toInt();
    if (totalPrice != null && totalPrice > 0) return totalPrice;

    final totalAmount = (json['totalAmount'] as num?)?.toInt();
    if (totalAmount != null && totalAmount > 0) return totalAmount;

    final total = (json['total'] as num?)?.toInt();
    if (total != null && total > 0) return total;

    final items = lineItems(json);
    var sum = 0;
    for (final item in items) {
      final price = lineItemUnitPrice(item);
      final qty = (item['quantity'] as num?)?.toInt() ?? 1;
      sum += price * qty;
    }
    return sum;
  }

  static int deliveryFee(Map<String, dynamic> json) {
    return (json['deliveryFee'] as num?)?.toInt() ?? 0;
  }

  static int readAmount(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null) return parsed;
      final asDouble = double.tryParse(value.trim());
      if (asDouble != null) return asDouble.toInt();
    }
    return 0;
  }

  static int lineItemUnitPrice(Map<String, dynamic> raw) {
    final product = raw['productId'];
    final productMap = product is Map<String, dynamic> ? product : null;

    for (final key in ['unitPrice', 'price', 'offerPrice']) {
      final direct = readAmount(raw[key]);
      if (direct > 0) return direct;
    }

    if (productMap != null) {
      for (final key in ['offerPrice', 'price', 'unitPrice']) {
        final nested = readAmount(productMap[key]);
        if (nested > 0) return nested;
      }
    }

    return 0;
  }
}
