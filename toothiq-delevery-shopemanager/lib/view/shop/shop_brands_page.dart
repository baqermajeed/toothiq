import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controller/shop_catalog_controller.dart';
import '../../core/constants/brand_preset_icons.dart';
import '../../model/shop_brand.dart';
import '../../utils/app_colors.dart';
import '../../widget/auth_text_field.dart';
import '../../widget/my_text.dart';
import '../../widget/shop/app_image.dart';
import '../../widget/shop/brand_icon_picker.dart';

class ShopBrandsPage extends StatelessWidget {
  const ShopBrandsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ShopCatalogController>();

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: MyText('براندات المتجر', fontSize: 18.sp),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: Get.back,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: MyText('براند جديد', fontSize: 13.sp, color: Colors.white),
      ),
      body: Obx(() {
        final list = controller.brands;
        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_outlined, size: 56.sp, color: AppColors.textLight),
                SizedBox(height: 12.h),
                MyText(
                  'لا توجد براندات بعد',
                  fontSize: 15.sp,
                  color: AppColors.textSecondary,
                ),
                SizedBox(height: 6.h),
                MyText(
                  'أضف البراندات المتوفر لديك',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textLight,
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 88.h),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12.h,
            crossAxisSpacing: 12.w,
            childAspectRatio: 0.95,
          ),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final brand = list[index];
            return _BrandCard(
              brand: brand,
              onEdit: () => _openForm(context, brand: brand),
              onDelete: () => _confirmDelete(brand),
            );
          },
        );
      }),
    );
  }

  void _openForm(BuildContext context, {ShopBrand? brand}) {
    Get.bottomSheet(
      _BrandFormSheet(brand: brand),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _confirmDelete(ShopBrand brand) {
    Get.dialog(
      AlertDialog(
        title: const Text('حذف البراند', style: TextStyle(fontFamily: 'Expo Arabic')),
        content: Text(
          'هل تريد حذف براند "${brand.nameAr}"؟',
          style: const TextStyle(fontFamily: 'Expo Arabic'),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('إلغاء', style: TextStyle(fontFamily: 'Expo Arabic'))),
          TextButton(
            onPressed: () {
              Get.find<ShopCatalogController>().removeBrand(brand.id);
              Get.back();
            },
            child: const Text('حذف', style: TextStyle(fontFamily: 'Expo Arabic', color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _BrandCard extends StatelessWidget {
  const _BrandCard({
    required this.brand,
    required this.onEdit,
    required this.onDelete,
  });

  final ShopBrand brand;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(color: AppColors.shadow, blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          AppImage(
            path: brand.logoPath,
            width: 64.w,
            height: 64.w,
            borderRadius: BorderRadius.circular(16.r),
            icon: Icons.verified_outlined,
          ),
          SizedBox(height: 10.h),
          MyText(brand.nameAr, fontSize: 13.sp, maxLines: 2, textAlign: TextAlign.center),
          SizedBox(height: 4.h),
          MyText(
            '${brand.productCount} منتج',
            fontSize: 10.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(onPressed: onEdit, icon: Icon(Icons.edit_outlined, size: 20.sp)),
              IconButton(
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline, color: AppColors.error, size: 20.sp),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BrandFormSheet extends StatefulWidget {
  const _BrandFormSheet({this.brand});

  final ShopBrand? brand;

  @override
  State<_BrandFormSheet> createState() => _BrandFormSheetState();
}

class _BrandFormSheetState extends State<_BrandFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  String? _logoPath;
  String? _iconError;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.brand?.nameAr ?? '');
    final existing = widget.brand?.logoPath;
    _logoPath = BrandPresetIcons.isAssetPath(existing) ? existing : null;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _iconError = null);
    if (!_formKey.currentState!.validate()) return;
    if (!BrandPresetIcons.isAssetPath(_logoPath)) {
      setState(() => _iconError = 'اختر أيقونة للبراند');
      return;
    }
    final ctrl = Get.find<ShopCatalogController>();
    if (widget.brand != null) {
      await ctrl.updateBrand(
        widget.brand!.copyWith(nameAr: _name.text.trim(), logoPath: _logoPath),
      );
    } else {
      await ctrl.addBrand(nameAr: _name.text, logoPath: _logoPath);
    }
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ShopCatalogController>();
    final isEdit = widget.brand != null;

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
              MyText(isEdit ? 'تعديل البراند' : 'إضافة براند جديد', fontSize: 17.sp),
              SizedBox(height: 20.h),
              BrandIconPicker(
                selectedAssetPath: _logoPath,
                errorText: _iconError,
                onSelected: (path) => setState(() {
                  _logoPath = path;
                  _iconError = null;
                }),
              ),
              SizedBox(height: 16.h),
              AuthTextField(
                controller: _name,
                label: 'اسم البراند',
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'أدخل اسم البراند' : null,
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
                  child: MyText(isEdit ? 'حفظ التعديلات' : 'إضافة البراند', fontSize: 14.sp, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
