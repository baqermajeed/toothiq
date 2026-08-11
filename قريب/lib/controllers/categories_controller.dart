import 'package:get/get.dart';

import 'app_location_controller.dart';
import 'auth_controller.dart';
import '../models/shop.dart';

/// عنصر تصنيف للعرض (من API أو "الكل").
class CategoryItem {
  const CategoryItem({required this.id, required this.name, required this.icon});
  final String id;
  final String name;
  final String icon;
}

/// تحكم صفحة التصنيفات: يجلب التصنيفات والمحلات من الـ API.
class CategoriesController extends GetxController {
  final RxList<Shop> shops = <Shop>[].obs;
  final RxBool loading = true.obs;
  final Rxn<String> error = Rxn<String>();
  final RxInt selectedCategoryIndex = 0.obs;

  /// التصنيفات المعروضة: "الكل" أولاً ثم التصنيفات من API.
  final RxList<CategoryItem> categories = <CategoryItem>[
    const CategoryItem(id: 'all', name: 'الكل', icon: '📋'),
  ].obs;

  /// قائمة المحلات الحالية (تُجلب من الـ API حسب التصنيف المختار).
  List<Shop> get displayedShops => shops;

  @override
  void onInit() {
    super.onInit();
    loadCategories();
    loadShopsBySelectedCategory();
  }

  Future<void> loadCategories() async {
    try {
      final auth = Get.find<AuthController>();
      final apiClient = auth.apiClient;
      final raw = await apiClient.getCategories();
      final items = <CategoryItem>[
        const CategoryItem(id: 'all', name: 'الكل', icon: '📋'),
      ];
      for (final e in raw) {
        final nameAr = e['nameAr'] as String? ?? '';
        if (nameAr.isEmpty) continue;
        final id = e['id'] as String? ?? nameAr;
        final icon = e['icon'] as String? ?? '📋';
        items.add(CategoryItem(id: id, name: nameAr, icon: icon));
      }
      categories.assignAll(items);
    } catch (_) {
      // إبقاء "الكل" فقط عند فشل جلب التصنيفات
      categories.assignAll([const CategoryItem(id: 'all', name: 'الكل', icon: '📋')]);
    }
  }

  /// جلب المحلات من الـ API حسب التصنيف المختار (بدون فلترة محلية).
  Future<void> loadShopsBySelectedCategory() async {
    loading.value = true;
    error.value = null;
    String? category;
    if (selectedCategoryIndex.value > 0 &&
        selectedCategoryIndex.value < categories.length) {
      category = categories[selectedCategoryIndex.value].name;
    }
    try {
      final auth = Get.find<AuthController>();
      final apiClient = auth.apiClient;
      double? lng;
      double? lat;
      final user = auth.user.value;
      if (user?.location is Map<String, dynamic>) {
        final loc = user!.location as Map<String, dynamic>;
        final coords = loc['coordinates'];
        if (coords is List && coords.length >= 2) {
          lng = (coords[0] as num).toDouble();
          lat = (coords[1] as num).toDouble();
        }
      }
      if (lng == null || lat == null) {
        final appLoc = Get.find<AppLocationController>();
        if (appLoc.hasLocation) {
          lng = appLoc.lng;
          lat = appLoc.lat;
        }
      }
      final list = await apiClient.getShops(
        lng: lng,
        lat: lat,
        category: category,
      );
      shops.value = list;
    } catch (e) {
      error.value = e.toString().replaceFirst('ApiException', '').trim();
      if (error.value?.isEmpty ?? true) error.value = 'فشل تحميل المحلات';
      shops.clear();
    } finally {
      loading.value = false;
    }
  }

  /// عند النقر على تصنيف: تحديث الاختيار ثم طلب المحلات من الـ API.
  void selectCategory(int index) {
    if (selectedCategoryIndex.value == index) return;
    selectedCategoryIndex.value = index;
    loadShopsBySelectedCategory();
  }
}
