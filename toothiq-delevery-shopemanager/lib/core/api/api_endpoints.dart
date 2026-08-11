class ApiEndpoints {
  // Auth
  static const String login = '/api/auth/login';
  static const String refresh = '/api/auth/refresh';
  static const String logout = '/api/auth/logout';
  static const String currentUser = '/api/users/me';

  // Shops & products
  static const String shops = '/api/shops';
  static const String brands = '/api/brands';
  static const String catalogCategories = '/api/catalog/categories';
  static String shop(String id) => '/api/shops/$id';
  static String shopProducts(String shopId) => '/api/shops/$shopId/products';
  static String shopProduct(String shopId, String id) =>
      '/api/shops/$shopId/products/$id';
  static String shopProductCategories(String shopId) =>
      '/api/shops/$shopId/product-categories';
  static String shopProductCategory(String shopId, String categoryId) =>
      '/api/shops/$shopId/product-categories/$categoryId';

  // Orders (role-scoped by token)
  static const String orders = '/api/orders';
  static String order(String id) => '/api/orders/$id';
  static String orderStatus(String id) => '/api/orders/$id/status';
}
