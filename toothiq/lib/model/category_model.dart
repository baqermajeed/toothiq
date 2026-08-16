import 'package:flutter/material.dart';

import 'shop_category_model.dart';

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
  final String? parentCategoryId;

  const CategoryModel({
    required this.id,
    required this.name,
    this.iconUrl,
    this.icon = Icons.category_outlined,
    this.iconColor = const Color(0xFF179BAE),
    this.source = CategorySource.admin,
    this.shopId,
    this.productCategoryId,
    this.parentCategoryId,
  });

  bool get hasIconImage => iconUrl != null && iconUrl!.trim().isNotEmpty;

  bool get isShopCategory => source == CategorySource.shop;

  bool get isShopScoped => shopId != null && shopId!.isNotEmpty;

  String get filterId => productCategoryId ?? id;

  static const fallbackIcons = <IconData>[
    Icons.brush_outlined,
    Icons.grid_view_rounded,
    Icons.healing_outlined,
    Icons.medical_services_outlined,
    Icons.construction_outlined,
    Icons.water_drop_outlined,
  ];
  static const fallbackIconColors = <Color>[
    Color(0xFF26A69A),
    Color(0xFF00897B),
    Color(0xFF00796B),
    Color(0xFF00695C),
    Color(0xFF26A69A),
    Color(0xFF00897B),
  ];

  factory CategoryModel.fromShopCategory(
    ShopCategoryModel category, {
    int index = 0,
  }) {
    return CategoryModel(
      id: category.id,
      name: category.nameAr,
      iconUrl: category.iconUrl,
      icon: fallbackIcons[index % fallbackIcons.length],
      iconColor: fallbackIconColors[index % fallbackIconColors.length],
      source: category.isShopCategory
          ? CategorySource.shop
          : CategorySource.admin,
      shopId: category.shopId,
      productCategoryId: category.isShopCategory ? category.id : null,
      parentCategoryId: category.parentCategoryId,
    );
  }
}
