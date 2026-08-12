import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controller/shop_catalog_controller.dart';
import '../../model/shop_category.dart';
import '../../utils/app_colors.dart';
import '../../widget/auth_text_field.dart';
import '../../widget/my_text.dart';
import '../../widget/shop/app_image.dart';
import '../../widget/shop/category_icon_picker.dart';
import '../../core/constants/category_preset_icons.dart';

class ShopCategoriesPage extends StatefulWidget {
  const ShopCategoriesPage({super.key});

  @override
  State<ShopCategoriesPage> createState() => _ShopCategoriesPageState();
}

class _ShopCategoriesPageState extends State<ShopCategoriesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<ShopCatalogController>().loadShopCategories(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ShopCatalogController>();

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: MyText('أقسام المتجر', fontSize: 18.sp),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: Get.back,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddOptions(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: MyText('قسم جديد', fontSize: 13.sp, color: Colors.white),
      ),
      body: Obx(() {
        if (controller.isLoadingShopCategories.value && controller.shopCategories.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final list = controller.shopCategories;
        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.category_outlined, size: 56.sp, color: AppColors.textLight),
                SizedBox(height: 12.h),
                MyText(
                  'لا توجد أقسام بعد',
                  fontSize: 15.sp,
                  color: AppColors.textSecondary,
                ),
                SizedBox(height: 6.h),
                MyText(
                  'أضف أقسام لتنظيم منتجاتك',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textLight,
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 88.h),
          itemCount: list.length,
          separatorBuilder: (_, __) => SizedBox(height: 10.h),
          itemBuilder: (context, index) {
            final category = list[index];
            return _CategoryCard(
              category: category,
              onEdit: () => _openForm(context, category: category),
              onDelete: () => _confirmDelete(category),
            );
          },
        );
      }),
    );
  }

  void _openAddOptions(BuildContext context) {
    final controller = Get.find<ShopCatalogController>();
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            MyText('إضافة قسم للمتجر', fontSize: 17.sp),
            SizedBox(height: 16.h),
            ListTile(
              leading: Icon(Icons.admin_panel_settings_outlined, color: AppColors.primary),
              title: const Text('من أقسام الإدارة', style: TextStyle(fontFamily: 'Expo Arabic')),
              subtitle: const Text(
                'اختر قسماً جاهزاً من لوحة التحكم',
                style: TextStyle(fontFamily: 'Expo Arabic'),
              ),
              onTap: () {
                Get.back();
                _openAdminCategoryPicker(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.add_circle_outline, color: AppColors.primary),
              title: const Text('قسم مخصص', style: TextStyle(fontFamily: 'Expo Arabic')),
              subtitle: const Text(
                'أنشئ قسماً خاصاً بمتجرك',
                style: TextStyle(fontFamily: 'Expo Arabic'),
              ),
              onTap: () {
                Get.back();
                _openForm(context);
              },
            ),
            if (controller.availableAdminCategories.isEmpty)
              Padding(
                padding: EdgeInsets.only(top: 4.h),
                child: MyText(
                  'جميع أقسام الإدارة مضافة لمتجرك',
                  fontSize: 11.sp,
                  color: AppColors.textLight,
                ),
              ),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _openAdminCategoryPicker(BuildContext context) {
    final controller = Get.find<ShopCatalogController>();
    final available = controller.availableAdminCategories;
    if (available.isEmpty) {
      Get.snackbar('تنبيه', 'جميع أقسام الإدارة مضافة لمتجرك بالفعل');
      return;
    }

    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            MyText('اختر من أقسام الإدارة', fontSize: 17.sp),
            SizedBox(height: 12.h),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: available.length,
                separatorBuilder: (_, __) => SizedBox(height: 8.h),
                itemBuilder: (context, index) {
                  final category = available[index];
                  return ListTile(
                    leading: AppImage(
                      path: category.imagePath,
                      width: 40.w,
                      height: 40.w,
                      borderRadius: BorderRadius.circular(10.r),
                      icon: Icons.category_outlined,
                    ),
                    title: Text(category.nameAr, style: const TextStyle(fontFamily: 'Expo Arabic')),
                    trailing: Icon(Icons.add, color: AppColors.primary, size: 22.sp),
                    onTap: () async {
                      Get.back();
                      await controller.addAdminCategory(category.id);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _openForm(BuildContext context, {ShopCategory? category}) {
    Get.bottomSheet(
      _CategoryFormSheet(category: category),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _confirmDelete(ShopCategory category) {
    Get.dialog(
      AlertDialog(
        title: const Text('إزالة من المتجر', style: TextStyle(fontFamily: 'Expo Arabic')),
        content: Text(
          'هل تريد إزالة قسم "${category.nameAr}" من عرض متجرك؟\n\nسيظل القسم متاحاً في التطبيق لمتاجر أخرى.',
          style: const TextStyle(fontFamily: 'Expo Arabic'),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('إلغاء', style: TextStyle(fontFamily: 'Expo Arabic'))),
          TextButton(
            onPressed: () async {
              Get.back();
              await Get.find<ShopCatalogController>().removeCategory(category.id);
            },
            child: const Text('إزالة', style: TextStyle(fontFamily: 'Expo Arabic', color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  final ShopCategory category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          AppImage(
            path: category.imagePath,
            width: 52.w,
            height: 52.w,
            borderRadius: BorderRadius.circular(14.r),
            icon: Icons.category_outlined,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(category.nameAr, fontSize: 14.sp),
                SizedBox(height: 4.h),
                MyText(
                  category.isAdminLinked ? 'قسم إدارة' : '${category.productCount} منتج',
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
          if (!category.isAdminLinked)
            IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined)),
          IconButton(
            onPressed: onDelete,
            icon: Icon(Icons.delete_outline, color: AppColors.error, size: 22.sp),
          ),
        ],
      ),
    );
  }
}

class _CategoryFormSheet extends StatefulWidget {
  const _CategoryFormSheet({this.category});

  final ShopCategory? category;

  @override
  State<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<_CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  String? _selectedIconAsset;
  String? _iconError;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.category?.nameAr ?? '');
    final existing = widget.category?.imagePath;
    if (existing != null && CategoryPresetIcons.isAssetPath(existing)) {
      _selectedIconAsset = existing;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final isEdit = widget.category != null;
    if (!isEdit && _selectedIconAsset == null) {
      setState(() => _iconError = 'اختر أيقونة للقسم');
      return;
    }
    final ctrl = Get.find<ShopCatalogController>();
    if (isEdit) {
      await ctrl.updateCategory(
        widget.category!.copyWith(nameAr: _name.text.trim()),
        iconAssetPath: _selectedIconAsset,
      );
    } else {
      await ctrl.addCategory(
        nameAr: _name.text.trim(),
        iconAssetPath: _selectedIconAsset!,
      );
    }
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ShopCatalogController>();
    final isEdit = widget.category != null;

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              MyText(isEdit ? 'تعديل القسم' : 'إضافة قسم مخصص', fontSize: 17.sp),
              SizedBox(height: 16.h),
              CategoryIconPicker(
                selectedAssetPath: _selectedIconAsset,
                errorText: _iconError,
                onSelected: (assetPath) => setState(() {
                  _selectedIconAsset = assetPath;
                  _iconError = null;
                }),
              ),
              SizedBox(height: 16.h),
              AuthTextField(
                controller: _name,
                label: 'اسم القسم',
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'أدخل اسم القسم' : null,
              ),
              SizedBox(height: 20.h),
              Obx(
                () => ElevatedButton(
                  onPressed: ctrl.isSaving.value ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 50.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                  ),
                  child: MyText(isEdit ? 'حفظ التعديلات' : 'إضافة القسم', fontSize: 14.sp, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
