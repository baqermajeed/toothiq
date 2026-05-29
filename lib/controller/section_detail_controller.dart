import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../model/brand_model.dart';
import '../model/category_model.dart';
import '../model/product_model.dart';
import 'home_controller.dart';

class SectionDetailController extends GetxController {
  final CategoryModel category;

  SectionDetailController({required this.category});

  final brandSearchController = TextEditingController();
  final selectedTabIndex = 0.obs;

  static const List<String> tabs = [
    'كل المنتجات',
    'البراندات',
    'أدوات التبييض',
  ];

  final brands = <BrandModel>[
    const BrandModel(id: 'b1', name: 'أسم البراند'),
    const BrandModel(id: 'b2', name: 'أسم البراند'),
    const BrandModel(id: 'b3', name: 'أسم البراند'),
    const BrandModel(id: 'b4', name: 'أسم البراند'),
    const BrandModel(id: 'b5', name: 'أسم البراند'),
    const BrandModel(id: 'b6', name: 'أسم البراند'),
    const BrandModel(id: 'b7', name: 'أسم البراند'),
    const BrandModel(id: 'b8', name: 'أسم البراند'),
    const BrandModel(id: 'b9', name: 'أسم البراند'),
    const BrandModel(id: 'b10', name: 'أسم البراند'),
    const BrandModel(id: 'b11', name: 'أسم البراند'),
    const BrandModel(id: 'b12', name: 'أسم البراند'),
    const BrandModel(id: 'b13', name: 'أسم البراند'),
    const BrandModel(id: 'b14', name: 'أسم البراند'),
    const BrandModel(id: 'b15', name: 'أسم البراند'),
  ];

  final filteredBrands = <BrandModel>[].obs;
  late final List<ProductModel> sectionProducts;
  late final List<ProductModel> whiteningProducts;

  @override
  void onInit() {
    super.onInit();
    filteredBrands.assignAll(brands);
    brandSearchController.addListener(_onBrandSearch);

    final home = Get.find<HomeController>();
    sectionProducts = List<ProductModel>.from(home.products);
    whiteningProducts = sectionProducts
        .where((p) => p.name.contains('فرشاة') || p.id == '1')
        .toList();
    if (whiteningProducts.isEmpty) {
      whiteningProducts = sectionProducts.take(2).toList();
    }
  }

  @override
  void onClose() {
    brandSearchController.removeListener(_onBrandSearch);
    brandSearchController.dispose();
    super.onClose();
  }

  void selectTab(int index) {
    selectedTabIndex.value = index;
  }

  void _onBrandSearch() {
    final query = brandSearchController.text.trim();
    if (query.isEmpty) {
      filteredBrands.assignAll(brands);
      return;
    }
    filteredBrands.assignAll(
      brands.where((b) => b.name.contains(query)).toList(),
    );
  }

}
