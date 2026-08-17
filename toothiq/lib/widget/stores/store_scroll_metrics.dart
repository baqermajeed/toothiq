import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'store_cover_header.dart';

abstract final class StoreScrollMetrics {
  static double hideAnimationRange() => 48.h;

  static double hideStartOffset(double topInset) =>
      StoreCoverHeader.heightFor(topInset);
}
