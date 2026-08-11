enum AppUserRole {
  shop('متجر', 'shop'),
  driver('مندوب توصيل', 'driver');

  final String label;
  final String apiValue;

  const AppUserRole(this.label, this.apiValue);

  static AppUserRole? fromStorage(String? value) {
    switch (value) {
      case 'shop':
        return AppUserRole.shop;
      case 'driver':
        return AppUserRole.driver;
      default:
        return null;
    }
  }
}
