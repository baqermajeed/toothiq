import '../../core/api/api_client.dart';
import '../../model/banner_model.dart';

class BannerService {
  final ApiClient _api;

  BannerService(this._api);

  Future<List<BannerModel>> fetchActiveBanners() {
    return _api.getBanners();
  }
}
