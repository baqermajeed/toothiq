import '../../core/api/api_client.dart';
import '../../model/brand_model.dart';
import '../../model/product_model.dart';

class BrandService {
  final ApiClient _api;

  BrandService(this._api);

  Future<List<BrandModel>> fetchBrandsByCategory(String categoryId) {
    return _api.getCatalogBrands(categoryId);
  }

  Future<List<BrandModel>> fetchAllBrands() {
    return _api.getBrands();
  }

  List<BrandModel> brandsFromProducts(Iterable<ProductModel> products) {
    return BrandModel.fromProducts(products);
  }
}
