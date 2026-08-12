class ApiEndpoints {
  // Auth
  static const String register = '/api/auth/register';
  static const String login = '/api/auth/login';
  static const String guestRegister = '/api/auth/guest-register';
  static const String refresh = '/api/auth/refresh';
  static const String logout = '/api/auth/logout';

  // Users
  static const String currentUser = '/api/users/me';

  // Public
  static const String governorates = '/api/governorates';
  static const String banners = '/api/banners';
  static const String categories = '/api/categories';
  static const String catalogCategories = '/api/catalog/categories';
  static const String shops = '/api/shops';
  static const String products = '/api/products';
  static const String brands = '/api/brands';
  static const String productSearch = '/api/products/search';
  static const String randomProducts = '/api/products/random-multi-shops';
  static const String appVersion = '/api/app-version';
  static const String appContact = '/api/app-contact';

  // Orders
  static const String orders = '/api/orders';

  // Notifications
  static const String notifications = '/api/notifications';
  static const String notificationsReadAll = '/api/notifications/read-all';
  static const String notificationsUnreadCount =
      '/api/notifications/unread-count';

  static String catalogCategory(String id) => '/api/catalog/categories/$id';
  static String catalogCategorySubcategories(String id) =>
      '/api/catalog/categories/$id/subcategories';
  static String catalogCategoryBrands(String id) =>
      '/api/catalog/categories/$id/brands';

  static String shop(String id) => '/api/shops/$id';
  static String shopReviews(String id) => '/api/shops/$id/reviews';
  static String shopProducts(String shopId) => '/api/shops/$shopId/products';
  static String shopProductCategories(String shopId) =>
      '/api/shops/$shopId/product-categories';
  static String shopProduct(String shopId, String id) =>
      '/api/shops/$shopId/products/$id';
  static String order(String id) => '/api/orders/$id';
  static String notificationRead(String id) =>
      '/api/notifications/$id/read';
}
