import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controller/stores_controller.dart';
import '../../utils/app_colors.dart';
import '../../widget/common/async_state_widgets.dart';
import '../../widget/main_app_bar.dart';
import '../../widget/search_filter_row.dart';
import '../../widget/stores/store_card_widget.dart';

class StoresPage extends StatelessWidget {
  const StoresPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<StoresController>()) {
      Get.put(StoresController(), permanent: true);
    }
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
              onSubmitted: (_) => stores.submitSearch(),
              onFilterTap: stores.onFilterTap,
            ),
            SizedBox(height: 16.h),
            Expanded(
              child: Obx(() {
                if (stores.isLoading.value && stores.filteredStores.isEmpty) {
                  return const AppLoadingState();
                }

                if (stores.loadError.value != null &&
                    stores.filteredStores.isEmpty) {
                  return AppErrorState(
                    message: stores.loadError.value!,
                    onRetry: () => stores.refresh(),
                  );
                }

                if (stores.filteredStores.isEmpty) {
                  return const AppEmptyState(title: 'لا توجد محلات حالياً');
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: stores.refresh,
                  child: ListView.separated(
                    controller: stores.scrollController,
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                    itemCount:
                        stores.filteredStores.length +
                        (stores.loadingMore.value ? 1 : 0),
                    separatorBuilder: (context, index) =>
                        SizedBox(height: 14.h),
                    itemBuilder: (context, index) {
                      if (index >= stores.filteredStores.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      }
                      final store = stores.filteredStores[index];
                      return StoreCardWidget(
                        store: store,
                        onViewStore: () => stores.onViewStore(store.id),
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
