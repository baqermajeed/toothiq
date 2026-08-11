import 'package:get/get.dart';

import '../../controller/cart_controller.dart';
import '../../controller/saved_addresses_controller.dart';
import '../../controller/settings_controller.dart';
import '../../model/user_model.dart';
import '../../utils/storage_keys.dart';
import 'favorites_service.dart';
import 'preferences_storage.dart';
import 'section_detail_cache_service.dart';

/// تنسيق بيانات المستخدم بين الجلسات — مثل قريب: لا تُعرض بيانات حساب على آخر.
class UserSessionService {
  UserSessionService._();

  static Future<void> onSignedIn(UserModel user) async {
    if (user.id.trim().isEmpty) return;

    await _removeLegacyGlobalUserKeys();

    if (Get.isRegistered<SettingsController>()) {
      await Get.find<SettingsController>().bindToUser(user);
    }
    if (Get.isRegistered<FavoritesService>()) {
      await Get.find<FavoritesService>().bindToUser(user.id);
    }
    if (Get.isRegistered<SavedAddressesController>()) {
      await Get.find<SavedAddressesController>().bindToUser(user.id);
    }
    if (Get.isRegistered<CartController>()) {
      await Get.find<CartController>().bindToUser(user.id);
    }
  }

  static Future<void> onSignedOut() async {
    if (Get.isRegistered<CartController>()) {
      await Get.find<CartController>().bindToUser(null);
    }
    if (Get.isRegistered<SettingsController>()) {
      await Get.find<SettingsController>().bindToUser(null);
    }
    if (Get.isRegistered<FavoritesService>()) {
      await Get.find<FavoritesService>().bindToUser(null);
    }
    if (Get.isRegistered<SavedAddressesController>()) {
      await Get.find<SavedAddressesController>().bindToUser(null);
    }
    if (Get.isRegistered<SectionDetailCacheService>()) {
      Get.find<SectionDetailCacheService>().clear();
    }

    await _removeLegacyGlobalUserKeys();
  }

  static Future<void> _removeLegacyGlobalUserKeys() async {
    final prefs = PreferencesStorage.instance;
    for (final key in StorageKeys.legacyUserDataKeys) {
      await prefs.remove(key);
    }
  }
}
