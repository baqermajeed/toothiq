import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controller/stores_controller.dart';
import '../../utils/app_colors.dart';
import '../../widget/main_app_bar.dart';
import '../../widget/search_filter_row.dart';
import '../../widget/stores/store_card_widget.dart';

class StoresPage extends StatelessWidget {
  const StoresPage({super.key});

  @override
  Widget build(BuildContext context) {
    final stores = Get.find<StoresController>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: const MainAppBar(title: 'المتاجر'),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 8.h),
            SearchFilterRow(
              controller: stores.searchController,
              hintText: 'أبحث عن متجر محدد ..',
            ),
            SizedBox(height: 16.h),
            Expanded(
              child: Obx(
                () => ListView.separated(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                  itemCount: stores.stores.length,
                  separatorBuilder: (context, index) => SizedBox(height: 14.h),
                  itemBuilder: (context, index) {
                    final store = stores.stores[index];
                    return StoreCardWidget(
                      store: store,
                      onViewStore: () => stores.onViewStore(store.id),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
