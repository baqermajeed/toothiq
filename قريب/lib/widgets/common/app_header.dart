import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../controllers/header_search_controller.dart';
import '../../core/theme/app_theme.dart';
import 'app_spacing.dart';

/// هيدر ثابت: اللوجو واسم التطبيق، أو مربع بحث مع انتقال أنيميشن عند تفعيل البحث.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    this.searchController,
    this.actions,
  });

  final HeaderSearchController? searchController;
  final List<Widget>? actions;

  static const String _appName = 'قريب';
  static const String _searchIconPath = 'assets/icons/search-alt-svgrepo-com.svg';

  @override
  Size get preferredSize => Size.fromHeight(56.h);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 8.h),
          child: Row(
            children: [
              Expanded(
                child: searchController != null
                    ? Obx(() => AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.2, 0),
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutCubic,
                                )),
                                child: child,
                              ),
                            );
                          },
                          child: searchController!.isSearchMode.value
                              ? SizedBox(
                                  key: const ValueKey('search'),
                                  width: double.infinity,
                                  child: _HeaderSearchField(
                                    controller: searchController!,
                                  ),
                                )
                              : Align(
                                  key: const ValueKey('logo'),
                                  alignment: AlignmentDirectional.centerStart,
                                  child: _LogoAndTitle(colorScheme: colorScheme),
                                ),
                        ))
                    : Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: _LogoAndTitle(colorScheme: colorScheme),
                      ),
              ),
              if (searchController != null) ...[
                Obx(() {
                  if (searchController!.isSearchMode.value) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _HeaderCancelButton(controller: searchController!),
                        SizedBox(width: 6.w),
                        _HeaderSubmitButton(controller: searchController!),
                      ],
                    );
                  }
                  return _HeaderSearchIconButton(controller: searchController!);
                }),
                SizedBox(width: 8.w),
              ],
              if (actions != null) ...actions!,
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoAndTitle extends StatelessWidget {
  const _LogoAndTitle({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/icon_app.png',
          height: 40.h,
          width: 40.w,
          fit: BoxFit.contain,
        ),
        SizedBox(width: 12.w),
        Text(
          AppHeader._appName,
          style: TextStyle(
            fontFamily: kFontFamilyKufam,
            fontSize: 22.sp,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _HeaderSearchField extends StatelessWidget {
  const _HeaderSearchField({required this.controller});

  final HeaderSearchController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 40.h,
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.5)),
      ),
      alignment: Alignment.centerRight,
      child: TextField(
        controller: controller.textController,
        focusNode: controller.focusNode,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => controller.submitSearch(),
        style: TextStyle(
          fontFamily: kFontFamilyCairo,
          fontSize: 15.sp,
          color: colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: 'ابحث عن منتجات...',
          hintStyle: TextStyle(
            fontFamily: kFontFamilyCairo,
            fontSize: 14.sp,
            color: colorScheme.onSurfaceVariant,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 10.h),
          isDense: true,
        ),
      ),
    );
  }
}

class _HeaderSearchIconButton extends StatelessWidget {
  const _HeaderSearchIconButton({required this.controller});

  final HeaderSearchController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return IconButton(
      onPressed: controller.openSearch,
      icon: SvgPicture.asset(
        AppHeader._searchIconPath,
        width: 24.sp,
        height: 24.sp,
        colorFilter: ColorFilter.mode(colorScheme.primary, BlendMode.srcIn),
      ),
      padding: EdgeInsets.zero,
      constraints: BoxConstraints(minWidth: 40.w, minHeight: 40.h),
    );
  }
}

class _HeaderCancelButton extends StatelessWidget {
  const _HeaderCancelButton({required this.controller});

  final HeaderSearchController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return IconButton(
      onPressed: controller.closeSearch,
      icon: Icon(Icons.close_rounded, size: 22.sp, color: colorScheme.onSurfaceVariant),
      padding: EdgeInsets.zero,
      constraints: BoxConstraints(minWidth: 36.w, minHeight: 36.h),
    );
  }
}

class _HeaderSubmitButton extends StatelessWidget {
  const _HeaderSubmitButton({required this.controller});

  final HeaderSearchController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: controller.submitSearch,
        borderRadius: BorderRadius.circular(18.r),
        child: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(18.r),
          ),
          child: SvgPicture.asset(
            AppHeader._searchIconPath,
            width: 20.sp,
            height: 20.sp,
            colorFilter: ColorFilter.mode(colorScheme.onPrimary, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}
