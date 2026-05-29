import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controller/categories_controller.dart';
import '../../utils/app_colors.dart';
import '../../widget/categories/category_card_widget.dart';
import '../../widget/main_app_bar.dart';
import '../../widget/search_filter_row.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = Get.find<CategoriesController>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: const MainAppBar(title: 'الأقسام'),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 8.h),
            SearchFilterRow(
              controller: categories.searchController,
              hintText: 'أبحث عن قسم ..',
              filterCircular: true,
            ),
            SizedBox(height: 16.h),
            Expanded(
              child: Obx(
                () => GridView.builder(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12.w,
                    mainAxisSpacing: 12.h,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: categories.filteredCategories.length,
                  itemBuilder: (context, index) {
                    final category = categories.filteredCategories[index];
                    return CategoryCardWidget(
                      category: category,
                      onTap: () => categories.onCategoryTap(category),
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
