import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../controller/driver_orders_controller.dart';
import '../../model/partner_order.dart';
import '../../utils/app_colors.dart';
import '../my_text.dart';

class DriverOrderCard extends StatelessWidget {
  const DriverOrderCard({
    super.key,
    required this.order,
    required this.tab,
    required this.isPickedUp,
    this.canDeliver = false,
    this.onAccept,
    this.onPickup,
    this.onDeliver,
    this.onDetails,
  });

  final PartnerOrder order;
  final DriverOrderTab tab;
  final bool isPickedUp;
  final bool canDeliver;
  final VoidCallback? onAccept;
  final VoidCallback? onPickup;
  final VoidCallback? onDeliver;
  final VoidCallback? onDetails;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 16.r,
            offset: Offset(0, 4.h),
          ),
        ],
        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StatusHeader(status: order.status),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        Icons.storefront_rounded,
                        size: 18.sp,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MyText(
                            order.shopName,
                            fontSize: 15.sp,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2.h),
                          MyText(
                            'طلب #${order.orderNumber}',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                _FinancialRow(
                  label: 'استلم من الزبون',
                  value: order.formattedTotal,
                  background: AppColors.pageBackground,
                ),
                SizedBox(height: 8.h),
                _FinancialRow(
                  label: 'أجرة منطقة التوصيل',
                  subtitle: 'مستحقاتك من أجرة المنطقة',
                  value: order.formattedDeliveryFee,
                  background: const Color(0xFFE8F8EF),
                  borderColor: AppColors.success.withValues(alpha: 0.35),
                  valueColor: AppColors.success,
                  icon: Icons.payments_outlined,
                ),
                SizedBox(height: 8.h),
                _FinancialRow(
                  label: 'أعطِ للمتجر (تسديد مباشر)',
                  value: order.formattedShopAmount,
                  background: AppColors.pageBackground,
                ),
                SizedBox(height: 12.h),
                Wrap(
                  spacing: 6.w,
                  runSpacing: 6.h,
                  children: [
                    _MetaChip(label: 'ID: ${order.id}'),
                    _MetaChip(label: 'أجرة المنطقة: ${order.formattedDeliveryFee}'),
                    _MetaChip(label: '${order.itemCount} منتجات'),
                  ],
                ),
                SizedBox(height: 8.h),
                _MetaChip(
                  label: 'تاريخ الطلب: ${order.formattedCreatedAt}',
                  fullWidth: true,
                ),
                SizedBox(height: 14.h),
                OutlinedButton.icon(
                  onPressed: onDetails,
                  icon: Icon(Icons.receipt_long_outlined, size: 18.sp),
                  label: MyText(
                    'تفاصيل الطلب',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(double.infinity, 44.h),
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.cardBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
                SizedBox(height: 14.h),
                _ContactRow(
                  icon: Icons.store_mall_directory_outlined,
                  title: order.shopName,
                  subtitle: order.shopId != null
                      ? 'رقم المتجر: ${order.shopId}'
                      : order.shopAddress,
                  phone: order.shopPhone,
                ),
                SizedBox(height: 10.h),
                _ContactRow(
                  icon: Icons.person_outline_rounded,
                  title: order.customerName,
                  subtitle: order.customerPhone,
                  phone: order.customerPhone,
                ),
                SizedBox(height: 14.h),
                _buildActions(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    switch (tab) {
      case DriverOrderTab.pending:
        return _PrimaryActionButton(
          label: 'قبول الطلب',
          icon: Icons.check_circle_outline_rounded,
          onPressed: onAccept,
        );
      case DriverOrderTab.inProgress:
        return _PrimaryActionButton(
          label: 'الاستلام',
          icon: Icons.inventory_2_outlined,
          onPressed: onPickup,
        );
      case DriverOrderTab.pickedUp:
        return _PrimaryActionButton(
          label: 'التوصيل',
          icon: Icons.location_on_outlined,
          onPressed: onDeliver,
        );
      case DriverOrderTab.finished:
        return const SizedBox.shrink();
    }
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.status});

  final PartnerOrderStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            status.textColor,
            status.textColor.withValues(alpha: 0.85),
          ],
        ),
      ),
      child: MyText(
        status.label,
        fontSize: 13.sp,
        color: Colors.white,
        textAlign: TextAlign.end,
      ),
    );
  }
}

class _FinancialRow extends StatelessWidget {
  const _FinancialRow({
    required this.label,
    required this.value,
    required this.background,
    this.subtitle,
    this.borderColor,
    this.valueColor,
    this.icon,
  });

  final String label;
  final String? subtitle;
  final String value;
  final Color background;
  final Color? borderColor;
  final Color? valueColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14.r),
        border: borderColor != null ? Border.all(color: borderColor!) : null,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20.sp, color: valueColor ?? AppColors.primary),
            SizedBox(width: 10.w),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(
                  label,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 2.h),
                  MyText(
                    subtitle!,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ],
              ],
            ),
          ),
          MyText(
            value,
            fontSize: 14.sp,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, this.fullWidth = false});

  final String label;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: MyText(
        label,
        fontSize: 10.sp,
        fontWeight: FontWeight.w500,
        color: AppColors.primaryDark,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );

    if (fullWidth) return chip;
    return chip;
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.phone,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? phone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.pageBackground,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          _CircleIcon(icon: icon),
          if (phone != null) ...[
            SizedBox(width: 8.w),
            _CircleIcon(
              icon: Icons.phone_outlined,
              onTap: () => launchUrl(Uri.parse('tel:$phone')),
            ),
          ],
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(
                  title,
                  fontSize: 13.sp,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                MyText(
                  subtitle,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 36.w,
          height: 36.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Icon(icon, size: 18.sp, color: AppColors.primary),
        ),
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.label,
    required this.icon,
    this.onPressed,
    this.compact = false,
    this.enabled = true,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool compact;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 18.sp),
      label: MyText(
        label,
        fontSize: compact ? 12.sp : 14.sp,
        color: Colors.white,
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.35),
        disabledForegroundColor: Colors.white70,
        minimumSize: Size(compact ? 0 : double.infinity, 46.h),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  const _SecondaryActionButton({
    required this.label,
    required this.icon,
    this.onPressed,
    this.enabled = true,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 18.sp),
      label: MyText(
        label,
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
        color: enabled ? AppColors.primary : AppColors.textLight,
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: Size(0, 46.h),
        foregroundColor: AppColors.primary,
        disabledForegroundColor: AppColors.textLight,
        side: BorderSide(
          color: enabled ? AppColors.primary : AppColors.cardBorder,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
      ),
    );
  }
}
