import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../model/order_model.dart';
import '../../utils/app_colors.dart';
import '../app_image.dart';

/// كارد الطلب — قائمة طلباتك (RTL)
class OrderCardWidget extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onTap;

  const OrderCardWidget({
    super.key,
    required this.order,
    this.onTap,
  });

  static const double _cardRadius = 20;
  static const double _imageRadius = 14;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_cardRadius.r),
        border: Border.all(color: AppColors.orderCardBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: AppColors.orderCardShadow,
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(_cardRadius.r),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(_cardRadius.r),
          splashColor: AppColors.primary.withValues(alpha: 0.08),
          highlightColor: AppColors.primaryLight.withValues(alpha: 0.4),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _OrderImage(
                  imageAsset: order.imageAsset,
                  radius: _imageRadius,
                ),
                SizedBox(width: 14.w),
                Expanded(child: _OrderDetails(order: order)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderImage extends StatelessWidget {
  final String imageAsset;
  final double radius;

  const _OrderImage({
    required this.imageAsset,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius.r),
      child: AppImage(
        source: imageAsset,
        width: 92.w,
        height: 92.w,
        fit: BoxFit.cover,
        errorIcon: Icons.medical_services_rounded,
      ),
    );
  }
}

class _OrderDetails extends StatelessWidget {
  final OrderModel order;

  const _OrderDetails({required this.order});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          order.orderName,
          textAlign: TextAlign.right,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Expo Arabic',
            fontSize: 16.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            height: 1.3,
          ),
        ),
        SizedBox(height: 5.h),
        Text(
          order.storeName,
          textAlign: TextAlign.right,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Expo Arabic',
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.orderStoreName,
            height: 1.3,
          ),
        ),
        SizedBox(height: 12.h),
        const _DashedDivider(),
        SizedBox(height: 12.h),
        Text(
          'السعر : ${order.formattedPrice}',
          textAlign: TextAlign.right,
          style: TextStyle(
            fontFamily: 'Expo Arabic',
            fontSize: 14.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            height: 1.3,
          ),
        ),
        SizedBox(height: 12.h),
        _OrderStatusBadge(status: order.status),
      ],
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedLinePainter(color: AppColors.orderCardDivider),
      size: Size(double.infinity, 1.5.h),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 4.0;
    const dashSpace = 5.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    double startX = 0;
    while (startX < size.width) {
      final endX = (startX + dashWidth).clamp(0.0, size.width);
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(endX, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OrderStatusBadge extends StatelessWidget {
  final OrderStatus status;

  const _OrderStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 8.h),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(18.r),
      ),
      alignment: Alignment.center,
      child: Text(
        status.label,
        style: TextStyle(
          fontFamily: 'Expo Arabic',
          fontSize: 13.sp,
          fontWeight: FontWeight.w800,
          color: status.textColor,
          height: 1.2,
        ),
      ),
    );
  }
}
