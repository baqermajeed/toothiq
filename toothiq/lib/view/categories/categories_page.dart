import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controller/categories_controller.dart';
import '../../utils/app_colors.dart';
import '../../widget/app_bottom_navigation.dart';
import '../../widget/categories/category_card_widget.dart';
import '../../widget/common/async_state_widgets.dart';
import '../../widget/main_app_bar.dart';
import '../../widget/search_filter_row.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<CategoriesController>()) {
      Get.put(CategoriesController(), permanent: true);
    }
    final categories = Get.find<CategoriesController>();
    final topInset =
        MediaQuery.paddingOf(context).top + MainAppBar.toolbarHeight();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        extendBodyBehindAppBar: true,
        appBar: const MainAppBar(title: 'الأقسام'),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: topInset + 8.h),
            SearchFilterRow(
              controller: categories.searchController,
              hintText: 'أبحث عن قسم ..',
              showFilter: false,
              height: 48.h,
              centerTextVertically: true,
            ),
            SizedBox(height: 16.h),
            Expanded(
              child: Obx(() {
                if (categories.isLoading.value &&
                    categories.filteredCategories.isEmpty) {
                  return const AppLoadingState();
                }

                if (categories.loadError.value != null &&
                    categories.filteredCategories.isEmpty) {
                  return AppErrorState(
                    message: categories.loadError.value!,
                    onRetry: () => categories.refresh(),
                  );
                }

                if (categories.filteredCategories.isEmpty) {
                  return const AppEmptyState(title: 'لا توجد أقسام حالياً');
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: categories.refresh,
                  child: GridView.builder(
                    clipBehavior: Clip.none,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      16.w,
                      6.h,
                      16.w,
                      AppBottomNavMetrics.floatingBarReservedHeight.h,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 8.w,
                      mainAxisSpacing: 8.h,
                      childAspectRatio: 0.86,
                    ),
                    itemCount: categories.filteredCategories.length,
                    itemBuilder: (context, index) {
                      final category = categories.filteredCategories[index];
                      return CategoryCardWidget(
                        category: category,
                        compact: true,
                        onTap: () => categories.onCategoryTap(category),
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
