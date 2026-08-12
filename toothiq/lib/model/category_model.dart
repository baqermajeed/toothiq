import 'package:flutter/material.dart';

enum CategorySource { admin, shop }

class CategoryModel {
  final String id;
  final String name;
  final String? iconUrl;
  final IconData icon;
  final Color iconColor;
  final CategorySource source;
  final String? shopId;
  final String? productCategoryId;

  const CategoryModel({
    required this.id,
    required this.name,
    this.iconUrl,
    this.icon = Icons.category_outlined,
    this.iconColor = const Color(0xFF179BAE),
    this.source = CategorySource.admin,
    this.shopId,
    this.productCategoryId,
  });

  bool get hasIconImage => iconUrl != null && iconUrl!.trim().isNotEmpty;

  bool get isShopCategory => source == CategorySource.shop;

  bool get isShopScoped => shopId != null && shopId!.isNotEmpty;

  String get filterId => productCategoryId ?? id;
}
