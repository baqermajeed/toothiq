import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../model/governorate_model.dart';
import '../../service_layer/services/governorate_service.dart';
import '../../utils/app_colors.dart';
import '../../view/map/map_pick_page.dart';
import '../common/app_toast.dart';
import '../my_text.dart';

class AddressFormResult {
  final String governorate;
  final String area;
  final String landmark;
  final double? lat;
  final double? lng;

  const AddressFormResult({
    required this.governorate,
    required this.area,
    required this.landmark,
    this.lat,
    this.lng,
  });
}

class AddressFormBottomSheet extends StatefulWidget {
  final bool isEdit;
  final String initialGovernorate;
  final String initialArea;
  final String initialLandmark;
  final double? initialLat;
  final double? initialLng;

  const AddressFormBottomSheet({
    super.key,
    this.isEdit = false,
    this.initialGovernorate = '',
    this.initialArea = '',
    this.initialLandmark = '',
    this.initialLat,
    this.initialLng,
  });

  static Future<AddressFormResult?> showAdd() {
    return _open(const AddressFormBottomSheet());
  }

  static Future<AddressFormResult?> showEdit({
    required String governorate,
    required String area,
    required String landmark,
    double? lat,
    double? lng,
  }) {
    return _open(
      AddressFormBottomSheet(
        isEdit: true,
        initialGovernorate: governorate,
        initialArea: area,
        initialLandmark: landmark,
        initialLat: lat,
        initialLng: lng,
      ),
    );
  }

  static Future<AddressFormResult?> _open(AddressFormBottomSheet sheet) {
    return Get.bottomSheet<AddressFormResult>(
      sheet,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
    );
  }

  @override
  State<AddressFormBottomSheet> createState() => _AddressFormBottomSheetState();
}

class _AddressFormBottomSheetState extends State<AddressFormBottomSheet> {
  final _governorateService = Get.find<GovernorateService>();

  final _governorates = <GovernorateModel>[].obs;
  final isLoadingGovernorates = true.obs;

  late String? _governorate;
  late final TextEditingController _areaController;
  late final TextEditingController _landmarkController;
  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    _governorate =
        widget.initialGovernorate.isEmpty ? null : widget.initialGovernorate;
    _areaController = TextEditingController(text: widget.initialArea);
    _landmarkController = TextEditingController(text: widget.initialLandmark);
    _lat = widget.initialLat;
    _lng = widget.initialLng;
    _loadGovernorates();
  }

  Future<void> _loadGovernorates() async {
    isLoadingGovernorates.value = true;
    try {
      final items = await _governorateService.fetchGovernorates();
      _governorates.assignAll(
        items.where((item) => item.nameAr.trim().isNotEmpty),
      );
    } catch (_) {
      _governorates.clear();
    } finally {
      isLoadingGovernorates.value = false;
    }
  }

  @override
  void dispose() {
    _areaController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboardHeight = media.viewInsets.bottom;
    final title = widget.isEdit ? 'تعديل العنوان' : 'أضافة عنوان جديد';
    final actionLabel = widget.isEdit ? 'تعديل العنوان' : 'أضافة العنوان';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboardHeight),
        child: Container(
          constraints: BoxConstraints(maxHeight: media.size.height * 0.88),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 12.h),
                Container(
                  width: 44.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.searchBorder,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: MyText(
                      title,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.productTitle,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 20.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        MyText(
                          'المحافظة',
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.productTitle,
                          textAlign: TextAlign.right,
                        ),
                        SizedBox(height: 10.h),
                        Obx(() {
                          if (isLoadingGovernorates.value) {
                            return SizedBox(
                              height: 54.h,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                ),
                              ),
                            );
                          }

                          return _AddressDropdownField(
                            value: _governorate,
                            hint: 'اختر المحافظة',
                            options: _governorates
                                .map((item) => item.nameAr)
                                .toList(growable: false),
                            onSelected: (value) {
                              setState(() => _governorate = value);
                            },
                          );
                        }),
                        SizedBox(height: 20.h),
                        MyText(
                          'المنطقة',
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.productTitle,
                          textAlign: TextAlign.right,
                        ),
                        SizedBox(height: 10.h),
                        _AddressTextField(
                          controller: _areaController,
                          hintText: 'أكتب اسم المنطقة',
                        ),
                        SizedBox(height: 20.h),
                        MyText(
                          'أقرب نقطة دالة',
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.productTitle,
                          textAlign: TextAlign.right,
                        ),
                        SizedBox(height: 10.h),
                        _AddressTextField(
                          controller: _landmarkController,
                          hintText: 'أكتب أقرب نقطة دالة',
                        ),
                        SizedBox(height: 20.h),
                        MyText(
                          'الموقع على الخريطة',
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.productTitle,
                          textAlign: TextAlign.right,
                        ),
                        SizedBox(height: 10.h),
                        Material(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(18.r),
                          child: InkWell(
                            onTap: _pickOnMap,
                            borderRadius: BorderRadius.circular(18.r),
                            child: Container(
                              height: 120.h,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18.r),
                                border: Border.all(
                                  color: _lat != null && _lng != null
                                      ? AppColors.primary
                                      : AppColors.searchBorder,
                                  width: _lat != null && _lng != null ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.map_rounded,
                                    size: 36.sp,
                                    color: AppColors.primaryDark,
                                  ),
                                  SizedBox(height: 8.h),
                                  MyText(
                                    _lat != null && _lng != null
                                        ? 'تم تحديد الموقع — اضغط للتعديل'
                                        : 'اضغط لاختيار الموقع على الخريطة',
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.productTitle,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: Material(
                          color: AppColors.productStore,
                          elevation: 4,
                          shadowColor: Colors.black.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(16.r),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: _save,
                            child: SizedBox(
                              height: 52.h,
                              child: Center(
                                child: MyText(
                                  actionLabel,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      TextButton(
                        onPressed: Get.back,
                        style: TextButton.styleFrom(
                          minimumSize: Size(72.w, 52.h),
                          padding: EdgeInsets.symmetric(horizontal: 12.w),
                        ),
                        child: MyText(
                          'الغاء',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.productTitle,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickOnMap() async {
    final result = await MapPickPage.open(lat: _lat, lng: _lng);
    if (result == null) return;
    setState(() {
      _lat = result.lat;
      _lng = result.lng;
    });
  }

  void _save() {
    final governorate = _governorate?.trim() ?? '';
    final area = _areaController.text.trim();
    final landmark = _landmarkController.text.trim();

    if (governorate.isEmpty || area.isEmpty || landmark.isEmpty) return;
    if (_lat == null || _lng == null) {
      AppToast.show(
        'الموقع مطلوب',
        'يرجى اختيار الموقع على الخريطة قبل الحفظ',
        type: ToastType.warning,
      );
      return;
    }

    Get.back(
      result: AddressFormResult(
        governorate: governorate,
        area: area,
        landmark: landmark,
        lat: _lat,
        lng: _lng,
      ),
    );
  }
}

class _AddressDropdownField extends StatelessWidget {
  final String? value;
  final String hint;
  final List<String> options;
  final ValueChanged<String> onSelected;

  const _AddressDropdownField({
    required this.value,
    required this.hint,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = (value ?? '').isNotEmpty;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18.r),
      child: InkWell(
        onTap: () => _showPicker(context),
        borderRadius: BorderRadius.circular(18.r),
        child: Ink(
          height: 54.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: AppColors.searchBorder),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: Row(
              children: [
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 22.sp,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    hasValue ? value! : hint,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Expo Arabic',
                      fontSize: 14.sp,
                      fontWeight:
                          hasValue ? FontWeight.w600 : FontWeight.w500,
                      color: hasValue
                          ? AppColors.productTitle
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showPicker(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              itemCount: options.length,
              separatorBuilder: (_, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final option = options[index];
                final isSelected = option == value;
                return ListTile(
                  title: Text(
                    option,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: 'Expo Arabic',
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w500,
                      color: AppColors.productTitle,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_rounded, color: AppColors.productStore)
                      : null,
                  onTap: () => Navigator.pop(context, option),
                );
              },
            ),
          ),
        );
      },
    );

    if (selected != null) onSelected(selected);
  }
}

class _AddressTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;

  const _AddressTextField({
    required this.controller,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.searchBorder),
      ),
      alignment: Alignment.centerRight,
      child: TextField(
        controller: controller,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontFamily: 'Expo Arabic',
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.productTitle,
        ),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: TextStyle(
            fontFamily: 'Expo Arabic',
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
