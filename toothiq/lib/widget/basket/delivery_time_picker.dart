import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../utils/app_colors.dart';

final _hours = List.generate(24, (i) => i);
final _minutes = List.generate(60, (i) => i);
const _quickTimes = [(8, 0), (12, 0), (16, 0), (20, 0)];

/// منتقي وقت توصيل مخصص — بديل عن Material time picker
class DeliveryTimePicker {
  DeliveryTimePicker._();

  static Future<TimeOfDay?> show(
    BuildContext context, {
    TimeOfDay? initialTime,
  }) {
    return showModalBottomSheet<TimeOfDay>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => DeliveryTimePickerSheet(
        initialTime: initialTime ?? const TimeOfDay(hour: 12, minute: 0),
      ),
    );
  }
}

class DeliveryTimePickerSheet extends StatefulWidget {
  final TimeOfDay initialTime;

  const DeliveryTimePickerSheet({super.key, required this.initialTime});

  @override
  State<DeliveryTimePickerSheet> createState() =>
      _DeliveryTimePickerSheetState();
}

class _DeliveryTimePickerSheetState extends State<DeliveryTimePickerSheet> {
  late FixedExtentScrollController _hourCtrl;
  late FixedExtentScrollController _minuteCtrl;
  late int _hour;
  late int _minute;

  @override
  void initState() {
    super.initState();
    _hour = widget.initialTime.hour;
    _minute = widget.initialTime.minute;
    _hourCtrl = FixedExtentScrollController(initialItem: _hour);
    _minuteCtrl = FixedExtentScrollController(initialItem: _minute);
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    super.dispose();
  }

  TimeOfDay get _selected => TimeOfDay(hour: _hour, minute: _minute);

  String get _formatted {
    final h = _hour.toString().padLeft(2, '0');
    final m = _minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  void _applyQuick(int h, int m) {
    setState(() {
      _hour = h;
      _minute = m;
    });
    _hourCtrl.animateToItem(
      h,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
    _minuteCtrl.animateToItem(
      m,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.productStore.withValues(alpha: 0.22),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PickerHeader(formattedTime: _formatted),
                  Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 8.h),
                    child: Column(
                      children: [
                        _WheelPickerRow(
                          hourController: _hourCtrl,
                          minuteController: _minuteCtrl,
                          onHourChanged: (v) => setState(() => _hour = v),
                          onMinuteChanged: (v) => setState(() => _minute = v),
                        ),
                        SizedBox(height: 18.h),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'أوقات سريعة',
                            style: TextStyle(
                              fontFamily: 'Expo Arabic',
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Wrap(
                          spacing: 8.w,
                          runSpacing: 8.h,
                          alignment: WrapAlignment.end,
                          children: _quickTimes.map((t) {
                            final selected =
                                _hour == t.$1 && _minute == t.$2;
                            final label =
                                '${t.$1.toString().padLeft(2, '0')}:${t.$2.toString().padLeft(2, '0')}';
                            return _QuickTimeChip(
                              label: label,
                              selected: selected,
                              onTap: () => _applyQuick(t.$1, t.$2),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  _PickerActions(
                    onCancel: () => Navigator.pop(context),
                    onConfirm: () => Navigator.pop(context, _selected),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerHeader extends StatelessWidget {
  final String formattedTime;

  const _PickerHeader({required this.formattedTime});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(22.w, 22.h, 22.w, 24.h),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppColors.productStore,
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 44.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 18.h),
          Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
                child: Icon(
                  Icons.schedule_rounded,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'وقت التوصيل',
                      style: TextStyle(
                        fontFamily: 'Expo Arabic',
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'اختر الوقت المناسب لك',
                      style: TextStyle(
                        fontFamily: 'Expo Arabic',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                formattedTime,
                style: TextStyle(
                  fontFamily: 'Expo Arabic',
                  fontSize: 32.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1.2,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WheelPickerRow extends StatelessWidget {
  final FixedExtentScrollController hourController;
  final FixedExtentScrollController minuteController;
  final ValueChanged<int> onHourChanged;
  final ValueChanged<int> onMinuteChanged;

  const _WheelPickerRow({
    required this.hourController,
    required this.minuteController,
    required this.onHourChanged,
    required this.onMinuteChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 52.h,
            margin: EdgeInsets.symmetric(horizontal: 8.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.productPriceBar,
                  AppColors.primaryLight,
                ],
              ),
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(
                color: AppColors.productStore.withValues(alpha: 0.25),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _TimeWheel(
                  controller: hourController,
                  items: _hours,
                  labelBuilder: (v) => v.toString().padLeft(2, '0'),
                  onChanged: onHourChanged,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: Text(
                  ':',
                  style: TextStyle(
                    fontFamily: 'Expo Arabic',
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.productStore,
                  ),
                ),
              ),
              Expanded(
                child: _TimeWheel(
                  controller: minuteController,
                  items: _minutes,
                  labelBuilder: (v) => v.toString().padLeft(2, '0'),
                  onChanged: onMinuteChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimeWheel extends StatelessWidget {
  final FixedExtentScrollController controller;
  final List<int> items;
  final String Function(int) labelBuilder;
  final ValueChanged<int> onChanged;

  const _TimeWheel({
    required this.controller,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: 44.h,
      diameterRatio: 1.6,
      perspective: 0.003,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: (index) => onChanged(items[index]),
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: items.length,
        builder: (context, index) {
          final selected = controller.selectedItem == index;
          return Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: TextStyle(
                fontFamily: 'Expo Arabic',
                fontSize: selected ? 26.sp : 18.sp,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                color: selected
                    ? AppColors.productTitle
                    : AppColors.textSecondary.withValues(alpha: 0.55),
                height: 1,
              ),
              child: Text(labelBuilder(items[index])),
            ),
          );
        },
      ),
    );
  }
}

class _QuickTimeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _QuickTimeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.productStore : AppColors.primaryLight,
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: selected
                  ? AppColors.productStore
                  : AppColors.productStore.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Expo Arabic',
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : AppColors.productTitle,
            ),
          ),
        ),
      ),
    );
  }
}

class _PickerActions extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const _PickerActions({
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 18.h),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.45),
        border: Border(
          top: BorderSide(
            color: AppColors.productStore.withValues(alpha: 0.12),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.productTitle,
                side: BorderSide(
                  color: AppColors.productStore.withValues(alpha: 0.35),
                ),
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28.r),
                ),
              ),
              child: Text(
                'إلغاء',
                style: TextStyle(
                  fontFamily: 'Expo Arabic',
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            flex: 2,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28.r),
                gradient: const LinearGradient(
                  colors: [
                    AppColors.productStore,
                    AppColors.primaryDark,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.productStore.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28.r),
                  ),
                ),
                child: Text(
                  'تأكيد الوقت',
                  style: TextStyle(
                    fontFamily: 'Expo Arabic',
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
