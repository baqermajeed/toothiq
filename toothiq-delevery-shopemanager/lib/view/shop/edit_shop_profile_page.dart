import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controller/shop_profile_controller.dart';
import '../../utils/app_colors.dart';
import '../../widget/auth_text_field.dart';
import '../../widget/my_text.dart';
import '../../widget/shop/image_picker_box.dart';

class EditShopProfilePage extends StatefulWidget {
  const EditShopProfilePage({super.key});

  @override
  State<EditShopProfilePage> createState() => _EditShopProfilePageState();
}

class _EditShopProfilePageState extends State<EditShopProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _address;
  late final TextEditingController _phone1;
  late final TextEditingController _phone2;
  String? _logoPath;

  @override
  void initState() {
    super.initState();
    final shop = Get.find<ShopProfileController>().profile.value;
    _name = TextEditingController(text: shop?.name ?? '');
    _description = TextEditingController(text: shop?.description ?? '');
    _address = TextEditingController(text: shop?.address ?? '');
    _phone1 = TextEditingController(text: shop?.phonePrimary ?? '');
    _phone2 = TextEditingController(text: shop?.phoneSecondary ?? '');
    _logoPath = shop?.logoPath;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _address.dispose();
    _phone1.dispose();
    _phone2.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = Get.find<ShopProfileController>();
    await controller.saveProfile(
      name: _name.text,
      description: _description.text,
      address: _address.text,
      phonePrimary: _phone1.text,
      phoneSecondary: _phone2.text,
      logoPath: _logoPath,
    );
    Get.back();
    Get.snackbar(
      'تم الحفظ',
      'تم تحديث بيانات المتجر بنجاح',
      backgroundColor: AppColors.primary,
      colorText: Colors.white,
      margin: EdgeInsets.all(16.w),
      borderRadius: 12.r,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ShopProfileController>();

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: MyText('بيانات المتجر', fontSize: 18.sp),
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
                label: 'شعار المتجر',
                imagePath: _logoPath,
                size: 110,
                shape: BoxShape.circle,
                icon: Icons.storefront_rounded,
                onPicked: (path) => setState(() => _logoPath = path),
              ),
            ),
            SizedBox(height: 24.h),
            _SectionCard(
              title: 'المعلومات الأساسية',
              icon: Icons.store_outlined,
              children: [
                AuthTextField(
                  controller: _name,
                  label: 'اسم المتجر',
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'أدخل اسم المتجر' : null,
                ),
                SizedBox(height: 14.h),
                AuthTextField(
                  controller: _description,
                  label: 'وصف المتجر',
                  maxLines: 4,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'أدخل وصف المتجر' : null,
                ),
                SizedBox(height: 14.h),
                AuthTextField(
                  controller: _address,
                  label: 'عنوان المتجر',
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'أدخل عنوان المتجر' : null,
                ),
              ],
            ),
            SizedBox(height: 16.h),
            _SectionCard(
              title: 'أرقام التواصل',
              icon: Icons.phone_outlined,
              children: [
                AuthTextField(
                  controller: _phone1,
                  label: 'رقم الهاتف الأساسي',
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'أدخل رقم الهاتف';
                    if (v.trim().length < 10) return 'رقم غير صالح';
                    return null;
                  },
                ),
                SizedBox(height: 14.h),
                AuthTextField(
                  controller: _phone2,
                  label: 'رقم هاتف إضافي (اختياري)',
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
            SizedBox(height: 28.h),
            Obx(
              () => ElevatedButton(
                onPressed: controller.isSaving.value ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 54.h),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                child: controller.isSaving.value
                    ? SizedBox(
                        width: 22.w,
                        height: 22.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : MyText('حفظ بيانات المتجر', fontSize: 15.sp, color: Colors.white),
              ),
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
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
