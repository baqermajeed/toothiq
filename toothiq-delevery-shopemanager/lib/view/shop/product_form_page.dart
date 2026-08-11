import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controller/shop_catalog_controller.dart';
import '../../controller/shop_products_controller.dart';
import '../../core/utils/expiry_date_utils.dart';
import '../../model/shop_product.dart';
import '../../utils/app_colors.dart';
import '../../widget/auth_text_field.dart';
import '../../widget/my_text.dart';
import '../../widget/scroll_date_picker_sheet.dart';
import '../../widget/shop/image_picker_box.dart';

class ProductFormPage extends StatefulWidget {
  const ProductFormPage({super.key, this.product});

  final ShopProduct? product;

  bool get isEdit => product != null;

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _stock;
  late final TextEditingController _origin;
  DateTime? _expiryDate;
  String? _imagePath;
  List<String> _gallery = [];
  String? _categoryId;
  String? _brandId;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _price = TextEditingController(text: p != null ? '${p.price}' : '');
    _stock = TextEditingController(text: p != null ? '${p.stock}' : '1');
    _origin = TextEditingController(text: p?.origin ?? '');
    _expiryDate = ExpiryDateUtils.parseToDateTime(p?.expiryDate);
    _imagePath = p?.imagePath ?? p?.primaryImage;
    _gallery = List<String>.from(p?.galleryPaths ?? []);
    _categoryId = p?.categoryId;
    _brandId = p?.brandId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<ShopCatalogController>().loadCatalog(force: true);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _stock.dispose();
    _origin.dispose();
    super.dispose();
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final picked = await ScrollDatePickerSheet.show(
      context: context,
      title: 'تاريخ الانتهاء',
      initialDate: _expiryDate ?? now,
      minimumDate: now,
      maximumDate: DateTime(now.year + 20),
      mode: CupertinoDatePickerMode.monthYear,
    );
    if (picked != null) {
      setState(() {
        _expiryDate = DateTime(picked.year, picked.month + 1, 0);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imagePath == null || _imagePath!.isEmpty) {
      Get.snackbar('تنبيه', 'أضف صورة رئيسية للمنتج');
      return;
    }

    final catalog = Get.find<ShopCatalogController>();
    final products = Get.find<ShopProductsController>();
    final category = catalog.categoryById(_categoryId);
    final brand = catalog.brandById(_brandId);

    final expiryDate = ExpiryDateUtils.fromDateTime(_expiryDate);
    final originRaw = _origin.text.trim();
    final origin = originRaw.isEmpty ? null : originRaw;

    bool saved;
    if (widget.isEdit) {
      saved = await products.updateProduct(
        widget.product!.copyWith(
          name: _name.text.trim(),
          description: _description.text.trim(),
          price: int.parse(_price.text.trim()),
          stock: int.parse(_stock.text.trim()),
          imagePath: _imagePath,
          galleryPaths: _gallery,
          categoryId: category?.id,
          categoryName: category?.nameAr,
          brandId: brand?.id,
          brandName: brand?.nameAr,
          expiryDate: expiryDate,
          clearExpiry: expiryDate == null,
          origin: origin,
          clearOrigin: origin == null,
        ),
      );
    } else {
      saved = await products.addProduct(
        name: _name.text.trim(),
        description: _description.text.trim(),
        price: int.parse(_price.text.trim()),
        stock: int.parse(_stock.text.trim()),
        imagePath: _imagePath,
        galleryPaths: _gallery,
        categoryId: category?.id,
        categoryName: category?.nameAr,
        brandId: brand?.id,
        brandName: brand?.nameAr,
        expiryDate: expiryDate,
        origin: origin,
      );
    }

    if (!saved) return;

    Get.back();
    Get.snackbar(
      'تم',
      widget.isEdit ? 'تم تحديث المنتج' : 'تمت إضافة المنتج',
      backgroundColor: AppColors.primary,
      colorText: Colors.white,
      margin: EdgeInsets.all(16.w),
      borderRadius: 12.r,
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = Get.find<ShopProductsController>();
    final catalog = Get.find<ShopCatalogController>();

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: MyText(
          widget.isEdit ? 'تعديل المنتج' : 'إضافة منتج',
          fontSize: 18.sp,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: Get.back,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            Center(
              child: ImagePickerBox(
                label: 'صورة المنتج الرئيسية',
                imagePath: _imagePath,
                size: 140,
                icon: Icons.medical_services_outlined,
                onPicked: (p) => setState(() => _imagePath = p),
              ),
            ),
            SizedBox(height: 16.h),
            GalleryImagePicker(
              images: _gallery,
              onChanged: (list) => setState(() => _gallery = list),
            ),
            SizedBox(height: 20.h),
            _FormSection(
              title: 'تفاصيل المنتج',
              icon: Icons.inventory_2_outlined,
              children: [
                AuthTextField(
                  controller: _name,
                  label: 'اسم المنتج',
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'أدخل اسم المنتج' : null,
                ),
                SizedBox(height: 14.h),
                AuthTextField(
                  controller: _description,
                  label: 'وصف المنتج',
                  maxLines: 4,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'أدخل الوصف' : null,
                ),
                SizedBox(height: 14.h),
                AuthTextField(
                  controller: _price,
                  label: 'السعر (د.ع)',
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'أدخل السعر';
                    if (int.tryParse(v.trim()) == null) return 'سعر غير صالح';
                    return null;
                  },
                ),
                SizedBox(height: 14.h),
                Row(
                  children: [
                    Expanded(
                      child: AuthTextField(
                        controller: _stock,
                        label: 'الكمية',
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'أدخل الكمية';
                          if (int.tryParse(v.trim()) == null) return 'كمية غير صالحة';
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _OptionalDateField(
                        label: 'تاريخ الانتهاء (اختياري)',
                        value: _expiryDate,
                        onTap: _pickExpiryDate,
                        onClear: _expiryDate == null
                            ? null
                            : () => setState(() => _expiryDate = null),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                AuthTextField(
                  controller: _origin,
                  label: 'المنشأ (اختياري)',
                  hint: 'مثال: ألمانيا، الصين، العراق',
                ),
              ],
            ),
            SizedBox(height: 16.h),
            _FormSection(
              title: 'التصنيف والبراند',
              icon: Icons.category_outlined,
              children: [
                Obx(() {
                  if (catalog.isLoading.value) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.h),
                      child: Center(
                        child: SizedBox(
                          width: 28.w,
                          height: 28.w,
                          child: const CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      ),
                    );
                  }

                  if (catalog.errorMessage.value.isNotEmpty) {
                    return Column(
                      children: [
                        MyText(
                          catalog.errorMessage.value,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.error,
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 10.h),
                        TextButton(
                          onPressed: () => catalog.loadCatalog(force: true),
                          child: MyText(
                            'إعادة المحاولة',
                            fontSize: 13.sp,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    );
                  }

                  final categories = catalog.categories;
                  final selectedCategory = _pickValidId(
                    _categoryId,
                    categories.map((c) => c.id),
                  );

                  return _DropdownField<String>(
                    label: 'القسم',
                    value: selectedCategory,
                    hint: categories.isEmpty
                        ? 'لا توجد أقسام متاحة'
                        : 'اختر القسم',
                    items: categories
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(
                              c.nameAr,
                              style: TextStyle(
                                fontFamily: 'Expo Arabic',
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: categories.isEmpty
                        ? null
                        : (v) => setState(() => _categoryId = v),
                  );
                }),
                SizedBox(height: 14.h),
                Obx(() {
                  if (catalog.isLoading.value) return const SizedBox.shrink();

                  final brands = catalog.brands;
                  final selectedBrand = _pickValidId(
                    _brandId,
                    brands.map((b) => b.id),
                  );

                  return _DropdownField<String>(
                    label: 'البراند',
                    value: selectedBrand,
                    hint: brands.isEmpty ? 'لا توجد براندات متاحة' : 'اختر البراند',
                    items: brands
                        .map(
                          (b) => DropdownMenuItem(
                            value: b.id,
                            child: Text(
                              b.nameAr,
                              style: TextStyle(
                                fontFamily: 'Expo Arabic',
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged:
                        brands.isEmpty ? null : (v) => setState(() => _brandId = v),
                  );
                }),
              ],
            ),
            SizedBox(height: 28.h),
            Obx(
              () => ElevatedButton(
                onPressed: products.isSaving.value ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 54.h),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                child: products.isSaving.value
                    ? SizedBox(
                        width: 22.w,
                        height: 22.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : MyText(
                        widget.isEdit ? 'حفظ التعديلات' : 'حفظ المنتج',
                        fontSize: 15.sp,
                        color: Colors.white,
                      ),
              ),
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  String? _pickValidId(String? value, Iterable<String> validIds) {
    if (value == null || value.isEmpty) return null;
    return validIds.contains(value) ? value : null;
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20.sp),
              SizedBox(width: 8.w),
              MyText(title, fontSize: 15.sp),
            ],
          ),
          SizedBox(height: 16.h),
          ...children,
        ],
      ),
    );
  }
}

class _OptionalDateField extends StatelessWidget {
  const _OptionalDateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppColors.pageBackground,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          suffixIcon: onClear == null
              ? Icon(Icons.calendar_today_outlined, size: 20.sp)
              : IconButton(
                  onPressed: onClear,
                  icon: Icon(Icons.close, size: 20.sp),
                  tooltip: 'مسح التاريخ',
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: const BorderSide(color: AppColors.cardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: const BorderSide(color: AppColors.cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
          ),
          labelStyle: TextStyle(
            fontFamily: 'Expo Arabic',
            fontSize: 13.sp,
            color: AppColors.textSecondary,
          ),
        ),
        child: MyText(
          value == null
              ? 'اختر التاريخ'
              : ExpiryDateUtils.formatForPicker(value!),
          fontSize: 14.sp,
          color: value == null ? AppColors.textSecondary : AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyText(label, fontSize: 13.sp, fontWeight: FontWeight.w600),
        SizedBox(height: 8.h),
        DropdownButtonFormField<T>(
          key: ValueKey<T?>(value),
          initialValue: value,
          items: items,
          onChanged: onChanged,
          isExpanded: true,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontFamily: 'Expo Arabic',
              fontSize: 13.sp,
              color: AppColors.textSecondary,
            ),
            filled: true,
            fillColor: AppColors.pageBackground,
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
          ),
          style: TextStyle(
            fontFamily: 'Expo Arabic',
            fontSize: 14.sp,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
