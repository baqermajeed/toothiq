import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

import '../../utils/app_colors.dart';
import '../home/home_catalog_strips_metrics.dart';
import '../home/product_card_widget.dart';

abstract final class SkeletonStyle {
  static const Color base = Color(0xFFE6EBED);
  static const Color highlight = Color(0xFFF7F9FA);
}

class AppShimmer extends StatelessWidget {
  const AppShimmer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: SkeletonStyle.base,
      highlightColor: SkeletonStyle.highlight,
      period: const Duration(milliseconds: 1300),
      child: child,
    );
  }
}

class ImageShimmer extends StatelessWidget {
  const ImageShimmer({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final base = color ?? SkeletonStyle.base;
    final highlight = Color.lerp(base, Colors.white, 0.38) ?? SkeletonStyle.highlight;
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      period: const Duration(milliseconds: 1300),
      child: ColoredBox(color: base),
    );
  }
}

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.radius,
    this.borderRadius,
  });

  final double? width;
  final double? height;
  final double? radius;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: SkeletonStyle.base,
        borderRadius: borderRadius ?? BorderRadius.circular(radius ?? 12.r),
      ),
    );
  }
}

class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: ProductCardWidget.cardHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      padding: EdgeInsets.all(6.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SkeletonBox(
            height: 127.34.h,
            radius: 18.r,
          ),
          SizedBox(height: 10.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SkeletonBox(width: 118.w, height: 12.h, radius: 6.r),
                SizedBox(height: 8.h),
                SkeletonBox(width: 78.w, height: 10.h, radius: 6.r),
                SizedBox(height: 8.h),
                SkeletonBox(width: 96.w, height: 9.h, radius: 6.r),
              ],
            ),
          ),
          const Spacer(),
          SkeletonBox(height: 40.h, radius: 18.r),
        ],
      ),
    );
  }
}

class ProductGridSkeleton extends StatelessWidget {
  const ProductGridSkeleton({
    super.key,
    this.itemCount = 6,
    this.shrinkWrap = false,
    this.padding,
  });

  final int itemCount;
  final bool shrinkWrap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: GridView.builder(
        shrinkWrap: shrinkWrap,
        primary: shrinkWrap ? false : null,
        physics: shrinkWrap
            ? const NeverScrollableScrollPhysics()
            : const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
        padding: padding ?? EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: itemCount,
        gridDelegate: ProductCardWidget.gridDelegate,
        itemBuilder: (_, _) => const ProductCardSkeleton(),
      ),
    );
  }
}

class StoreCardSkeleton extends StatelessWidget {
  const StoreCardSkeleton({super.key});

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
            children: [
              SkeletonBox(width: 48.w, height: 48.w, radius: 12.r),
              SizedBox(width: 10.w),
              Expanded(
                child: SkeletonBox(height: 14.h, radius: 6.r),
              ),
              SizedBox(width: 12.w),
              SkeletonBox(width: 52.w, height: 28.h, radius: 10.r),
            ],
          ),
          SizedBox(height: 12.h),
          SkeletonBox(height: 10.h, radius: 6.r),
          SizedBox(height: 8.h),
          Align(
            alignment: Alignment.centerRight,
            child: SkeletonBox(width: 180.w, height: 10.h, radius: 6.r),
          ),
          SizedBox(height: 14.h),
          SkeletonBox(height: 48.h, radius: 16.r),
        ],
      ),
    );
  }
}

class StoresListSkeleton extends StatelessWidget {
  const StoresListSkeleton({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
        itemCount: itemCount,
        separatorBuilder: (_, _) => SizedBox(height: 14.h),
        itemBuilder: (_, _) => const StoreCardSkeleton(),
      ),
    );
  }
}

class HomePageSkeleton extends StatelessWidget {
  const HomePageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 4.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: SkeletonBox(height: 142.h, radius: 20.r),
            ),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SkeletonBox(width: 18.w, height: 7.h, radius: 8.r),
                SizedBox(width: 6.w),
                SkeletonBox(width: 7.w, height: 7.h, radius: 8.r),
                SizedBox(width: 6.w),
                SkeletonBox(width: 7.w, height: 7.h, radius: 8.r),
              ],
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 8.h),
              child: Row(
                children: [
                  SkeletonBox(width: 72.w, height: 14.h, radius: 6.r),
                  const Spacer(),
                  SkeletonBox(width: 58.w, height: 12.h, radius: 6.r),
                ],
              ),
            ),
            SizedBox(
              height: HomeCatalogStripsMetrics.categoryListHeight(),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                itemCount: 5,
                separatorBuilder: (_, _) =>
                    SizedBox(width: HomeCatalogStripsMetrics.itemGap()),
                itemBuilder: (_, _) {
                  final size = HomeCatalogStripsMetrics.categoryBoxSize();
                  return Column(
                    children: [
                      SkeletonBox(
                        width: size,
                        height: size,
                        radius: HomeCatalogStripsMetrics.categoryRadius(),
                      ),
                      SizedBox(height: 6.h),
                      SkeletonBox(width: 54.w, height: 10.h, radius: 6.r),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 8.h),
              child: Row(
                children: [
                  SkeletonBox(width: 86.w, height: 14.h, radius: 6.r),
                  const Spacer(),
                  SkeletonBox(width: 58.w, height: 12.h, radius: 6.r),
                ],
              ),
            ),
            SizedBox(
              height: HomeCatalogStripsMetrics.brandListHeight(),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                itemCount: 3,
                separatorBuilder: (_, _) => SizedBox(width: 6.w),
                itemBuilder: (_, _) => SkeletonBox(
                  width: HomeCatalogStripsMetrics.brandWidth(),
                  height: HomeCatalogStripsMetrics.brandHeight(),
                  radius: HomeCatalogStripsMetrics.brandRadius(),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              height: 42.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: 5,
                separatorBuilder: (_, _) => SizedBox(width: 8.w),
                itemBuilder: (_, _) =>
                    SkeletonBox(width: 92.w, height: 42.h, radius: 16.r),
              ),
            ),
            SizedBox(height: 12.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Align(
                alignment: Alignment.centerRight,
                child: SkeletonBox(width: 110.w, height: 16.h, radius: 6.r),
              ),
            ),
            SizedBox(height: 10.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 4,
                gridDelegate: ProductCardWidget.gridDelegate,
                itemBuilder: (_, _) => const ProductCardSkeleton(),
              ),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}

class HomeFeedSkeleton extends StatelessWidget {
  const HomeFeedSkeleton({super.key, this.showStores = false});

  final bool showStores;

  @override
  Widget build(BuildContext context) {
    if (showStores) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: AppShimmer(
          child: Column(
            children: [
              for (var i = 0; i < 3; i++) ...[
                const StoreCardSkeleton(),
                if (i < 2) SizedBox(height: 14.h),
              ],
            ],
          ),
        ),
      );
    }

    return const ProductGridSkeleton(
      itemCount: 4,
      shrinkWrap: true,
    );
  }
}

class StoreDetailSkeleton extends StatelessWidget {
  const StoreDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final coverHeight = topInset + 56.h + 128.h;

    return AppShimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SkeletonBox(
              height: coverHeight,
              radius: 0,
            ),
            Transform.translate(
              offset: Offset(0, -28.h),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: SkeletonBox(height: 114.h, radius: 20.r),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 12.h),
              child: Row(
                children: [
                  Expanded(child: SkeletonBox(height: 36.h, radius: 14.r)),
                  SizedBox(width: 8.w),
                  Expanded(child: SkeletonBox(height: 36.h, radius: 14.r)),
                  SizedBox(width: 8.w),
                  Expanded(child: SkeletonBox(height: 36.h, radius: 14.r)),
                ],
              ),
            ),
            SizedBox(
              height: ProductCardWidget.cardHeight,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: 3,
                separatorBuilder: (_, _) => SizedBox(width: 12.w),
                itemBuilder: (_, _) {
                  return SizedBox(
                    width: ProductCardWidget.cardWidthFor(context),
                    child: const ProductCardSkeleton(),
                  );
                },
              ),
            ),
            SizedBox(height: 16.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 4,
                gridDelegate: ProductCardWidget.gridDelegate,
                itemBuilder: (_, _) => const ProductCardSkeleton(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductDetailsSkeleton extends StatelessWidget {
  const ProductDetailsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final galleryHeight = 280.h;
    final thumbSize = (galleryHeight - (6.h * 3)) / 4;

    return ColoredBox(
      color: AppColors.background,
      child: AppShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: SizedBox(
                        height: galleryHeight,
                        child: Row(
                          children: [
                            Expanded(
                              child: SkeletonBox(
                                height: galleryHeight,
                                radius: 16.r,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Column(
                              children: [
                                for (var i = 0; i < 4; i++) ...[
                                  SkeletonBox(
                                    width: thumbSize,
                                    height: thumbSize,
                                    radius: 12.r,
                                  ),
                                  if (i < 3) SizedBox(height: 6.h),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: SkeletonBox(height: 48.h, radius: 16.r),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          SkeletonBox(width: 180.w, height: 16.h, radius: 6.r),
                          SizedBox(height: 12.h),
                          Row(
                            children: [
                              SkeletonBox(
                                width: 110.w,
                                height: 36.h,
                                radius: 12.r,
                              ),
                              const Spacer(),
                              SkeletonBox(
                                width: 96.w,
                                height: 28.h,
                                radius: 8.r,
                              ),
                            ],
                          ),
                          SizedBox(height: 18.h),
                          SkeletonBox(width: 90.w, height: 14.h, radius: 6.r),
                          SizedBox(height: 10.h),
                          SkeletonBox(height: 10.h, radius: 6.r),
                          SizedBox(height: 8.h),
                          SkeletonBox(height: 10.h, radius: 6.r),
                          SizedBox(height: 8.h),
                          Align(
                            alignment: Alignment.centerRight,
                            child: SkeletonBox(
                              width: 220.w,
                              height: 10.h,
                              radius: 6.r,
                            ),
                          ),
                          SizedBox(height: 10.h),
                          SkeletonBox(height: 10.h, radius: 6.r),
                          SizedBox(height: 8.h),
                          Align(
                            alignment: Alignment.centerRight,
                            child: SkeletonBox(
                              width: 160.w,
                              height: 10.h,
                              radius: 6.r,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
              child: SkeletonBox(height: 56.h, radius: 18.r),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoriesGridSkeleton extends StatelessWidget {
  const CategoriesGridSkeleton({
    super.key,
    this.itemCount = 12,
    this.shrinkWrap = false,
  });

  final int itemCount;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: GridView.builder(
        shrinkWrap: shrinkWrap,
        physics: shrinkWrap
            ? const NeverScrollableScrollPhysics()
            : const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 24.h),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 8.w,
          mainAxisSpacing: 8.h,
          childAspectRatio: 0.86,
        ),
        itemCount: itemCount,
        itemBuilder: (_, _) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: AppColors.cardBorder),
            ),
            padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
            child: Column(
              children: [
                Expanded(
                  child: SkeletonBox(radius: 12.r),
                ),
                SizedBox(height: 8.h),
                SkeletonBox(height: 10.h, radius: 6.r),
              ],
            ),
          );
        },
      ),
    );
  }
}

class OrdersListSkeleton extends StatelessWidget {
  const OrdersListSkeleton({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
        itemCount: itemCount,
        separatorBuilder: (_, _) => SizedBox(height: 10.h),
        itemBuilder: (_, _) => const OrderCardSkeleton(),
      ),
    );
  }
}

class OrderCardSkeleton extends StatelessWidget {
  const OrderCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.orderCardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: 72.w, height: 72.w, radius: 10.r),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SkeletonBox(width: 140.w, height: 13.h, radius: 6.r),
                SizedBox(height: 8.h),
                SkeletonBox(width: 90.w, height: 10.h, radius: 6.r),
                SizedBox(height: 8.h),
                SkeletonBox(width: 68.w, height: 22.h, radius: 8.r),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OrderDetailSkeleton extends StatelessWidget {
  const OrderDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
        children: [
          SkeletonBox(height: 160.h, radius: 16.r),
          SizedBox(height: 12.h),
          for (var i = 0; i < 3; i++) ...[
            const OrderCardSkeleton(),
            SizedBox(height: 10.h),
          ],
          SkeletonBox(height: 84.h, radius: 16.r),
        ],
      ),
    );
  }
}

class NotificationsListSkeleton extends StatelessWidget {
  const NotificationsListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
        itemCount: 8,
        separatorBuilder: (_, _) => SizedBox(height: 10.h),
        itemBuilder: (_, _) {
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                SkeletonBox(width: 34.w, height: 34.w, radius: 10.r),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SkeletonBox(width: 180.w, height: 12.h, radius: 6.r),
                      SizedBox(height: 8.h),
                      SkeletonBox(height: 10.h, radius: 6.r),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class CheckoutFormSkeleton extends StatelessWidget {
  const CheckoutFormSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
        children: [
          for (var i = 0; i < 5; i++) ...[
            Align(
              alignment: Alignment.centerRight,
              child: SkeletonBox(width: 90.w, height: 12.h, radius: 6.r),
            ),
            SizedBox(height: 8.h),
            SkeletonBox(height: 52.h, radius: 16.r),
            SizedBox(height: 16.h),
          ],
          SkeletonBox(height: 56.h, radius: 16.r),
          SizedBox(height: 12.h),
          SkeletonBox(height: 56.h, radius: 16.r),
        ],
      ),
    );
  }
}

class FilterPageSkeleton extends StatelessWidget {
  const FilterPageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: SkeletonBox(width: 80.w, height: 14.h, radius: 6.r),
          ),
          SizedBox(height: 16.h),
          SkeletonBox(height: 12.h, radius: 8.r),
          SizedBox(height: 28.h),
          Align(
            alignment: Alignment.centerRight,
            child: SkeletonBox(width: 100.w, height: 14.h, radius: 6.r),
          ),
          SizedBox(height: 14.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              for (var i = 0; i < 8; i++)
                SkeletonBox(width: 88.w, height: 36.h, radius: 18.r),
            ],
          ),
          SizedBox(height: 28.h),
          Align(
            alignment: Alignment.centerRight,
            child: SkeletonBox(width: 110.w, height: 14.h, radius: 6.r),
          ),
          SizedBox(height: 14.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              for (var i = 0; i < 6; i++)
                SkeletonBox(width: 96.w, height: 36.h, radius: 18.r),
            ],
          ),
        ],
      ),
    );
  }
}

class SearchResultsSkeleton extends StatelessWidget {
  const SearchResultsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: SkeletonBox(width: 70.w, height: 14.h, radius: 6.r),
          ),
          SizedBox(height: 10.h),
          const StoreCardSkeleton(),
          SizedBox(height: 14.h),
          Align(
            alignment: Alignment.centerRight,
            child: SkeletonBox(width: 80.w, height: 14.h, radius: 6.r),
          ),
          SizedBox(height: 10.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            gridDelegate: ProductCardWidget.gridDelegate,
            itemBuilder: (_, _) => const ProductCardSkeleton(),
          ),
        ],
      ),
    );
  }
}

class ProductGallerySkeleton extends StatelessWidget {
  const ProductGallerySkeleton({super.key, required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: SkeletonBox(height: height, radius: 16.r),
    );
  }
}

class LoadMoreSkeleton extends StatelessWidget {
  const LoadMoreSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: const ProductGridSkeleton(
        itemCount: 2,
        shrinkWrap: true,
        padding: EdgeInsets.zero,
      ),
    );
  }
}
