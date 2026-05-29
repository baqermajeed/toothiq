import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../model/category_model.dart';
import '../view/section/section_detail_page.dart';

class CategoriesController extends GetxController {
  final searchController = TextEditingController();

  final allCategories = <CategoryModel>[
    const CategoryModel(
      id: 'whitening',
      name: 'تبييض',
      icon: Icons.brush_outlined,
      iconColor: Color(0xFF26A69A),
    ),
    const CategoryModel(
      id: 'orthodontics',
      name: 'تقويم',
      icon: Icons.grid_view_rounded,
      iconColor: Color(0xFF00897B),
    ),
    const CategoryModel(
      id: 'fillings',
      name: 'حشوات',
      icon: Icons.healing_outlined,
      iconColor: Color(0xFF00796B),
    ),
    const CategoryModel(
      id: 'surgery',
      name: 'جراحة',
      icon: Icons.medical_services_outlined,
      iconColor: Color(0xFF00695C),
    ),
    const CategoryModel(
      id: 'implants',
      name: 'زراعة الأسنان',
      icon: Icons.construction_outlined,
      iconColor: Color(0xFF26A69A),
    ),
    const CategoryModel(
      id: 'cleaning',
      name: 'تنظيف',
      icon: Icons.water_drop_outlined,
      iconColor: Color(0xFF00897B),
    ),
  ];

  late final List<CategoryModel> gridCategories;

  final filteredCategories = <CategoryModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    gridCategories = [
      ...allCategories,
      ...allCategories,
    ];
    filteredCategories.assignAll(gridCategories);
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
      filteredCategories.assignAll(gridCategories);
      return;
    }
    filteredCategories.assignAll(
      gridCategories
          .where((c) => c.name.contains(query))
          .toList(),
    );
  }

  void onCategoryTap(CategoryModel category) {
    SectionDetailPage.open(category);
  }
}
