import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../model/search_filter_model.dart';
import '../../model/search_filter_options_model.dart';
import '../../service_layer/services/search_filter_options_service.dart';
import '../../utils/app_colors.dart';
import '../../view/search/search_results_page.dart';
import '../../widget/common/async_state_widgets.dart';
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
  final _optionsService = Get.find<SearchFilterOptionsService>();

  SearchFilterOptionsModel? _options;
  String? _loadError;
  bool _loading = true;

  late RangeValues _priceRange;
  String? _selectedBrandId;
  String? _selectedBrandName;
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  DateTime? _expiryDate;
  bool _brandExpanded = true;
  bool _departmentExpanded = true;

  @override
  void initState() {
    super.initState();
    _initFromFilter(widget.initialFilter);
    _loadOptions();
  }

  void _initFromFilter(SearchFilterModel filter) {
    _selectedBrandId = filter.brandId;
    _selectedBrandName = filter.brand;
    _selectedCategoryId = filter.categoryId;
    _selectedCategoryName = filter.department ?? filter.category;
    _expiryDate = filter.expiryDate;
    _priceRange = RangeValues(filter.minPrice, filter.maxPrice);
  }

  Future<void> _loadOptions() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final options = await _optionsService.fetch();
      if (!mounted) return;

      final filter = widget.initialFilter;
      final min = options.priceMin;
      final max = options.priceMax;

      setState(() {
        _options = options;
        _priceRange = RangeValues(
          _clampPrice(filter.minPrice, min, max),
          _clampPrice(filter.maxPrice, min, max),
        );

        if (_selectedCategoryId != null &&
            !options.categories.any((c) => c.id == _selectedCategoryId)) {
          _selectedCategoryId = null;
          _selectedCategoryName = null;
        }
        if (_selectedBrandId != null &&
            !options.brands.any((b) => b.id == _selectedBrandId)) {
          _selectedBrandId = null;
          _selectedBrandName = null;
        }

        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _options = SearchFilterOptionsModel.fallback();
        _loadError = 'تعذر تحميل خيارات الفلترة';
        _loading = false;
      });
    }
  }

  double _clampPrice(double value, double min, double max) {
    if (max <= min) return min;
    return value.clamp(min, max);
  }

  SearchFilterModel _buildResult() {
    final options = _options ?? SearchFilterOptionsModel.fallback();
    return widget.initialFilter.copyWith(
      minPrice: _priceRange.start,
      maxPrice: _priceRange.end,
      catalogMinPrice: options.priceMin,
      catalogMaxPrice: options.priceMax,
      brandId: _selectedBrandId,
      brand: _selectedBrandName,
      clearBrand: _selectedBrandId == null,
      clearBrandId: _selectedBrandId == null,
      categoryId: _selectedCategoryId,
      category: _selectedCategoryName,
      department: _selectedCategoryName,
      clearCategory: _selectedCategoryId == null,
      clearCategoryId: _selectedCategoryId == null,
      clearDepartment: _selectedCategoryId == null,
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

  int? _priceDivisions(SearchFilterOptionsModel options) {
    final span = (options.priceMax - options.priceMin).round();
    if (span <= 0) return null;
    if (span <= 20) return span;
    if (span <= 200) return (span / 10).round();
    return (span / 1000).round().clamp(10, 100);
  }

  @override
  Widget build(BuildContext context) {
    final options = _options ?? SearchFilterOptionsModel.fallback();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.filterPageBackground,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FilterHeader(onClose: () => Get.back()),
              if (_loadError != null)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: MyText(
                    _loadError!,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.settingsDelete,
                    textAlign: TextAlign.center,
                  ),
                ),
              Expanded(
                child: _loading
                    ? const AppLoadingState()
                    : SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _PriceSection(
                              priceRange: _priceRange,
                              minPrice: options.priceMin,
                              maxPrice: options.priceMax,
                              divisions: _priceDivisions(options),
                              formatPrice: _formatPrice,
                              onChanged: (values) =>
                                  setState(() => _priceRange = values),
                            ),
                            SizedBox(height: 28.h),
                            _CollapsibleChipSection(
                              title: 'حسب البراند',
                              expanded: _brandExpanded,
                              emptyLabel: 'لا توجد براندات متاحة',
                              options: options.brands
                                  .map(
                                    (brand) => _FilterChipOption(
                                      id: brand.id,
                                      label: brand.name,
                                    ),
                                  )
                                  .toList(),
                              selectedId: _selectedBrandId,
                              onToggle: () => setState(
                                () => _brandExpanded = !_brandExpanded,
                              ),
                              onSelect: (option) => setState(() {
                                _selectedBrandId = option?.id;
                                _selectedBrandName = option?.label;
                              }),
                            ),
                            SizedBox(height: 24.h),
                            _CollapsibleChipSection(
                              title: 'حسب القسم',
                              expanded: _departmentExpanded,
                              emptyLabel: 'لا توجد أقسام متاحة',
                              options: options.categories
                                  .map(
                                    (category) => _FilterChipOption(
                                      id: category.id,
                                      label: category.nameAr,
                                    ),
                                  )
                                  .toList(),
                              selectedId: _selectedCategoryId,
                              onToggle: () => setState(
                                () => _departmentExpanded = !_departmentExpanded,
                              ),
                              onSelect: (option) => setState(() {
                                _selectedCategoryId = option?.id;
                                _selectedCategoryName = option?.label;
                              }),
                            ),
                            SizedBox(height: 24.h),
                            _ExpiryDateSection(
                              label: _expiryDate == null
                                  ? '2026 / 00 / 00'
                                  : widget.initialFilter
                                        .copyWith(expiryDate: _expiryDate)
                                        .expiryDateLabel,
                              onTap: _pickExpiryDate,
                            ),
                          ],
                        ),
                      ),
              ),
              _FilterBottomBar(
                onBack: () => Get.back(),
                onApply: _loading ? null : _applyAndClose,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChipOption {
  final String id;
  final String label;

  const _FilterChipOption({required this.id, required this.label});
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
  final double minPrice;
  final double maxPrice;
  final int? divisions;
  final String Function(double) formatPrice;
  final ValueChanged<RangeValues> onChanged;

  const _PriceSection({
    required this.priceRange,
    required this.minPrice,
    required this.maxPrice,
    required this.divisions,
    required this.formatPrice,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final sliderEnabled = maxPrice > minPrice;

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
            min: minPrice,
            max: maxPrice,
            divisions: divisions,
            onChanged: sliderEnabled ? onChanged : null,
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
  final String emptyLabel;
  final List<_FilterChipOption> options;
  final String? selectedId;
  final VoidCallback onToggle;
  final ValueChanged<_FilterChipOption?> onSelect;

  const _CollapsibleChipSection({
    required this.title,
    required this.expanded,
    required this.emptyLabel,
    required this.options,
    required this.selectedId,
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
          if (options.isEmpty)
            MyText(
              emptyLabel,
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              textAlign: TextAlign.right,
            )
          else
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                _FilterChip(
                  label: 'الكل',
                  isSelected: selectedId == null,
                  onTap: () => onSelect(null),
                ),
                ...options.map(
                  (option) => _FilterChip(
                    label: option.label,
                    isSelected: selectedId == option.id,
                    onTap: () => onSelect(option),
                  ),
                ),
              ],
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
  final VoidCallback? onApply;

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
                    disabledBackgroundColor: AppColors.productStore.withValues(
                      alpha: 0.5,
                    ),
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
