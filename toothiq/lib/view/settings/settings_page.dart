import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controller/settings_controller.dart';
import '../../utils/app_colors.dart';
import '../../widget/app_bottom_navigation.dart';
import '../../widget/main_app_bar.dart';
import '../../widget/my_text.dart';
import '../favorites/favorites_page.dart';
import '../settings/saved_addresses_page.dart';
import '../settings/about_us_page.dart';
import '../settings/contact_us_page.dart';
import '../settings/help_page.dart';
import '../../widget/settings/edit_profile_bottom_sheet.dart';
import '../../widget/settings/settings_menu_tile.dart';
import '../../widget/settings/settings_profile_card.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsController>();
    final topInset =
        MediaQuery.paddingOf(context).top + MainAppBar.toolbarHeight();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.settingsPageBackground,
        extendBodyBehindAppBar: true,
        appBar: const MainAppBar(title: 'الأعدادات'),
        body: ListView(
          padding: EdgeInsets.fromLTRB(
            16.w,
            topInset + 8.h,
            16.w,
            AppBottomNavMetrics.floatingBarReservedHeight.h,
          ),
          children: [
            SettingsProfileCard(controller: settings),
            SizedBox(height: 20.h),
            ...SettingsController.settingsSections.expand(
              (section) => [
                _SectionTitle(title: section.title),
                SizedBox(height: 10.h),
                ...section.items.map(
                  (item) => Padding(
                    padding: EdgeInsets.only(bottom: 10.h),
                    child: SettingsMenuTile(
                      item: item,
                      controller: settings,
                      onTap: () => _onSettingsItemTap(item.id, settings),
                    ),
                  ),
                ),
                SizedBox(height: 6.h),
              ],
            ),
            _SectionTitle(title: 'عن التطبيق'),
            SizedBox(height: 10.h),
            ...SettingsController.accountActions.map(
              (item) => Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: SettingsMenuTile(
                  item: item,
                  controller: settings,
                  onTap: () {
                    if (item.id == 'logout') {
                      settings.onLogout();
                    } else if (item.id == 'delete_account') {
                      settings.onDeleteAccount();
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _onSettingsItemTap(String id, SettingsController settings) {
  if (id == 'edit_profile') {
    EditProfileBottomSheet.show();
    return;
  }
  if (id == 'favorites') {
    FavoritesPage.open();
    return;
  }
  if (id == 'delivery_location') {
    SavedAddressesPage.open();
    return;
  }
  if (id == 'about_us') {
    AboutUsPage.open();
    return;
  }
  if (id == 'contact') {
    ContactUsPage.open();
    return;
  }
  if (id == 'help') {
    HelpPage.open();
    return;
  }
  settings.onMenuItemTap(id);
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return MyText(
      title,
      fontSize: 16.sp,
      fontWeight: FontWeight.w800,
      color: AppColors.textPrimary,
      textAlign: TextAlign.right,
    );
  }
}
