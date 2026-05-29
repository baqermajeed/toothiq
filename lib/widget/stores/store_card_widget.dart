import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../model/store_model.dart';
import '../../utils/app_colors.dart';
import '../my_text.dart';

class StoreCardWidget extends StatelessWidget {
  final StoreModel store;
  final VoidCallback onViewStore;

  const StoreCardWidget({
    super.key,
    required this.store,
    required this.onViewStore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      padding: EdgeInsets.all(14.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12.r),
                      child: Image.asset(
                        store.logoAsset,
                        width: 48.w,
                        height: 48.w,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                          width: 48.w,
                          height: 48.w,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Icon(
                            Icons.medical_services_rounded,
                            color: AppColors.productStore,
                            size: 26.sp,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: MyText(
                        store.name,
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.productTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              _RatingBadge(rating: store.rating),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            store.description,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Expo Arabic',
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.productDescription,
              height: 1.45,
            ),
          ),
          SizedBox(height: 14.h),
          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: ElevatedButton(
              onPressed: onViewStore,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.productStore,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              child: MyText(
                'عرض المتجر',
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  final double rating;

  const _RatingBadge({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: AppColors.ratingBackground,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontFamily: 'Expo Arabic',
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.productTitle,
            ),
          ),
          SizedBox(width: 4.w),
          Icon(
            Icons.star_rounded,
            color: AppColors.ratingStar,
            size: 18.sp,
          ),
        ],
      ),
    );
  }
}
