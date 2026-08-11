import '../../core/api/api_client.dart';
import '../../model/paginated_result.dart';
import '../../model/product_model.dart';

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
    String? brandId,
  }) {
    return _api.getProducts(
      page: page,
      limit: limit,
      productCategoryId: productCategoryId,
      brandId: brandId,
    );
  }

  Future<PaginatedResult<ProductModel>> searchProductsPaginated(
    String query, {
    int page = 1,
    int limit = 12,
  }) {
    return _api.searchProducts(query, page: page, limit: limit);
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
