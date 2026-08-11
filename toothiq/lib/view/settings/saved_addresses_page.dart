import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../bindings/saved_addresses_binding.dart';
import '../../controller/saved_addresses_controller.dart';
import '../../model/delivery_address_model.dart';
import '../../utils/app_colors.dart';
import '../../widget/basket/basket_bottom_bar.dart';
import '../../widget/common/async_state_widgets.dart';
import '../../widget/section/section_app_bar.dart';
import '../../widget/settings/address_form_bottom_sheet.dart';
import '../../widget/settings/saved_address_card_widget.dart';

class SavedAddressesPage extends GetView<SavedAddressesController> {
  const SavedAddressesPage({super.key});

  static void open() {
    Get.to(() => const SavedAddressesPage(), binding: SavedAddressesBinding());
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: const SectionAppBar(title: 'عناوين التوصيل المحفوظة'),
        body: Obx(() {
          final items = controller.addresses;
          final isEmpty = items.isEmpty;

          return Column(
            children: [
              Expanded(
                child: isEmpty
                    ? const AppEmptyState(
                        title: 'لا توجد عناوين محفوظة',
                        icon: Icons.location_on_outlined,
                      )
                    : ListView.separated(
                        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
                        physics: const BouncingScrollPhysics(),
                        itemCount: items.length,
                        separatorBuilder: (_, index) => Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.orderCardDivider.withValues(
                            alpha: 0.75,
                          ),
                        ),
                        itemBuilder: (context, index) {
                          final address = items[index];
                          return SavedAddressCardWidget(
                            address: address,
                            onEdit: () => _onEditAddress(address),
                            onDelete: () =>
                                controller.deleteAddress(address.id),
                          );
                        },
                      ),
              ),
              BasketBottomBar(
                label: isEmpty ? 'أضافة عنوان' : 'أضافة عنوان جديد',
                onTap: _onAddAddress,
              ),
            ],
          );
        }),
      ),
    );
  }

  Future<void> _onAddAddress() async {
    final result = await AddressFormBottomSheet.showAdd();
    if (result == null) return;

    await controller.addAddress(
      governorate: result.governorate,
      area: result.area,
      landmark: result.landmark,
      lat: result.lat,
      lng: result.lng,
      setAsCurrent: controller.addresses.isEmpty,
    );
  }

  Future<void> _onEditAddress(DeliveryAddressModel address) async {
    final result = await AddressFormBottomSheet.showEdit(
      governorate: address.governorate,
      area: address.area,
      landmark: address.landmark,
      lat: address.lat,
      lng: address.lng,
    );
    if (result == null) return;

    await controller.updateAddress(
      id: address.id,
      governorate: result.governorate,
      area: result.area,
      landmark: result.landmark,
      lat: result.lat,
      lng: result.lng,
    );
  }
}
