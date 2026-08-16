import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../model/paginated_result.dart';
import '../../model/product_model.dart';
import '../../model/search_filter_options_model.dart';

class ProductService {
  final ApiClient _api;

  ProductService(this._api);

  Future<List<ProductModel>> fetchRandomProducts({
    String? productCategoryId,
    int shopCount = 6,
    int perShop = 2,
  }) {
    return _api.getRandomProducts(
      productCategoryId: productCategoryId,
      shopCount: shopCount,
      perShop: perShop,
    );
  }

  Future<PaginatedResult<ProductModel>> fetchProductsPaginated({
    int page = 1,
    int limit = 12,
    String? productCategoryId,
    String? categoryId,
    String? brandId,
    bool hasOffer = false,
  }) {
    return _api.getProducts(
      page: page,
      limit: limit,
      productCategoryId: productCategoryId,
      categoryId: categoryId,
      brandId: brandId,
      hasOffer: hasOffer,
    );
  }

  Future<PaginatedResult<ProductModel>> searchProductsPaginated(
    String query, {
    int page = 1,
    int limit = 12,
  }) {
    return _api.searchProducts(query, page: page, limit: limit);
  }

  Future<PaginatedResult<ProductModel>> fetchHomeAll({
    int page = 1,
    int limit = 12,
  }) {
    return _api.getProductFeed(ApiEndpoints.productAll, page: page, limit: limit);
  }

  Future<PaginatedResult<ProductModel>> fetchOffers({
    int page = 1,
    int limit = 12,
  }) {
    return _api.getProductFeed(ApiEndpoints.productOffers, page: page, limit: limit);
  }

  Future<PaginatedResult<ProductModel>> fetchBestSellers({
    int page = 1,
    int limit = 12,
  }) {
    return _api.getProductFeed(
      ApiEndpoints.productBestSellers,
      page: page,
      limit: limit,
    );
  }

  Future<PaginatedResult<ProductModel>> fetchForYou({
    int page = 1,
    int limit = 12,
  }) {
    return _api.getProductFeed(ApiEndpoints.productForYou, page: page, limit: limit);
  }

  Future<PaginatedResult<ProductModel>> fetchNewProducts({
    int page = 1,
    int limit = 12,
  }) {
    return _api.getProductFeed(ApiEndpoints.productNew, page: page, limit: limit);
  }

  /// أقل وأعلى سعر بين كل المنتجات المتاحة في التطبيق.
  Future<({double min, double max})> fetchPriceBounds({
    int pageSize = 100,
  }) async {
    double? min;
    double? max;
    var page = 1;

    while (true) {
      final result = await fetchProductsPaginated(page: page, limit: pageSize);
      for (final product in result.items) {
        final price = product.sellingPrice.toDouble();
        min = min == null ? price : (price < min ? price : min);
        max = max == null ? price : (price > max ? price : max);
      }
      if (!result.hasNextPage) break;
      page++;
    }

    return (
      min: (min ?? SearchFilterOptionsModel.fallbackMinPrice).toDouble(),
      max: (max ?? SearchFilterOptionsModel.fallbackMaxPrice).toDouble(),
    );
  }

  List<ProductModel> filterByCategoryId(
    List<ProductModel> items,
    String? categoryId,
  ) {
    if (categoryId == null || categoryId.isEmpty) return items;
    return items
        .where((product) => product.productCategoryId == categoryId)
        .toList(growable: false);
  }
}
