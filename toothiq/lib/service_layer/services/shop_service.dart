import '../../core/api/api_client.dart';
import '../../model/brand_model.dart';
import '../../model/paginated_result.dart';
import '../../model/product_model.dart';
import '../../model/shop_category_model.dart';
import '../../model/store_model.dart';
import '../../model/store_review_model.dart';

class ShopService {
  final ApiClient _api;

  ShopService(this._api);

  Future<List<StoreModel>> fetchShops({
    String? category,
    int page = 1,
    int limit = 20,
  }) {
    return _api.getShops(category: category, page: page, limit: limit);
  }

  /// بحث محلي في قائمة المتاجر (السيرفر لا يدعم q على /api/shops).
  Future<List<StoreModel>> searchStoresByQuery(
    String query, {
    int limit = 50,
  }) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return const [];

    final shops = await fetchShops(limit: limit);
    return shops
        .where(
          (store) =>
              store.name.toLowerCase().contains(normalized) ||
              store.description.toLowerCase().contains(normalized) ||
              store.address.toLowerCase().contains(normalized),
        )
        .toList(growable: false);
  }

  Future<StoreModel> getShopById(String shopId) {
    return _api.getShopById(shopId);
  }

  Future<ProductModel> fetchShopProduct({
    required String shopId,
    required String productId,
    required String shopName,
  }) {
    return _api.getShopProduct(
      shopId: shopId,
      productId: productId,
      shopName: shopName,
    );
  }

  Future<List<ProductModel>> fetchShopProducts({
    required String shopId,
    required String shopName,
  }) {
    return _api.getShopProducts(shopId: shopId, shopName: shopName);
  }

  Future<PaginatedResult<ProductModel>> fetchShopProductsPaginated({
    required String shopId,
    required String shopName,
    int page = 1,
    int limit = 20,
  }) {
    return _api.getShopProductsPaginated(
      shopId: shopId,
      shopName: shopName,
      page: page,
      limit: limit,
    );
  }

  Future<List<ShopCategoryModel>> fetchShopProductCategories(
    String shopId, {
    bool grouped = true,
  }) {
    return _api.getShopProductCategories(shopId, grouped: grouped);
  }

  Future<List<BrandModel>> fetchShopBrands({
    required List<String> categoryIds,
    List<ProductModel> products = const [],
    List<ShopCategoryModel> shopCategories = const [],
  }) async {
    final brandsById = <String, BrandModel>{};

    for (final brand in BrandModel.fromProducts(products)) {
      brandsById[brand.id] = brand;
    }

    for (final category in shopCategories) {
      for (final brand in category.brands) {
        brandsById[brand.id] = brand;
      }
    }

    if (categoryIds.isEmpty) return brandsById.values.toList(growable: false);

    final results = await Future.wait(
      categoryIds.map(_api.getCatalogBrands),
    );
    for (final list in results) {
      for (final brand in list) {
        brandsById[brand.id] = brand;
      }
    }

    return brandsById.values.toList(growable: false);
  }

  Future<List<StoreReviewModel>> fetchShopReviews(String shopId) {
    return _api.getShopReviews(shopId);
  }

  Future<void> submitShopReview({
    required String shopId,
    required int rating,
    required String comment,
  }) {
    return _api.submitShopReview(
      shopId: shopId,
      rating: rating,
      comment: comment,
    );
  }
}
