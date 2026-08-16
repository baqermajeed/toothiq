import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../bindings/order_detail_binding.dart';
import '../../controller/order_detail_controller.dart';
import '../../controller/orders_controller.dart';
import '../../model/order_model.dart';
import '../../utils/app_colors.dart';
import '../../widget/common/async_state_widgets.dart';
import '../../widget/orders/driver_rating_card.dart';
import '../../widget/orders/order_detail_app_bar.dart';
import '../../widget/orders/order_detail_bottom_bar.dart';
import '../../widget/orders/order_info_card.dart';
import '../../widget/my_text.dart';
import '../../widget/orders/order_product_line_widget.dart';

class OrderDetailPage extends StatelessWidget {
  const OrderDetailPage({super.key});

  static Future<void> open(OrderModel order) async {
    await Get.to(
      () => const OrderDetailPage(),
      binding: OrderDetailBinding(order: order),
    );
    if (Get.isRegistered<OrdersController>()) {
      await Get.find<OrdersController>().refreshSilently();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<OrderDetailController>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: const OrderDetailAppBar(),
        bottomNavigationBar: Obx(() {
          if (ctrl.detail.value == null) return const SizedBox.shrink();
          return OrderDetailBottomBar(controller: ctrl);
        }),
        body: Obx(() {
          if (ctrl.isLoading.value && ctrl.detail.value == null) {
            return const AppLoadingState();
          }

          if (ctrl.loadError.value != null && ctrl.detail.value == null) {
            return AppErrorState(
              message: ctrl.loadError.value!,
              onRetry: () => ctrl.loadDetail(),
            );
          }

          final d = ctrl.detail.value;
          if (d == null) {
            return const AppLoadingState();
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: ctrl.refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (ctrl.loadError.value != null) ...[
                    AppErrorState(
                      message: ctrl.loadError.value!,
                      onRetry: () => ctrl.loadDetail(),
                      compact: true,
                    ),
                    SizedBox(height: 10.h),
                  ],
                  OrderInfoCard(
                    fields: [
                      OrderInfoField(
                        label: 'أسم الزبون :',
                        value: d.customerName,
                      ),
                      OrderInfoField(label: 'رقم الهاتف :', value: d.phone),
                      OrderInfoField(
                        label: 'رقم هاتف آخر :',
                        value: d.altPhone,
                      ),
                      OrderInfoField(
                        label: 'وقت التوصيل :',
                        value: d.deliveryTime,
                      ),
                      OrderInfoField(
                        label: 'عنوان التوصيل :',
                        value: d.deliveryAddress,
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  OrderInfoCard(
                    fields: [
                      OrderInfoField(
                        label: 'تاريخ الطلب :',
                        value: d.orderDate,
                      ),
                      OrderInfoField(label: 'أسم المتجر :', value: d.storeName),
                      OrderInfoField(
                        label: 'عنوان المتجر :',
                        value: d.storeAddress,
                      ),
                    ],
                  ),
                  if (d.canRateDriver) ...[
                    SizedBox(height: 16.h),
                    DriverRatingCard(
                      driverName: d.driverName ?? '',
                      selectedRating: ctrl.selectedDriverRating.value,
                      commentController:
                          ctrl.driverReviewCommentController,
                      isSubmitting: ctrl.isSubmittingDriverReview.value,
                      hasSubmitted: d.hasDriverReview,
                      onRatingChanged: (rating) =>
                          ctrl.selectedDriverRating.value = rating,
                      onSubmit: ctrl.submitDriverReview,
                    ),
                  ],
                  if (d.status == OrderStatus.onTheWay && d.canTrackOnMap) ...[
                    SizedBox(height: 16.h),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: ctrl.openLiveTracking,
                        icon: Icon(Icons.map_rounded, size: 22.sp),
                        label: MyText(
                          'تتبع طلبي على الخريطة',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryDark,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: 10.h),
                  MyText(
                    'المنتجات المطلوبة ( ${d.itemCount} )',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.productTitle,
                    textAlign: TextAlign.right,
                  ),
                  SizedBox(height: 6.h),
                  if (d.items.isEmpty)
                    const AppEmptyState(
                      title: 'لا توجد منتجات في هذا الطلب',
                      icon: Icons.shopping_bag_outlined,
                    )
                  else
                    ...d.items.map(
                      (item) => Padding(
                        padding: EdgeInsets.only(bottom: 6.h),
                        child: OrderProductLineWidget(item: item),
                      ),
                    ),
                  SizedBox(height: 6.h),
                  MyText(
                    'تفاصيل السعر',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.productTitle,
                    textAlign: TextAlign.right,
                  ),
                  SizedBox(height: 6.h),
                  OrderInfoCard(
                    fields: [
                      OrderInfoField(
                        label: 'طريقة الدفع :',
                        value: d.paymentMethod,
                      ),
                      OrderInfoField(
                        label: 'سعر الطلب :',
                        value: d.formattedOrderPrice,
                        valueIsGreen: true,
                      ),
                      OrderInfoField(
                        label: 'سعر التوصيل :',
                        value: d.deliveryPriceLabel,
                      ),
                      OrderInfoField(
                        label: 'السعر الكلي :',
                        value: d.formattedTotalPrice,
                        highlightValue: true,
                        valueIsGreen: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
