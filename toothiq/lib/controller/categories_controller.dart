import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/api/api_exception.dart';
import '../model/category_model.dart';
import '../model/shop_category_model.dart';
import '../service_layer/services/category_service.dart';
import '../view/section/section_detail_page.dart';

class CategoriesController extends GetxController {
  final CategoryService _categoryService = Get.find<CategoryService>();

  final searchController = TextEditingController();
  final allCategories = <CategoryModel>[].obs;
  final filteredCategories = <CategoryModel>[].obs;
  final isLoading = false.obs;
  final loadError = RxnString();

  static const _icons = <IconData>[
    Icons.brush_outlined,
    Icons.grid_view_rounded,
    Icons.healing_outlined,
    Icons.medical_services_outlined,
    Icons.construction_outlined,
    Icons.water_drop_outlined,
  ];
  static const _iconColors = <Color>[
    Color(0xFF26A69A),
    Color(0xFF00897B),
    Color(0xFF00796B),
    Color(0xFF00695C),
    Color(0xFF26A69A),
    Color(0xFF00897B),
  ];

  @override
  void onInit() {
    super.onInit();
    loadCategories();
    searchController.addListener(_onSearchChanged);
  }

  @override
  void onClose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.onClose();
  }

  void _onSearchChanged() {
    final query = searchController.text.trim();
    if (query.isEmpty) {
      filteredCategories.assignAll(allCategories);
      return;
    }
    filteredCategories.assignAll(
      allCategories.where((c) => c.name.contains(query)).toList(),
    );
  }

  Future<void> loadCategories() async {
    isLoading.value = true;
    loadError.value = null;
    try {
      final data = await _categoryService.fetchCategories();
      final mapped = _toCategoryCards(data);
      allCategories.assignAll(mapped);
      filteredCategories.assignAll(mapped);
    } on ApiException catch (error) {
      loadError.value = error.message;
      allCategories.clear();
      filteredCategories.clear();
    } catch (_) {
      loadError.value = 'تعذر تحميل الأقسام';
      allCategories.clear();
      filteredCategories.clear();
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Future<void> refresh() async {
    await loadCategories();
  }

  List<CategoryModel> _toCategoryCards(List<ShopCategoryModel> data) {
    return data
        .asMap()
        .entries
        .map((entry) {
          final index = entry.key;
          final category = entry.value;
          return CategoryModel(
            id: category.id,
            name: category.nameAr,
            iconUrl: category.iconUrl,
            icon: _icons[index % _icons.length],
            iconColor: _iconColors[index % _iconColors.length],
            source: category.isShopCategory
                ? CategorySource.shop
                : CategorySource.admin,
            shopId: category.shopId,
            productCategoryId:
                category.isShopCategory ? category.id : null,
          );
        })
        .toList(growable: false);
  }

  void onCategoryTap(CategoryModel category) {
    SectionDetailPage.open(category);
  }
}