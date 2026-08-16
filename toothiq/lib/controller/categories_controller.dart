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
      mapped.sort(_comparePublicCategories);
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
        .map(
          (entry) => CategoryModel.fromShopCategory(
            entry.value,
            index: entry.key,
          ),
        )
        .toList(growable: false);
  }

  int _comparePublicCategories(CategoryModel a, CategoryModel b) {
    if (a.source != b.source) {
      return a.source == CategorySource.admin ? -1 : 1;
    }
    return a.name.compareTo(b.name);
  }

  void onCategoryTap(CategoryModel category) {
    SectionDetailPage.open(
      category,
      shopId: category.shopId,
    );
  }
}