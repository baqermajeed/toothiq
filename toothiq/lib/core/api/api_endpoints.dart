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
  static const String shops = '/api/shops';
  static const String products = '/api/products';
  static const String brands = '/api/brands';
  static const String productSearch = '/api/products/search';
  static const String randomProducts = '/api/products/random-multi-shops';
  static const String appVersion = '/api/app-version';

  // Orders
  static const String orders = '/api/orders';

  static String shop(String id) => '/api/shops/$id';
  static String shopReviews(String id) => '/api/shops/$id/reviews';
  static String shopProducts(String shopId) => '/api/shops/$shopId/products';
  static String shopProductCategories(String shopId) =>
      '/api/shops/$shopId/product-categories';
  static String shopProduct(String shopId, String id) =>
      '/api/shops/$shopId/products/$id';
  static String order(String id) => '/api/orders/$id';
}
