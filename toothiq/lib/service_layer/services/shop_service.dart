import '../../core/api/api_client.dart';
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

  Future<List<ShopCategoryModel>> fetchShopProductCategories(String shopId) {
    return _api.getShopProductCategories(shopId);
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
