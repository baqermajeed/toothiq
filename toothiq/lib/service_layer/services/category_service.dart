import '../../core/api/api_client.dart';
import '../../model/shop_category_model.dart';

class CategoryService {
  final ApiClient _api;

  CategoryService(this._api);

  Future<List<ShopCategoryModel>> fetchCategories() {
    return _api.getCategories();
  }
}
