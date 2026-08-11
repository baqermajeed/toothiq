import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../model/search_filter_model.dart';
import '../../utils/app_colors.dart';
import '../../view/search/search_results_page.dart';
import '../../widget/my_text.dart';

class SearchFilterPage extends StatefulWidget {
  final SearchFilterModel initialFilter;
  final String? searchQuery;
  final bool navigateToResultsOnApply;

  const SearchFilterPage({
    super.key,
    required this.initialFilter,
    this.searchQuery,
    this.navigateToResultsOnApply = false,
  });

  static Future<SearchFilterModel?> open({
    required SearchFilterModel initialFilter,
    String? searchQuery,
    bool navigateToResultsOnApply = false,
  }) async {
    final result = await Get.to<SearchFilterModel>(
      () => SearchFilterPage(
        initialFilter: initialFilter,
        searchQuery: searchQuery,
        navigateToResultsOnApply: navigateToResultsOnApply,
      ),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 250),
    );
    return result;
  }

  @override
  State<SearchFilterPage> createState() => _SearchFilterPageState();
}

class _SearchFilterPageState extends State<SearchFilterPage> {
  late RangeValues _priceRange;
  late String? _selectedBrand;
  late String? _selectedDepartment;
  late DateTime? _expiryDate;
  bool _brandExpanded = true;
  bool _departmentExpanded = true;

  @override
  void initState() {
    super.initState();
    final filter = widget.initialFilter;
    _priceRange = RangeValues(filter.minPrice, filter.maxPrice);
    _selectedBrand = filter.brand;
    _selectedDepartment = filter.department ?? filter.category;
    _expiryDate = filter.expiryDate;
  }

  SearchFilterModel _buildResult() {
    return widget.initialFilter.copyWith(
      minPrice: _priceRange.start,
      maxPrice: _priceRange.end,
      brand: _selectedBrand,
      clearBrand: _selectedBrand == null,
      department: _selectedDepartment,
      clearDepartment: _selectedDepartment == null,
      category: _selectedDepartment,
      clearCategory: _selectedDepartment == null,
      expiryDate: _expiryDate,
      clearExpiryDate: _expiryDate == null,
    );
  }

  void _applyAndClose() {
    final result = _buildResult();
    if (widget.navigateToResultsOnApply) {
      Get.back();
      final query = widget.searchQuery?.trim();
      SearchResultsPage.open(
        query: query?.isEmpty ?? true ? null : query,
        filter: result,
        replace: true,
      );
      return;
    }
    Get.back(result: result);
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime(2026),
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
      locale: const Locale('ar'),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(primary: AppColors.productStore),
            ),
            child: child!,
          ),
        );
      },
    );
    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  String _formatPrice(double value) {
    return widget.initialFilter.formatPrice(value);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.filterPageBackground,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FilterHeader(onClose: () => Get.back()),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _PriceSection(
                        priceRange: _priceRange,
                        formatPrice: _formatPrice,
                        onChanged: (values) =>
                            setState(() => _priceRange = values),
                      ),
                      SizedBox(height: 28.h),
                      _CollapsibleChipSection(
                        title: 'حسب البراند',
                        expanded: _brandExpanded,
                        options: SearchFilterModel.brandOptions,
                        selected: _selectedBrand,
                        onToggle: () =>
                            setState(() => _brandExpanded = !_brandExpanded),
                        onSelect: (value) =>
                            setState(() => _selectedBrand = value),
                      ),
                      SizedBox(height: 24.h),
                      _CollapsibleChipSection(
                        title: 'حسب القسم',
                        expanded: _departmentExpanded,
                        options: SearchFilterModel.departmentOptions,
                        selected: _selectedDepartment,
                        onToggle: () => setState(
                          () => _departmentExpanded = !_departmentExpanded,
                        ),
                        onSelect: (value) =>
                            setState(() => _selectedDepartment = value),
                      ),
                      SizedBox(height: 24.h),
                      _ExpiryDateSection(
                        label: _expiryDate == null
                            ? '2026 / 00 / 00'
                            : widget.initialFilter.copyWith(
                                expiryDate: _expiryDate,
                              ).expiryDateLabel,
                        onTap: _pickExpiryDate,
                      ),
                    ],
                  ),
                ),
              ),
              _FilterBottomBar(
                onBack: () => Get.back(),
                onApply: _applyAndClose,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterHeader extends StatelessWidget {
  final VoidCallback onClose;

  const _FilterHeader({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 4.h),
      child: Stack(
        alignment: Alignment.center,
        children: [
          MyText(
            'فلترة نتائج البحث',
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.productTitle,
            textAlign: TextAlign.center,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onClose,
              icon: Icon(
                Icons.close_rounded,
                color: AppColors.productTitle,
                size: 26.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceSection extends StatelessWidget {
  final RangeValues priceRange;
  final String Function(double) formatPrice;
  final ValueChanged<RangeValues> onChanged;

  const _PriceSection({
    required this.priceRange,
    required this.formatPrice,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MyText(
          'حسب السعر',
          fontSize: 16.sp,
          fontWeight: FontWeight.w800,
          color: AppColors.productTitle,
          textAlign: TextAlign.right,
        ),
        SizedBox(height: 16.h),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 6.h,
            rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
            rangeThumbShape: RoundRangeSliderThumbShape(
              enabledThumbRadius: 12.r,
            ),
            overlayShape: RoundSliderOverlayShape(overlayRadius: 18.r),
            inactiveTrackColor: AppColors.filterSliderTrack,
            activeTrackColor: AppColors.filterSliderActive,
            thumbColor: AppColors.productStore,
            overlayColor: AppColors.productStore.withValues(alpha: 0.12),
          ),
          child: RangeSlider(
            values: priceRange,
            min: SearchFilterModel.priceSliderMin,
            max: SearchFilterModel.priceSliderMax,
            divisions: 18,
            onChanged: onChanged,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MyText(
                formatPrice(priceRange.end),
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.productTitle,
              ),
              MyText(
                formatPrice(priceRange.start),
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.productTitle,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CollapsibleChipSection extends StatelessWidget {
  final String title;
  final bool expanded;
  final List<String> options;
  final String? selected;
  final VoidCallback onToggle;
  final ValueChanged<String?> onSelect;

  const _CollapsibleChipSection({
    required this.title,
    required this.expanded,
    required this.options,
    required this.selected,
    required this.onToggle,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: onToggle,
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              Icon(
                expanded
                    ? Icons.keyboard_arrow_down_rounded
                    : Icons.keyboard_arrow_up_rounded,
                color: AppColors.productTitle,
                size: 24.sp,
              ),
              Expanded(
                child: MyText(
                  title,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.productTitle,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        if (expanded) ...[
          SizedBox(height: 14.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: options.map((option) {
              final isAll = option == 'الكل';
              final isSelected =
                  isAll ? selected == null : selected == option;
              return _FilterChip(
                label: option,
                isSelected: isSelected,
                onTap: () => onSelect(isAll ? null : option),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.productStore : Colors.white,
      borderRadius: BorderRadius.circular(24.r),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: isSelected
                  ? AppColors.productStore
                  : AppColors.searchBorder,
            ),
          ),
          child: MyText(
            label,
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.productTitle,
          ),
        ),
      ),
    );
  }
}

class _ExpiryDateSection extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ExpiryDateSection({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MyText(
          'حسب تاريخ الأنتهاء',
          fontSize: 16.sp,
          fontWeight: FontWeight.w800,
          color: AppColors.productTitle,
          textAlign: TextAlign.right,
        ),
        SizedBox(height: 14.h),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 52.h,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppColors.searchBorder),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  color: AppColors.productStore,
                  size: 20.sp,
                ),
                Expanded(
                  child: MyText(
                    label,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    textAlign: TextAlign.left,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterBottomBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onApply;

  const _FilterBottomBar({
    required this.onBack,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 16.h),
      decoration: BoxDecoration(
        color: AppColors.filterPageBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52.h,
                child: ElevatedButton(
                  onPressed: onApply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.productStore,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28.r),
                    ),
                  ),
                  child: MyText(
                    'فلترة النتائج',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: SizedBox(
                height: 52.h,
                child: ElevatedButton(
                  onPressed: onBack,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.editProfileActionsBg,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28.r),
                    ),
                  ),
                  child: MyText(
                    'عودة',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.productStore,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
