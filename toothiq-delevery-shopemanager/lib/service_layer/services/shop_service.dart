import '../../core/api/api_client.dart';
import '../../model/shop_brand.dart';
import '../../model/shop_category.dart';
import '../../model/shop_product.dart';
import '../../model/shop_profile.dart';
import '../../model/user_model.dart';

class ShopService {
  ShopService(this._api);

  final ApiClient _api;

  Future<String?> resolveShopId(UserModel user) {
    return _api.resolveShopIdForUser(user);
  }

  Future<ShopProfile> fetchProfile(String shopId) {
    return _api.getShop(shopId);
  }

  Future<ShopProfile> updateProfile({
    required String shopId,
    required String name,
    required String description,
    required String address,
    required String phonePrimary,
    String? phoneSecondary,
    String? logoPath,
  }) {
    return _api.updateShop(
      shopId: shopId,
      name: name,
      description: description,
      address: address,
      phonePrimary: phonePrimary,
      phoneSecondary: phoneSecondary,
      logoPath: logoPath,
    );
  }

  Future<List<ShopProduct>> fetchProducts(String shopId) {
    return _api.getShopProducts(shopId);
  }

  Future<ShopProduct> createProduct({
    required String shopId,
    required ShopProduct product,
    String? imagePath,
    List<String> galleryPaths = const [],
  }) {
    return _api.createShopProduct(
      shopId: shopId,
      product: product,
      imagePath: imagePath,
      galleryPaths: galleryPaths,
    );
  }

  Future<ShopProduct> updateProduct({
    required String shopId,
    required ShopProduct product,
    String? imagePath,
    List<String> galleryPaths = const [],
  }) {
    return _api.updateShopProduct(
      shopId: shopId,
      product: product,
      imagePath: imagePath,
      galleryPaths: galleryPaths,
    );
  }

  Future<void> deleteProduct({
    required String shopId,
    required String productId,
  }) {
    return _api.deleteShopProduct(shopId: shopId, productId: productId);
  }

  Future<ShopProduct> toggleAvailability({
    required String shopId,
    required String productId,
    required bool isAvailable,
  }) {
    return _api.setProductAvailability(
      shopId: shopId,
      productId: productId,
      isAvailable: isAvailable,
    );
  }

  Future<List<ShopCategory>> fetchCategories(String shopId) {
    return _api.getShopCategories(shopId);
  }

  Future<void> removeCategoryFromShop({
    required String shopId,
    required String categoryId,
  }) {
    return _api.removeShopCategory(shopId: shopId, categoryId: categoryId);
  }

  Future<ShopCategory> createCategory({
    required String shopId,
    required String nameAr,
    String? parentCategoryId,
    String? imagePath,
  }) {
    return _api.createShopCategory(
      shopId: shopId,
      nameAr: nameAr,
      parentCategoryId: parentCategoryId,
      imagePath: imagePath,
    );
  }

  Future<ShopCategory> addAdminCategory({
    required String shopId,
    required String parentCategoryId,
  }) {
    return _api.addAdminCategoryToShop(
      shopId: shopId,
      parentCategoryId: parentCategoryId,
    );
  }

  Future<ShopCategory> updateCategoryInShop({
    required String shopId,
    required String categoryId,
    String? nameAr,
    String? imagePath,
  }) {
    return _api.updateShopCategory(
      shopId: shopId,
      categoryId: categoryId,
      nameAr: nameAr,
      imagePath: imagePath,
    );
  }

  Future<({List<ShopCategory> categories, List<ShopBrand> brands})>
  fetchCatalogTree() {
    return _api.getCatalogTree();
  }

  Future<List<ShopCategory>> fetchCatalogCategories() {
    return _api.getCatalogCategories();
  }

  Future<List<ShopBrand>> fetchBrands({String? shopId}) {
    return _api.getBrands(shopId: shopId);
  }
}
