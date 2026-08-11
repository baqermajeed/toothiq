import 'user_role.dart';

class UserModel {
  final String id;
  final String name;
  final String phone;
  final String? roleRaw;
  final String? shopId;

  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    this.roleRaw,
    this.shopId,
  });

  AppUserRole? get partnerRole {
    final value = roleRaw?.trim().toLowerCase();
    switch (value) {
      case 'shop':
      case 'shop_owner':
      case 'shopowner':
      case 'store':
      case 'store_owner':
        return AppUserRole.shop;
      case 'driver':
      case 'delivery':
      case 'delivery_driver':
      case 'courier':
        return AppUserRole.driver;
      default:
        return null;
    }
  }

  bool matchesRole(AppUserRole selected) => partnerRole == selected;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    String? shop;
    final shopRef = json['shopId'] ?? json['shop'];
    if (shopRef is Map<String, dynamic>) {
      shop = shopRef['_id']?.toString() ?? shopRef['id']?.toString();
    } else {
      shop = shopRef?.toString();
    }

    return UserModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      roleRaw: json['role']?.toString() ?? json['userType']?.toString(),
      shopId: shop?.trim().isEmpty == true ? null : shop,
    );
  }
}
