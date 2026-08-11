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

  final userName = ''.obs;
  final userPhone = ''.obs;
  final userAltPhone = ''.obs;
  final userAddress = ''.obs;
  final profileImagePath = RxnString();
  final notificationsEnabled = true.obs;
  final isSyncingProfile = false.obs;
  String? _userId;
  Worker? _sessionUserWorker;

  @override
  void onInit() {
    super.onInit();
    _loadDevicePreferences();
    _bindSessionUserState();
  }

  @override
  void onClose() {
    _sessionUserWorker?.dispose();
    super.onClose();
  }

  void _loadDevicePreferences() {
    final notifications = _prefs.getBool(StorageKeys.notificationsEnabled);
    if (notifications != null) notificationsEnabled.value = notifications;
  }

  void _bindSessionUserState() {
    if (!Get.isRegistered<SessionController>()) return;
    final session = Get.find<SessionController>();

    // تعبئة أولية عند إنشاء الكنترولر بعد اكتمال تسجيل الدخول.
    bindToUser(session.user.value);

    // إبقاء البطاقة متزامنة مع أي تغيير بالجسلة (دخول/خروج/استرجاع).
    _sessionUserWorker = ever<UserModel?>(
      session.user,
      (user) => bindToUser(user),
    );
  }

  Future<void> bindToUser(UserModel? user) async {
    if (user == null || user.id.trim().isEmpty) {
      _userId = null;
      _resetProfileState();
      return;
    }

    _userId = user.id;
    applyUserFromSession(user);
    await _loadProfileImageForCurrentUser();
  }

  void _resetProfileState() {
    userName.value = '';
    userPhone.value = '';
    userAltPhone.value = '';
    userAddress.value = '';
    profileImagePath.value = null;
  }

  Future<void> _loadProfileImageForCurrentUser() async {
    profileImagePath.value = null;
    final userId = _userId;
    if (userId == null || userId.isEmpty) return;

    final imagePath = _prefs.getString(StorageKeys.profileImagePathFor(userId));
    if (imagePath != null && imagePath.isNotEmpty) {
      profileImagePath.value = imagePath;
    }
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
  }

  Future<void> saveProfile({
    String? name,
    String? phone,
    String? altPhone,
    String? address,
  }) async {
    if (name != null && name.trim().isNotEmpty) {
      userName.value = name.trim();
    }
    if (phone != null && phone.trim().isNotEmpty) {
      userPhone.value = phone.trim();
    }
    if (altPhone != null) {
      userAltPhone.value = altPhone.trim();
    }
    if (address != null && address.trim().isNotEmpty) {
      userAddress.value = address.trim();
    }
  }

  Future<void> saveProfileImagePath(String? path) async {
    final trimmed = path?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      profileImagePath.value = null;
      final userId = _userId;
      if (userId != null && userId.isNotEmpty) {
        await _prefs.remove(StorageKeys.profileImagePathFor(userId));
      }
      return;
    }

    profileImagePath.value = trimmed;
    final userId = _userId;
    if (userId == null || userId.isEmpty) return;
    await _prefs.setString(StorageKeys.profileImagePathFor(userId), trimmed);
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
    required String clinicName,
  }) async {
    final user = await _userService.updateCurrentUser(
      name: name,
      clinicName: clinicName,
    );
    await _saveUserModelLocally(user);
    if (Get.isRegistered<SessionController>()) {
      Get.find<SessionController>().user.value = user;
    }
    AppDataRefreshService.refreshAfterProfileUpdate();
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
