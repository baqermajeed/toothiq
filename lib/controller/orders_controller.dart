import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../model/order_model.dart';

class OrdersController extends GetxController {
  final searchController = TextEditingController();
  final filteredOrders = <OrderModel>[].obs;

  final orders = <OrderModel>[
    const OrderModel(
      id: '1',
      orderName: 'أسم الطلب',
      storeName: 'أسم المتجر',
      price: 26000,
      imageAsset: 'assets/images/products/product_1.png',
      status: OrderStatus.inDelivery,
    ),
    const OrderModel(
      id: '2',
      orderName: 'أسم الطلب',
      storeName: 'أسم المتجر',
      price: 26000,
      imageAsset: 'assets/images/products/product_2.png',
      status: OrderStatus.delivered,
    ),
    const OrderModel(
      id: '3',
      orderName: 'أسم الطلب',
      storeName: 'أسم المتجر',
      price: 26000,
      imageAsset: 'assets/images/products/product_1.png',
      status: OrderStatus.canceled,
    ),
    const OrderModel(
      id: '4',
      orderName: 'أسم الطلب',
      storeName: 'أسم المتجر',
      price: 26000,
      imageAsset: 'assets/images/products/product_2.png',
      status: OrderStatus.inDelivery,
    ),
    const OrderModel(
      id: '5',
      orderName: 'أسم الطلب',
      storeName: 'أسم المتجر',
      price: 26000,
      imageAsset: 'assets/images/products/product_1.png',
      status: OrderStatus.delivered,
    ),
    const OrderModel(
      id: '6',
      orderName: 'أسم الطلب',
      storeName: 'أسم المتجر',
      price: 26000,
      imageAsset: 'assets/images/products/product_2.png',
      status: OrderStatus.inDelivery,
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    filteredOrders.assignAll(orders);
    searchController.addListener(_onSearch);
  }

  @override
  void onClose() {
    searchController.removeListener(_onSearch);
    searchController.dispose();
    super.onClose();
  }

  void _onSearch() {
    final query = searchController.text.trim();
    if (query.isEmpty) {
      filteredOrders.assignAll(orders);
      return;
    }
    filteredOrders.assignAll(
      orders
          .where(
            (o) =>
                o.orderName.contains(query) || o.storeName.contains(query),
          )
          .toList(),
    );
  }

  void onFilterTap() {
    // TODO: فلترة حسب حالة الطلب عند ربط الـ API
  }
}
