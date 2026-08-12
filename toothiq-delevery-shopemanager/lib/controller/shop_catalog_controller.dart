import 'package:get/get.dart';

import '../core/constants/category_preset_icons.dart';
import '../bindings/app_binding.dart';
import '../controller/session_controller.dart';
import '../controller/shop_products_controller.dart';
import '../core/utils/image_url.dart';
import '../model/shop_brand.dart';
import '../model/shop_category.dart';
import '../service_layer/services/shop_service.dart';

class ShopCatalogController extends GetxController {
  ShopCatalogController({
    required ShopService shopService,
    required SessionController session,
  }) : _shopService = shopService,
       _session = session;

  final ShopService _shopService;
  final SessionController _session;

  /// كل أقسام الكتالوج — تُستخدم عند إضافة/تعديل المنتجات.
  final categories = <ShopCategory>[].obs;

  /// الأقسام المعروضة داخل متجر صاحب الحساب فقط.
  final shopCategories = <ShopCategory>[].obs;
  final brands = <ShopBrand>[].obs;
  final isSaving = false.obs;
  final isLoading = false.obs;
  final isLoadingShopCategories = false.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadCatalog();
  }

  Future<void> ensureLoaded() => loadCatalog(force: categories.isEmpty);

  Future<void> loadCatalog({bool force = false}) async {
    if (isLoading.value) return;
    if (!force && categories.isNotEmpty && brands.isNotEmpty) return;

    isLoading.value = true;
    errorMessage.value = '';
    try {
      final tree = await _shopService.fetchCatalogTree();
      final mergedCategories = <ShopCategory>[...tree.categories];
      final mergedBrands = <ShopBrand>[...tree.brands];
      final categoryIds = mergedCategories.map((c) => c.id).toSet();

      final shopId = _session.shopId.value;
      if (shopId.isNotEmpty) {
        try {
          final shopOnlyCategories = await _shopService.fetchCategories(shopId);
          for (final category in shopOnlyCategories) {
            if (categoryIds.add(category.id)) {
              mergedCategories.add(category);
            }
          }
        } catch (_) {}
      }

      categories.assignAll(mergedCategories.map(_resolveCategoryImage));
      brands.assignAll(mergedBrands.map(_resolveBrandLogo));

      if (categories.isEmpty && brands.isEmpty) {
        errorMessage.value = 'لا توجد أقسام أو براندات في الكتالوج';
      }

      await loadShopCategories(force: true);
    } catch (error) {
      errorMessage.value = apiErrorMessage(error);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadShopCategories({bool force = false}) async {
    final shopId = _session.shopId.value;
    if (shopId.isEmpty) {
      shopCategories.clear();
      return;
    }
    if (isLoadingShopCategories.value) return;
    if (!force && shopCategories.isNotEmpty) return;

    isLoadingShopCategories.value = true;
    try {
      final list = await _shopService.fetchCategories(shopId);
      shopCategories.assignAll(
        list.map(_resolveCategoryImage).map(_withProductCount),
      );
    } catch (error) {
      Get.snackbar('خطأ', apiErrorMessage(error));
    } finally {
      isLoadingShopCategories.value = false;
    }
  }

  Future<void> addCategory({
    required String nameAr,
    required String iconAssetPath,
  }) async {
    final shopId = _session.shopId.value;
    if (shopId.isEmpty) return;
    if (!CategoryPresetIcons.isAssetPath(iconAssetPath)) {
      Get.snackbar('تنبيه', 'اختر أيقونة للقسم');
      return;
    }

    isSaving.value = true;
    try {
      final created = await _shopService.createCategory(
        shopId: shopId,
        nameAr: nameAr,
        imagePath: iconAssetPath,
      );
      shopCategories.add(_withProductCount(_resolveCategoryImage(created)));
      Get.snackbar('تمت الإضافة', 'تم إضافة القسم المخصص لمتجرك');
    } catch (error) {
      Get.snackbar('خطأ', apiErrorMessage(error));
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> addAdminCategory(String parentCategoryId) async {
    final shopId = _session.shopId.value;
    if (shopId.isEmpty) return;

    isSaving.value = true;
    try {
      final created = await _shopService.addAdminCategory(
        shopId: shopId,
        parentCategoryId: parentCategoryId,
      );
      shopCategories.add(_withProductCount(_resolveCategoryImage(created)));
      Get.snackbar('تمت الإضافة', 'تم إضافة القسم من أقسام الإدارة لمتجرك');
    } catch (error) {
      Get.snackbar('خطأ', apiErrorMessage(error));
    } finally {
      isSaving.value = false;
    }
  }

  /// أقسام الإدارة التي لم يُضفها المتجر بعد.
  List<ShopCategory> get availableAdminCategories {
    final linkedParentIds = shopCategories
        .map((c) => c.parentCategoryId)
        .whereType<String>()
        .toSet();
    return categories
        .where((c) => !linkedParentIds.contains(c.id))
        .toList(growable: false);
  }

  Future<void> updateCategory(
    ShopCategory category, {
    String? iconAssetPath,
  }) async {
    final shopId = _session.shopId.value;
    if (shopId.isEmpty) return;
    if (category.isAdminLinked) {
      Get.snackbar('تنبيه', 'لا يمكن تعديل اسم قسم مرتبط بقسم الإدارة');
      return;
    }
    isSaving.value = true;
    try {
      final updated = await _shopService.updateCategoryInShop(
        shopId: shopId,
        categoryId: category.id,
        nameAr: category.nameAr,
        imagePath: iconAssetPath ?? category.imagePath,
      );
      final index = shopCategories.indexWhere((c) => c.id == category.id);
      if (index >= 0) {
        shopCategories[index] = _withProductCount(_resolveCategoryImage(updated));
      }
      Get.snackbar('تم الحفظ', 'تم تحديث القسم بنجاح');
    } catch (error) {
      Get.snackbar('خطأ', apiErrorMessage(error));
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> removeCategory(String id) async {
    final shopId = _session.shopId.value;
    if (shopId.isEmpty) return;

    isSaving.value = true;
    try {
      await _shopService.removeCategoryFromShop(
        shopId: shopId,
        categoryId: id,
      );
      shopCategories.removeWhere((category) => category.id == id);
      Get.snackbar(
        'تمت الإزالة',
        'تم إخفاء القسم من متجرك ويبقى متاحاً لمتاجر أخرى',
      );
    } catch (error) {
      Get.snackbar('خطأ', apiErrorMessage(error));
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> addBrand({required String nameAr, String? logoPath}) async {
    Get.snackbar('غير متاح', 'إضافة البراندات تتم من لوحة التحكم');
  }

  Future<void> updateBrand(ShopBrand brand) async {
    Get.snackbar('غير متاح', 'تعديل البراندات من التطبيق قيد التطوير');
  }

  void removeBrand(String id) {
    Get.snackbar('غير متاح', 'حذف البراندات من التطبيق قيد التطوير');
  }

  ShopCategory? categoryById(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final category in categories) {
      if (category.id == id) return category;
    }
    for (final category in shopCategories) {
      if (category.id == id) return category;
    }
    return null;
  }

  ShopBrand? brandById(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final brand in brands) {
      if (brand.id == id) return brand;
    }
    return null;
  }

  ShopCategory _resolveCategoryImage(ShopCategory category) {
    final image = category.imagePath;
    if (image == null || image.isEmpty || ImageUrl.isLocalFile(image)) {
      return category;
    }
    return category.copyWith(imagePath: ImageUrl.resolve(image));
  }

  ShopBrand _resolveBrandLogo(ShopBrand brand) {
    final logo = brand.logoPath;
    if (logo == null || logo.isEmpty || ImageUrl.isLocalFile(logo)) {
      return brand;
    }
    return brand.copyWith(logoPath: ImageUrl.resolve(logo));
  }

  ShopCategory _withProductCount(ShopCategory category) {
    if (category.productCount > 0) return category;
    if (!Get.isRegistered<ShopProductsController>()) return category;

    final count = Get.find<ShopProductsController>()
        .products
        .where((product) => product.categoryId == category.id)
        .length;
    if (count == 0) return category;
    return category.copyWith(productCount: count);
  }
}
