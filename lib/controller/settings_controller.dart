import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../model/settings_menu_item.dart';
import '../service_layer/services/get_storage_service.dart';
import '../utils/storage_keys.dart';
import '../view/auth/login_page.dart';
import '../widget/settings/settings_confirm_dialog.dart';
import 'session_controller.dart';

class SettingsController extends GetxController {
  final _storage = GetStorageService();

  final userName = 'د. بهجة مصطفى'.obs;
  final userPhone = '0770 000 000'.obs;
  final userAltPhone = ''.obs;
  final userAddress = 'العيادة ، بابل ، شارع 40'.obs;
  final notificationsEnabled = true.obs;

  @override
  void onInit() {
    super.onInit();
    _loadProfile();
  }

  void _loadProfile() {
    final name = _storage.read<String>(StorageKeys.profileName);
    final phone = _storage.read<String>(StorageKeys.profilePhone);
    final altPhone = _storage.read<String>(StorageKeys.profileAltPhone);
    final address = _storage.read<String>(StorageKeys.profileAddress);

    if ((name ?? '').isNotEmpty) userName.value = name!;
    if ((phone ?? '').isNotEmpty) userPhone.value = phone!;
    if (altPhone != null) userAltPhone.value = altPhone;
    if ((address ?? '').isNotEmpty) userAddress.value = address!;
  }

  Future<void> saveProfile({
    String? name,
    String? phone,
    String? altPhone,
    String? address,
  }) async {
    if (name != null && name.trim().isNotEmpty) {
      userName.value = name.trim();
      await _storage.write(StorageKeys.profileName, userName.value);
    }
    if (phone != null && phone.trim().isNotEmpty) {
      userPhone.value = phone.trim();
      await _storage.write(StorageKeys.profilePhone, userPhone.value);
    }
    if (altPhone != null) {
      userAltPhone.value = altPhone.trim();
      await _storage.write(StorageKeys.profileAltPhone, userAltPhone.value);
    }
    if (address != null && address.trim().isNotEmpty) {
      userAddress.value = address.trim();
      await _storage.write(StorageKeys.profileAddress, userAddress.value);
    }
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

  void toggleNotifications(bool value) {
    notificationsEnabled.value = value;
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

    Get.find<SessionController>().clearSession();
    Get.offAll(() => const LoginPage());
  }

  Future<void> onDeleteAccount() async {
    final confirmed = await SettingsConfirmDialog.showDeleteAccount();
    if (confirmed != true) return;

    // TODO: حذف الحساب عبر API
    Get.find<SessionController>().clearSession();
    Get.offAll(() => const LoginPage());
  }
}
