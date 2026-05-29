import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../bindings/order_detail_binding.dart';
import '../../controller/order_detail_controller.dart';
import '../../model/order_model.dart';
import '../../utils/app_colors.dart';
import '../../widget/orders/order_detail_app_bar.dart';
import '../../widget/orders/order_detail_bottom_bar.dart';
import '../../widget/orders/order_info_card.dart';
import '../../widget/my_text.dart';
import '../../widget/orders/order_product_line_widget.dart';

class OrderDetailPage extends StatelessWidget {
  const OrderDetailPage({super.key});

  static void open(OrderModel order) {
    Get.to(
      () => const OrderDetailPage(),
      binding: OrderDetailBinding(order: order),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<OrderDetailController>();
    final d = ctrl.detail;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: const OrderDetailAppBar(),
        bottomNavigationBar: OrderDetailBottomBar(controller: ctrl),
        body: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              SizedBox(height: 14.h),
              OrderInfoCard(
                fields: [
                  OrderInfoField(label: 'تاريخ الطلب :', value: d.orderDate),
                  OrderInfoField(label: 'أسم المتجر :', value: d.storeName),
                  OrderInfoField(
                    label: 'عنوان المتجر :',
                    value: d.storeAddress,
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              MyText(
                'المنتجات المطلوبة ( ${d.itemCount} )',
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.productTitle,
                textAlign: TextAlign.right,
              ),
              SizedBox(height: 12.h),
              ...d.items.map(
                (item) => Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: OrderProductLineWidget(item: item),
                ),
              ),
              SizedBox(height: 8.h),
              MyText(
                'تفاصيل السعر',
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.productTitle,
                textAlign: TextAlign.right,
              ),
              SizedBox(height: 12.h),
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
      ),
    );
  }
}
