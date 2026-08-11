class StorageKeys {
  static const String onboardingCompleted = 'onboarding_completed';
  static const String profileName = 'profile_name';
  static const String profilePhone = 'profile_phone';
  static const String profileAltPhone = 'profile_alt_phone';
  static const String profileAddress = 'profile_address';
  static const String savedAddresses = 'saved_addresses';
  static const String searchHistory = 'search_history';
  static const String notificationsEnabled = 'notifications_enabled';
  static const String notificationInbox = 'notification_inbox';

  static String storeAbout(String storeId) => 'store_about_$storeId';
}
