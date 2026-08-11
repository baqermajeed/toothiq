import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../model/settings_menu_item.dart';
import '../model/user_model.dart';
import '../service_layer/services/app_data_refresh_service.dart';
import '../service_layer/services/preferences_storage.dart';
import '../service_layer/services/user_service.dart';
import '../utils/storage_keys.dart';
import '../view/auth/login_page.dart';
import '../widget/settings/settings_confirm_dialog.dart';
import '../service_layer/services/auth_service.dart';
import 'session_controller.dart';

class SettingsController extends GetxController {
  final PreferencesStorage _prefs = PreferencesStorage.instance;
  final UserService _userService = Get.find<UserService>();

  final userName = 'د. بهجة مصطفى'.obs;
  final userPhone = '0770 000 000'.obs;
  final userAltPhone = ''.obs;
  final userAddress = 'العيادة ، بابل ، شارع 40'.obs;
  final notificationsEnabled = true.obs;
  final isSyncingProfile = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadProfileFromPreferences();
    syncProfileFromApi();
  }

  void _loadProfileFromPreferences() {
    final name = _prefs.getString(StorageKeys.profileName);
    final phone = _prefs.getString(StorageKeys.profilePhone);
    final altPhone = _prefs.getString(StorageKeys.profileAltPhone);
    final address = _prefs.getString(StorageKeys.profileAddress);
    final notifications = _prefs.getBool(StorageKeys.notificationsEnabled);

    if ((name ?? '').isNotEmpty) userName.value = name!;
    if ((phone ?? '').isNotEmpty) userPhone.value = phone!;
    if (altPhone != null) userAltPhone.value = altPhone;
    if ((address ?? '').isNotEmpty) userAddress.value = address!;
    if (notifications != null) notificationsEnabled.value = notifications;
  }

  void applyUserFromSession(UserModel user) {
    final clinic = (user.clinicName ?? '').trim();
    final location = user.governorateId.trim();
    final address = clinic.isNotEmpty
        ? '$clinic ، $location'
        : (location.isNotEmpty ? location : userAddress.value);

    userName.value = user.name;
    userPhone.value = user.phone;
    userAddress.value = address;

    _prefs.setString(StorageKeys.profileName, user.name);
    _prefs.setString(StorageKeys.profilePhone, user.phone);
    _prefs.setString(StorageKeys.profileAddress, address);
  }

  Future<void> saveProfile({
    String? name,
    String? phone,
    String? altPhone,
    String? address,
  }) async {
    if (name != null && name.trim().isNotEmpty) {
      userName.value = name.trim();
      await _prefs.setString(StorageKeys.profileName, userName.value);
    }
    if (phone != null && phone.trim().isNotEmpty) {
      userPhone.value = phone.trim();
      await _prefs.setString(StorageKeys.profilePhone, userPhone.value);
    }
    if (altPhone != null) {
      userAltPhone.value = altPhone.trim();
      await _prefs.setString(StorageKeys.profileAltPhone, userAltPhone.value);
    }
    if (address != null && address.trim().isNotEmpty) {
      userAddress.value = address.trim();
      await _prefs.setString(StorageKeys.profileAddress, userAddress.value);
    }
  }

  Future<void> syncProfileFromApi() async {
    if (!(Get.find<SessionController>().isAuthenticated)) return;

    isSyncingProfile.value = true;
    try {
      final user = await _userService.getCurrentUser();
      await _saveUserModelLocally(user);
    } catch (_) {
      // يحتفظ التطبيق بالبيانات المحلية الحالية عند فشل المزامنة.
    } finally {
      isSyncingProfile.value = false;
    }
  }

  Future<void> updateProfileOnApi({
    required String name,
    required String phone,
    required String clinicName,
  }) async {
    final user = await _userService.updateCurrentUser(
      name: name,
      phone: phone,
      clinicName: clinicName,
    );
    await _saveUserModelLocally(user);
    if (Get.isRegistered<SessionController>()) {
      Get.find<SessionController>().user.value = user;
    }
    await AppDataRefreshService.refreshAfterProfileUpdate();
  }

  Future<void> _saveUserModelLocally(UserModel user) async {
    final clinic = (user.clinicName ?? '').trim();
    final location = user.governorateId.trim();
    final address = clinic.isNotEmpty
        ? '$clinic ، $location'
        : (location.isNotEmpty ? location : userAddress.value);

    await saveProfile(name: user.name, phone: user.phone, address: address);
  }

  String get displayNameForForms {
    final name = userName.value.trim();
    if (name.startsWith('د. ')) return name.substring(3);
    if (name.startsWith('د.')) return name.substring(2).trim();
    return name;
  }

  bool get hasProfileInfo =>
      userName.value.trim().isNotEmpty ||
      userPhone.value.trim().isNotEmpty ||
      userAddress.value.trim().isNotEmpty;

  static final List<SettingsSection> settingsSections = [
    SettingsSection(
      title: 'الأعدادات',
      items: [
        SettingsMenuItem(
          id: 'favorites',
          title: 'المفضلات',
          icon: Icons.favorite_border_rounded,
        ),
        SettingsMenuItem(
          id: 'edit_profile',
          title: 'تعديل معلوماتك',
          icon: Icons.edit_outlined,
        ),
        SettingsMenuItem(
          id: 'delivery_location',
          title: 'موقع التوصيل',
          icon: Icons.location_on_outlined,
        ),
        SettingsMenuItem(
          id: 'payment_cards',
          title: 'بطاقات الدفع الألكتروني',
          icon: Icons.credit_card_outlined,
        ),
        SettingsMenuItem(
          id: 'notifications',
          title: 'الأشعارات',
          icon: Icons.notifications_none_outlined,
          kind: SettingsItemKind.toggle,
        ),
      ],
    ),
    SettingsSection(
      title: 'عن التطبيق',
      items: [
        SettingsMenuItem(
          id: 'about_us',
          title: 'من نحن ؟',
          icon: Icons.verified_outlined,
        ),
        SettingsMenuItem(
          id: 'contact',
          title: 'تواصل معنا',
          icon: Icons.chat_bubble_outline_rounded,
        ),
        SettingsMenuItem(
          id: 'help',
          title: 'المساعدة',
          icon: Icons.help_outline_rounded,
        ),
      ],
    ),
  ];

  static final List<SettingsMenuItem> accountActions = [
    SettingsMenuItem(
      id: 'logout',
      title: 'تسجيل الخروج',
      icon: Icons.logout_rounded,
    ),
    SettingsMenuItem(
      id: 'delete_account',
      title: 'حذف الحساب',
      icon: Icons.delete_outline_rounded,
    ),
  ];

  Future<void> toggleNotifications(bool value) async {
    notificationsEnabled.value = value;
    await _prefs.setBool(StorageKeys.notificationsEnabled, value);
  }

  void onProfileTap() {
    // TODO: اختيار العنوان / الملف الشخصي
  }

  void onMenuItemTap(String id) {
    // يُعالج من SettingsPage حسب نوع البند
  }

  Future<void> onLogout() async {
    final confirmed = await SettingsConfirmDialog.showLogout();
    if (confirmed != true) return;

    try {
      if (Get.isRegistered<AuthService>()) {
        await Get.find<AuthService>().logout();
      }
    } catch (_) {
      // يُكمل تسجيل الخروج محلياً حتى لو فشل الطلب
    }

    await Get.find<SessionController>().clearSession();
    Get.offAll(() => const LoginPage());
  }

  Future<void> onDeleteAccount() async {
    final confirmed = await SettingsConfirmDialog.showDeleteAccount();
    if (confirmed != true) return;

    // TODO: حذف الحساب عبر API
    await Get.find<SessionController>().clearSession();
    Get.offAll(() => const LoginPage());
  }
}
