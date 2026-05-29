import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../model/settings_menu_item.dart';
import '../view/auth/login_page.dart';
import '../widget/settings/settings_confirm_dialog.dart';
import 'session_controller.dart';

class SettingsController extends GetxController {
  final userName = 'د. بهجة مصطفى'.obs;
  final userAddress = 'العيادة ، بابل ، شارع 40'.obs;
  final notificationsEnabled = true.obs;

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
