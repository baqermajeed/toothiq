import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

enum OrderStatus {
  inDelivery('قيد التوصيل'),
  delivered('تم التوصيل'),
  canceled('ملغي');

  final String label;
  const OrderStatus(this.label);

  Color get backgroundColor {
    switch (this) {
      case OrderStatus.inDelivery:
        return AppColors.orderStatusInDeliveryBg;
      case OrderStatus.delivered:
        return AppColors.orderStatusDeliveredBg;
      case OrderStatus.canceled:
        return AppColors.orderStatusCanceledBg;
    }
  }

  Color get textColor {
    switch (this) {
      case OrderStatus.inDelivery:
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

  String get formattedPrice {
    final formatted = price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$formatted د.ع';
  }
}
