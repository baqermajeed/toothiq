import '../../core/api/api_client.dart';
import '../../model/governorate_model.dart';

class GovernorateService {
  final ApiClient _api;

  GovernorateService(this._api);

  Future<List<GovernorateModel>> fetchGovernorates() {
    return _api.getGovernorates();
  }
}
