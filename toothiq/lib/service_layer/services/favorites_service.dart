import 'package:get/get.dart';

import '../../controller/brand_products_controller.dart';
import '../../controller/home_controller.dart';
import '../../controller/section_detail_controller.dart';
import '../../controller/store_detail_controller.dart';
import '../../model/product_model.dart';
import '../../utils/storage_keys.dart';
import 'preferences_storage.dart';

class FavoritesService extends GetxService {
  FavoritesService(this._prefs);

  static const String _guestScope = '__guest__';

  final PreferencesStorage _prefs;
  final favoriteProducts = <ProductModel>[].obs;
  final _favoriteIds = <String>{};
  String? _userId;

  Future<void> bindToUser(String? userId) async {
    _userId = userId?.trim().isEmpty == true ? null : userId?.trim();
    _favoriteIds.clear();
    favoriteProducts.clear();

    final raw = _loadFavoritesForScope();
    if (raw == null || raw.isEmpty) return;

    final loaded = <ProductModel>[];
    for (final item in raw) {
      final product = ProductModel.fromFavoriteJson(item);
      if (product.id.isEmpty) continue;
      _favoriteIds.add(product.id);
      loaded.add(product);
    }
    favoriteProducts.assignAll(loaded);
  }

  bool isFavorite(String productId) => _favoriteIds.contains(productId);

  List<ProductModel> applyFavoriteState(List<ProductModel> products) {
    return products
        .map(
          (product) => product.copyWith(isFavorite: isFavorite(product.id)),
        )
        .toList(growable: false);
  }

  Future<bool> toggle(ProductModel product) async {
    final productId = product.id.trim();
    if (productId.isEmpty) return false;

    final nowFavorite = !isFavorite(productId);
    if (nowFavorite) {
      _favoriteIds.add(productId);
      final existingIndex = favoriteProducts.indexWhere((p) => p.id == productId);
      final stored = product.copyWith(isFavorite: true);
      if (existingIndex == -1) {
        favoriteProducts.add(stored);
      } else {
        favoriteProducts[existingIndex] = stored;
      }
    } else {
      _favoriteIds.remove(productId);
      favoriteProducts.removeWhere((p) => p.id == productId);
    }

    favoriteProducts.refresh();
    await _persist();
    _propagateFavoriteState(productId, nowFavorite);
    return nowFavorite;
  }

  void _propagateFavoriteState(String productId, bool isFavorite) {
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().updateFavoriteState(productId, isFavorite);
    }
    if (Get.isRegistered<StoreDetailController>()) {
      Get.find<StoreDetailController>().updateFavoriteState(
        productId,
        isFavorite,
      );
    }
    if (Get.isRegistered<SectionDetailController>()) {
      Get.find<SectionDetailController>().updateFavoriteState(
        productId,
        isFavorite,
      );
    }
    if (Get.isRegistered<BrandProductsController>()) {
      Get.find<BrandProductsController>().updateFavoriteState(
        productId,
        isFavorite,
      );
    }
  }

  Future<void> _persist() async {
    final scope = _currentScope;
    await _prefs.setJsonList(
      StorageKeys.favoriteProductsFor(scope),
      favoriteProducts.map((product) => product.toFavoriteJson()).toList(),
    );

    // توافق رجعي مع الإصدارات القديمة التي استخدمت مفتاحاً عاماً للمفضلات.
    if (_userId == null) {
      await _prefs.setJsonList(
        StorageKeys.favoriteProducts,
        favoriteProducts.map((product) => product.toFavoriteJson()).toList(),
      );
    }
  }

  String get _currentScope => _userId ?? _guestScope;

  List<Map<String, dynamic>>? _loadFavoritesForScope() {
    final scoped = _prefs.getJsonList(
      StorageKeys.favoriteProductsFor(_currentScope),
    );

    if (_userId == null && (scoped == null || scoped.isEmpty)) {
      return _prefs.getJsonList(StorageKeys.favoriteProducts);
    }

    return scoped;
  }
}
