import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'home_catalog_strips_metrics.dart';

/// أبعاد ثابتة لحساب سلوك إخفاء الشعار وظهور الهيدر المضغوط عند التمرير
abstract final class HomeScrollMetrics {
  static double logoBarHeight() => 56.h;

  static double searchBlockHeight() => 8.h + 53.72.h + 8.h;

  static double bannerBlockHeight() => 8.h + 160.h + 6.h + 14.h + 10.h;

  static double catalogStripsHeight() =>
      HomeCatalogStripsMetrics.categoryStripHeight() +
      HomeCatalogStripsMetrics.brandStripHeight();

  /// عند هذا الإزاحة يبدأ الشعار بالاختفاء (وصول قسم المنتجات)
  static double logoHideStartOffset() =>
      searchBlockHeight() + bannerBlockHeight() + catalogStripsHeight();

  static double logoHideAnimationRange() => 48.h;
}
