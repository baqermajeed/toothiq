import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controller/search_controller.dart';
import '../../model/search_filter_model.dart';
import '../../utils/app_colors.dart';
import '../my_text.dart';
import '../primary_button.dart';

class ProductSearchFilterSheet extends StatelessWidget {
  final SearchFilterModel initialFilter;

  const ProductSearchFilterSheet({
    super.key,
    required this.initialFilter,
  });

  static Future<SearchFilterModel?> show({
    required SearchFilterModel initialFilter,
  }) {
    return Get.bottomSheet<SearchFilterModel>(
      ProductSearchFilterSheet(initialFilter: initialFilter),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: _ProductSearchFilterBody(initialFilter: initialFilter),
    );
  }
}

class _ProductSearchFilterBody extends StatefulWidget {
  final SearchFilterModel initialFilter;

  const _ProductSearchFilterBody({required this.initialFilter});

  @override
  State<_ProductSearchFilterBody> createState() =>
      _ProductSearchFilterBodyState();
}

class _ProductSearchFilterBodyState extends State<_ProductSearchFilterBody> {
  late String? selectedCategory;
  late SearchSortOption selectedSort;
  late SearchResultType selectedType;
  late double? minRating;

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.initialFilter.category;
    selectedSort = widget.initialFilter.sort;
    selectedType = widget.initialFilter.resultType;
    minRating = widget.initialFilter.minStoreRating;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.indicatorInactive,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            MyText(
              'فلترة النتائج',
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.h),
            _SectionLabel(title: 'نوع النتائج'),
            SizedBox(height: 10.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: SearchResultType.values.map((type) {
                return _ChoiceChip(
                  label: type.label,
                  isSelected: selectedType == type,
                  onTap: () => setState(() => selectedType = type),
                );
              }).toList(),
            ),
            SizedBox(height: 18.h),
            _SectionLabel(title: 'القسم'),
            SizedBox(height: 10.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: SearchProductsController.categoryOptions.map((category) {
                final isAll = category == 'الكل';
                final isSelected = isAll
                    ? selectedCategory == null
                    : selectedCategory == category;
                return _ChoiceChip(
                  label: category,
                  isSelected: isSelected,
                  onTap: () => setState(() {
                    selectedCategory = isAll ? null : category;
                  }),
                );
              }).toList(),
            ),
            SizedBox(height: 18.h),
            _SectionLabel(title: 'ترتيب المنتجات'),
            SizedBox(height: 10.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: SearchSortOption.values.map((sort) {
                return _ChoiceChip(
                  label: sort.label,
                  isSelected: selectedSort == sort,
                  onTap: () => setState(() => selectedSort = sort),
                );
              }).toList(),
            ),
            SizedBox(height: 18.h),
            _SectionLabel(title: 'الحد الأدنى لتقييم المتجر'),
            SizedBox(height: 10.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                _ChoiceChip(
                  label: 'الكل',
                  isSelected: minRating == null,
                  onTap: () => setState(() => minRating = null),
                ),
                ...[3.0, 4.0, 4.5].map(
                  (rating) => _ChoiceChip(
                    label: '$rating+',
                    isSelected: minRating == rating,
                    onTap: () => setState(() => minRating = rating),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Get.back(
                        result: const SearchFilterModel(),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size.fromHeight(48.h),
                      side: const BorderSide(color: AppColors.searchBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    child: MyText(
                      'مسح الكل',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  flex: 2,
                  child: PrimaryButton(
                    label: 'تطبيق الفلتر',
                    onPressed: () {
                      Get.back(
                        result: SearchFilterModel(
                          category: selectedCategory,
                          sort: selectedSort,
                          resultType: selectedType,
                          minStoreRating: minRating,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;

  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return MyText(
      title,
      fontSize: 15.sp,
      fontWeight: FontWeight.w800,
      color: AppColors.productTitle,
      textAlign: TextAlign.right,
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChoiceChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.editProfileActionsBg : Colors.white,
      borderRadius: BorderRadius.circular(14.r),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: isSelected
                  ? AppColors.editProfilePrimary
                  : AppColors.settingsCardBorder,
            ),
          ),
          child: MyText(
            label,
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: isSelected
                ? AppColors.editProfilePrimary
                : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
