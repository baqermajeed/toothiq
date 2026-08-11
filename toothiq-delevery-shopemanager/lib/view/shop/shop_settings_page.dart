import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controller/session_controller.dart';
import '../../controller/shop_catalog_controller.dart';
import '../../controller/shop_profile_controller.dart';
import '../../utils/app_colors.dart';
import '../../widget/my_text.dart';
import '../../widget/shop/settings_menu_tile.dart';
import '../../widget/shop/shop_gradient_header.dart';
import 'edit_shop_profile_page.dart';
import 'shop_brands_page.dart';
import 'shop_categories_page.dart';

class ShopSettingsPage extends StatelessWidget {
  const ShopSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionController>();
    final catalog = Get.find<ShopCatalogController>();

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: ShopGradientHeader(
              onEditTap: () => Get.to(() => const EditShopProfilePage()),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 24.h),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SettingsSectionTitle('إدارة المتجر'),
                SettingsMenuTile(
                  icon: Icons.store_outlined,
                  title: 'بيانات المتجر',
                  subtitle: 'الاسم، الشعار، الوصف، العنوان وأرقام التواصل',
                  onTap: () => Get.to(() => const EditShopProfilePage()),
                ),
                SizedBox(height: 10.h),
                Obx(
                  () => SettingsMenuTile(
                    icon: Icons.category_outlined,
                    title: 'أقسام المنتجات',
                    subtitle: '${catalog.shopCategories.length} قسم — تنظيم منتجاتك حسب الفئات',
                    trailing: _CountBadge('${catalog.shopCategories.length}'),
                    onTap: () => Get.to(() => const ShopCategoriesPage()),
                  ),
                ),
                SizedBox(height: 10.h),
                Obx(
                  () => SettingsMenuTile(
                    icon: Icons.verified_outlined,
                    title: 'البراندات',
                    subtitle: '${catalog.brands.length} براند — العلامات التجارية المتوفرة',
                    trailing: _CountBadge('${catalog.brands.length}'),
                    onTap: () => Get.to(() => const ShopBrandsPage()),
                  ),
                ),
                SizedBox(height: 24.h),
                const SettingsSectionTitle('الحساب'),
                Obx(() {
                  final shop = Get.find<ShopProfileController>().profile.value;
                  return SettingsMenuTile(
                    icon: Icons.person_outline,
                    title: 'صاحب الحساب',
                    subtitle: session.displayName.value.isNotEmpty
                        ? session.displayName.value
                        : shop?.name ?? 'حساب المتجر',
                    showChevron: false,
                  );
                }),
                SizedBox(height: 10.h),
                SettingsMenuTile(
                  icon: Icons.info_outline,
                  title: 'عن ToothIQ Partner',
                  subtitle: 'إصدار 0.1.0 — لوحة إدارة المتاجر',
                  showChevron: false,
                ),
                SizedBox(height: 28.h),
                _LogoutButton(onPressed: () => session.logout()),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge(this.count);

  final String count;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: 8.w),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: MyText(count, fontSize: 11.sp, color: AppColors.primary),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
            color: AppColors.error.withValues(alpha: 0.06),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout, color: AppColors.error, size: 20.sp),
              SizedBox(width: 8.w),
              MyText('تسجيل الخروج', fontSize: 15.sp, color: AppColors.error),
            ],
          ),
        ),
      ),
    );
  }
}
