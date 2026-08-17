import '../../core/api/api_client.dart';
import '../../model/partner_order.dart';

class OrderService {
  OrderService(this._api);

  final ApiClient _api;

  Future<List<PartnerOrder>> fetchOrders({String? status}) {
    return _api.getOrders(status: status);
  }

  Future<PartnerOrder> fetchOrder(String orderId) {
    return _api.getOrderById(orderId);
  }

  Future<PartnerOrder> updateStatus({
    required String orderId,
    required String status,
  }) {
    return _api.updateOrderStatus(orderId: orderId, status: status);
  }

  Future<List<PartnerOrder>> fetchDriverOrders({required String tab}) {
    return _api.getDriverOrders(tab: tab);
  }

  Future<PartnerOrder> fetchDriverOrder(String orderId) {
    return _api.getDriverOrderById(orderId);
  }

  Future<PartnerOrder> acceptDriverOrder(String orderId) {
    return _api.acceptDriverOrder(orderId);
  }

  Future<PartnerOrder> updateDriverStatus({
    required String orderId,
    required String status,
  }) {
    return _api.updateDriverOrderStatus(orderId: orderId, status: status);
  }
}
