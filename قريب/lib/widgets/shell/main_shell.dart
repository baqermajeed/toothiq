import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/contact_info_controller.dart';
import '../../controllers/header_search_controller.dart';
import '../../controllers/login_controller.dart';
import '../../controllers/main_shell_controller.dart';
import '../../controllers/orders_controller.dart';
import '../../controllers/register_controller.dart';
import '../../utils/launch_phone_utils.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../common/app_toast.dart';
import '../../screens/categories/categories_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/orders/orders_screen.dart';
import '../common/app_header.dart';
import '../common/app_spacing.dart';

/// يعرض دايلوج تأكيد بنعم/لا ويُرجع true عند اختيار نعم.
Future<bool> _showConfirmDialog(String title, String content) async {
  final ctx = Get.context;
  if (ctx == null) return false;
  final colorScheme = Theme.of(ctx).colorScheme;
  final result = await Get.dialog<bool>(
    AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: kFontFamilyCairo,
          fontSize: 20.sp,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
        textAlign: TextAlign.center,
      ),
      content: Text(
        content,
        style: TextStyle(
          fontFamily: kFontFamilyCairo,
          fontSize: 15.sp,
          color: colorScheme.onSurfaceVariant,
          height: 1.4,
        ),
        textAlign: TextAlign.center,
      ),
      contentPadding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 20.h),
      actions: [
        TextButton(
          onPressed: () => Get.back(result: false),
          child: Text(
            'لا',
            style: TextStyle(
              fontFamily: kFontFamilyCairo,
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        FilledButton(
          onPressed: () => Get.back(result: true),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryDark,
            foregroundColor: AppColors.primaryLight,
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.r),
            ),
          ),
          child: Text(
            'نعم',
            style: TextStyle(
              fontFamily: kFontFamilyCairo,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
    barrierDismissible: false,
  );
  return result == true;
}

/// يعرض دايلوج لودنغ أثناء تنفيذ عملية.
void _showLoadingDialog(String message) {
  final ctx = Get.context;
  if (ctx == null) return;
  final colorScheme = Theme.of(ctx).colorScheme;
  Get.dialog(
    PopScope(
      canPop: false,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 32.w),
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 40.w,
                  height: 40.h,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.primary,
                  ),
                ),
                AppSpacing.verticalMd,
                Text(
                  message,
                  style: TextStyle(
                    fontFamily: kFontFamilyCairo,
                    fontSize: 16.sp,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    barrierDismissible: false,
  );
}

/// ينفّذ تسجيل الخروج مع إغلاق اللودنغ والتنقل للرئيسية.
Future<void> _performLogout() async {
  final auth = Get.find<AuthController>();
  _showLoadingDialog('جاري تسجيل الخروج...');
  try {
    await auth.logout();
    if (Get.isDialogOpen == true) Get.back();
    if (Get.isRegistered<LoginController>()) {
      Get.delete<LoginController>(force: true);
    }
    if (Get.isRegistered<RegisterController>()) {
      Get.delete<RegisterController>(force: true);
    }
    if (Get.isRegistered<MainShellController>()) {
      Get.delete<MainShellController>(force: true);
    }
    Get.offAllNamed('/');
  } catch (_) {
    if (Get.isDialogOpen == true) Get.back();
  }
}

/// هيكل التطبيق الرئيسي: هيدر ثابت باللوجو + محتوى + شريط تنقل سفلي.
class MainShell extends GetView<MainShellController> {
  const MainShell({super.key});

  static const int kTabHome = 0;
  static const int kTabCategories = 1;
  static const int kTabOrders = 2;
  static const int kTabProfile = 3;

  static List<Widget> _buildPages() {
    return [
      const HomeContent(),
      const CategoriesContent(),
      const OrdersContent(),
      const _ProfilePage(),
    ];
  }

  static List<Widget> _buildNavItems(BuildContext context, MainShellController ctrl) {
    return [
      _NavItem(
        iconPath: 'assets/icons/home-2-svgrepo-com.svg',
        icon: Icons.home_rounded,
        label: 'الرئيسية',
        isSelected: ctrl.currentIndex.value == kTabHome,
        onTap: () => ctrl.setTab(kTabHome),
      ),
      _NavItem(
        iconPath: 'assets/icons/category.svg',
        icon: Icons.grid_view_rounded,
        label: 'التصنيفات',
        isSelected: ctrl.currentIndex.value == kTabCategories,
        onTap: () => ctrl.setTab(kTabCategories),
      ),
      _NavItem(
        iconPath: 'assets/icons/bag-2-svgrepo-com.svg',
        icon: Icons.shopping_bag_rounded,
        label: 'الطلبات',
        isSelected: ctrl.currentIndex.value == kTabOrders,
        onTap: () {
          ctrl.setTab(kTabOrders);
          if (Get.isRegistered<OrdersController>()) {
            Get.find<OrdersController>().loadOrders();
          }
        },
      ),
      _NavItem(
        iconPath: 'assets/icons/profile-svgrepo-com.svg',
        icon: Icons.person_rounded,
        label: 'حسابي',
        isSelected: ctrl.currentIndex.value == kTabProfile,
        onTap: () => ctrl.setTab(kTabProfile),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (!Get.isRegistered<HeaderSearchController>()) {
      Get.put(HeaderSearchController(), permanent: false);
    }
    final headerSearch = Get.find<HeaderSearchController>();
    return Scaffold(
      appBar: AppHeader(
        searchController: headerSearch,
        actions: [
          _CartHeaderAction(),
        ],
      ),
      body: Obx(() {
        final pages = _buildPages();
        return IndexedStack(
          index: controller.currentIndex.value.clamp(0, pages.length - 1),
          children: pages,
        );
      }),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
            child: Obx(() => Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _buildNavItems(context, controller),
            )),
          ),
        ),
      ),
    );
  }
}

/// أيقونة السلة في الهيدر مع عداد.
class _CartHeaderAction extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cart = Get.find<CartController>();
    final colorScheme = Theme.of(context).colorScheme;
    return Obx(() {
      final count = cart.itemCount;
      return IconButton(
        onPressed: () => Get.toNamed('/cart'),
        icon: Badge(
          isLabelVisible: count > 0,
          label: Text(
            count > 99 ? '99+' : '$count',
            style: TextStyle(
              fontFamily: kFontFamilyCairo,
              fontSize: 10.sp,
              color: colorScheme.onPrimary,
            ),
          ),
          child: SvgPicture.asset(
            'assets/icons/dark-shop-cart-svgrepo-com.svg',
            width: 24.sp,
            height: 24.sp,
            colorFilter: ColorFilter.mode(
              colorScheme.primary,
              BlendMode.srcIn,
            ),
          ),
        ),
      );
    });
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    this.iconPath,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  /// مسار أيقونة SVG من مجلد assets/icons — إن وُجدت تُعرض بدل [icon].
  final String? iconPath;
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedBg = isDark ? colorScheme.primaryContainer : AppColors.primaryLight;
    final selectedFg = isDark ? colorScheme.onPrimaryContainer : AppColors.primaryDark;
    final unselectedFg = colorScheme.onSurfaceVariant;
    final iconColor = isSelected ? selectedFg : unselectedFg;

    final iconWidget = iconPath != null
        ? SvgPicture.asset(
            iconPath!,
            width: 24.sp,
            height: 24.sp,
            colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
          )
        : Icon(icon, size: 24.sp, color: iconColor);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : Colors.transparent,
          borderRadius: BorderRadius.circular(16.r),
          border: isSelected
              ? Border.all(color: (isDark ? colorScheme.primary : AppColors.primaryMedium).withValues(alpha: 0.5))
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget,
            AppSpacing.verticalXs,
            Text(
              label,
              style: TextStyle(
                fontFamily: kFontFamilyCairo,
                fontSize: 11.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? selectedFg : unselectedFg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage();

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final user = auth.user.value;
      final isGuest = user == null;
      return SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSpacing.verticalXl,
            Text(
              'حسابي',
              style: TextStyle(
                fontFamily: kFontFamilyCairo,
                fontSize: 22.sp,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            AppSpacing.verticalLg,
            Text(
              'مرحباً، ${user?.name ?? 'ضيف'}',
              style: TextStyle(
                fontFamily: kFontFamilyCairo,
                fontSize: 16.sp,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            AppSpacing.verticalLg,
            _ContactSocialRow(),
            AppSpacing.verticalXl,
            _ProfileSettingCard(
              children: [
                if (!isGuest)
                  _ProfileSettingTile(
                    icon: Icons.edit_rounded,
                    label: 'تعديل المعلومات الشخصية',
                    onTap: () => Get.toNamed('/edit-profile'),
                    trailing: Icon(Icons.chevron_left_rounded, size: 24.sp, color: colorScheme.primary),
                  ),
                _ProfileSettingTile(
                  icon: Icons.privacy_tip_rounded,
                  label: 'سياسة الخصوصية',
                  onTap: () => Get.toNamed(
                    '/static-content',
                    arguments: {
                      'title': 'سياسة الخصوصية',
                      'type': 'privacy-policy',
                    },
                  ),
                  trailing: Icon(Icons.chevron_left_rounded, size: 24.sp, color: colorScheme.primary),
                ),
                // _ProfileSettingTile(
                //   icon: Icons.business_rounded,
                //   label: 'الشركة المطورة',
                //   onTap: () => Get.toNamed('/static-content', arguments: {'title': 'الشركة المطورة', 'body': 'معلومات الشركة المطورة ستُضاف هنا.'}),
                //   trailing: Icon(Icons.chevron_left_rounded, size: 24.sp, color: colorScheme.primary),
                // ),
                // _ProfileSettingTile(
                //   icon: Icons.support_rounded,
                //   label: 'الدعم',
                //   onTap: () => Get.toNamed('/static-content', arguments: {'title': 'الدعم', 'body': 'للمساعدة والدعم تواصل معنا عبر البريد أو الهاتف.'}),
                //   trailing: Icon(Icons.chevron_left_rounded, size: 24.sp, color: colorScheme.primary),
                // ),
                // _ProfileSettingTile(
                //   icon: Icons.dark_mode_rounded,
                //   label: 'تفعيل الوضع الليلي',
                //   onTap: null,
                //   trailing: Obx(() => Switch(
                //     value: themeCtrl.isDarkMode,
                //     onChanged: (_) => themeCtrl.toggleDarkMode(),
                //   )),
                // ),
              ],
            ),
            AppSpacing.verticalMd,
            _ProfileSettingCard(
              backgroundColor: isGuest
                  ? (isDark ? colorScheme.primaryContainer.withValues(alpha: 0.3) : AppColors.primaryLight.withValues(alpha: 0.5))
                  : (isDark ? colorScheme.error.withValues(alpha: 0.15) : AppColors.error.withValues(alpha: 0.08)),
              borderColor: isGuest
                  ? (colorScheme.primary.withValues(alpha: 0.4))
                  : AppColors.error.withValues(alpha: 0.4),
              children: [
                _ProfileSettingTile(
                  icon: isGuest ? Icons.login_rounded : Icons.logout_rounded,
                  label: isGuest ? 'تسجيل الدخول' : 'تسجيل الخروج',
                  iconColor: isGuest ? colorScheme.primary : AppColors.error,
                  textColor: isGuest ? colorScheme.primary : AppColors.error,
                  onTap: () async {
                    if (isGuest) {
                      Get.toNamed('/login');
                    } else {
                      final confirmed = await _showConfirmDialog(
                        'تسجيل الخروج',
                        'هل ترغب بتسجيل الخروج؟',
                      );
                      if (confirmed) await _performLogout();
                    }
                  },
                ),
                if (!isGuest)
                  _ProfileSettingTile(
                    icon: Icons.person_off_rounded,
                    label: 'حذف الحساب',
                    iconColor: AppColors.error,
                    textColor: AppColors.error,
                    onTap: () async {
                      final confirmed = await _showConfirmDialog(
                        'حذف الحساب',
                        'هل ترغب بحذف الحساب؟',
                      );
                      if (confirmed) await _performLogout();
                    },
                  ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

/// ألوان خفيفة لخلفيات أيقونات المنصات (تتناسق مع الثيم).
abstract final class _SocialBrandColors {
  static const Color facebookBg = Color(0xFFE8F0FE);
  static const Color instagramBg = Color(0xFFFCE4EC);
  static const Color whatsappBg = Color(0xFFE8F5E9);
  static const Color facebookBgDark = Color(0xFF1E3A5F);
  static const Color instagramBgDark = Color(0xFF3D1F2E);
  static const Color whatsappBgDark = Color(0xFF1B2E1F);
}

/// بطاقة «تواصل معنا»: فيسبوك، انستغرام، واتساب الدعم — صفوف كباقي الإعدادات.
class _ContactSocialRow extends StatelessWidget {
  const _ContactSocialRow();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contactCtrl = Get.find<ContactInfoController>();
    final border = colorScheme.outline.withValues(alpha: 0.2);

    return _ProfileSettingCard(
      children: [
        _ContactSocialTile(
          assetPath: 'assets/icons/facebook-color-svgrepo-com.svg',
          label: 'فيسبوك',
          subtitle: 'تابعنا على فيسبوك',
          iconBg: isDark ? _SocialBrandColors.facebookBgDark : _SocialBrandColors.facebookBg,
          onTap: () async {
            final info = await contactCtrl.loadContactInfo();
            if (info.facebookUrl.trim().isEmpty) {
              AppToast.show('تنبيه', 'لم يتم تعيين رابط الفيسبوك بعد', type: ToastType.warning);
              return;
            }
            await launchUrlString(info.facebookUrl);
          },
        ),
        Divider(height: 1, indent: 72.r, endIndent: 16.w, color: border),
        _ContactSocialTile(
          assetPath: 'assets/icons/instagram-1-svgrepo-com.svg',
          label: 'انستغرام',
          subtitle: 'تابعنا على انستغرام',
          iconBg: isDark ? _SocialBrandColors.instagramBgDark : _SocialBrandColors.instagramBg,
          onTap: () async {
            final info = await contactCtrl.loadContactInfo();
            if (info.instagramUrl.trim().isEmpty) {
              AppToast.show('تنبيه', 'لم يتم تعيين رابط الانستغرام بعد', type: ToastType.warning);
              return;
            }
            await launchUrlString(info.instagramUrl);
          },
        ),
        Divider(height: 1, indent: 72.r, endIndent: 16.w, color: border),
        _ContactSocialTile(
          assetPath: 'assets/icons/whatsapp-color-svgrepo-com.svg',
          label: 'تواصل مع الدعم',
          subtitle: 'واتساب',
          iconBg: isDark ? _SocialBrandColors.whatsappBgDark : _SocialBrandColors.whatsappBg,
          onTap: () async {
            final info = await contactCtrl.loadContactInfo();
            if (info.supportPhone.trim().isEmpty) {
              AppToast.show('تنبيه', 'لم يتم تعيين رقم التواصل مع الدعم بعد', type: ToastType.warning);
              return;
            }
            await launchWhatsApp(info.supportPhone);
          },
        ),
      ],
    );
  }
}

/// صف واحد لمنصة تواصل: أيقونة SVG + عنوان + وصف فرعي + سهم.
class _ContactSocialTile extends StatelessWidget {
  const _ContactSocialTile({
    required this.assetPath,
    required this.label,
    required this.subtitle,
    required this.iconBg,
    required this.onTap,
  });

  final String assetPath;
  final String label;
  final String subtitle;
  final Color iconBg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        child: Row(
          children: [
            Icon(Icons.chevron_left_rounded, size: 24.sp, color: colorScheme.primary),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: kFontFamilyCairo,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: kFontFamilyCairo,
                      fontSize: 13.sp,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 48.w,
              height: 48.h,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Center(
                child: SvgPicture.asset(
                  assetPath,
                  width: 26.w,
                  height: 26.h,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSettingCard extends StatelessWidget {
  const _ProfileSettingCard({
    required this.children,
    this.backgroundColor,
    this.borderColor,
  });

  final List<Widget> children;
  final Color? backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bg = backgroundColor ?? colorScheme.surfaceContainerHighest;
    final border = borderColor ?? colorScheme.outline.withValues(alpha: 0.2);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: border),
      ),
      child: Column(
        children: children.asMap().entries.map<Widget>((e) {
          final isLast = e.key == children.length - 1;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              e.value,
              if (!isLast)
                Divider(height: 1, indent: 56.r, endIndent: 16.w, color: border),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _ProfileSettingTile extends StatelessWidget {
  const _ProfileSettingTile({
    required this.icon,
    required this.label,
    this.onTap,
    this.trailing,
    this.iconColor,
    this.textColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? iconColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconC = iconColor ?? colorScheme.primary;
    final textC = textColor ?? colorScheme.onSurface;

    final content = Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Row(
        children: [
          Icon(icon, size: 24.sp, color: iconC),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: kFontFamilyCairo,
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
                color: textC,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: content,
      );
    }
    return content;
  }
}
