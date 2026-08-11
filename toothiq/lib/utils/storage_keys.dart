class StorageKeys {
  static const String onboardingCompleted = 'onboarding_completed';
  static const String profileName = 'profile_name';
  static const String profilePhone = 'profile_phone';
  static const String profileAltPhone = 'profile_alt_phone';
  static const String profileAddress = 'profile_address';
  static const String profileImagePath = 'profile_image_path';
  static const String savedAddresses = 'saved_addresses';
  static const String searchHistory = 'search_history';
  static const String notificationsEnabled = 'notifications_enabled';
  static const String notificationInbox = 'notification_inbox';
  static const String favoriteProducts = 'favorite_products';
  static const String cartItems = 'cart_items';

  static String favoriteProductsFor(String userId) =>
      'favorite_products_$userId';

  static String cartItemsFor(String userId) => 'cart_items_$userId';

  static String savedAddressesFor(String userId) => 'saved_addresses_$userId';

  static String profileImagePathFor(String userId) =>
      'profile_image_path_$userId';

  /// مفاتيح قديمة كانت مشتركة بين كل الحسابات على الجهاز.
  static const legacyUserDataKeys = [
    profileName,
    profilePhone,
    profileAltPhone,
    profileAddress,
    profileImagePath,
    savedAddresses,
    favoriteProducts,
    cartItems,
  ];

  static String storeAbout(String storeId) => 'store_about_$storeId';
}
