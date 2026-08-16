enum HomeFeedTab { all, offers, bestSellers, forYou, newest, topRated }

extension HomeFeedTabX on HomeFeedTab {
  String get label {
    switch (this) {
      case HomeFeedTab.all:
        return 'الكل';
      case HomeFeedTab.offers:
        return 'العروض';
      case HomeFeedTab.bestSellers:
        return 'الأكثر مبيعاً';
      case HomeFeedTab.forYou:
        return 'خصيصاً لك';
      case HomeFeedTab.newest:
        return 'الجديد';
      case HomeFeedTab.topRated:
        return 'الأعلى تقييماً';
    }
  }

  String get gridTitle {
    switch (this) {
      case HomeFeedTab.all:
        return 'جميع المنتجات';
      case HomeFeedTab.offers:
        return 'العروض';
      case HomeFeedTab.bestSellers:
        return 'الأكثر مبيعاً';
      case HomeFeedTab.forYou:
        return 'خصيصاً لك';
      case HomeFeedTab.newest:
        return 'الجديد';
      case HomeFeedTab.topRated:
        return 'الأعلى تقييماً';
    }
  }

  String get emptyTitle {
    switch (this) {
      case HomeFeedTab.all:
        return 'لا توجد منتجات حالياً';
      case HomeFeedTab.offers:
        return 'لا توجد عروض حالياً';
      case HomeFeedTab.bestSellers:
        return 'لا توجد منتجات الأكثر مبيعاً بعد';
      case HomeFeedTab.forYou:
        return 'لا توجد توصيات حالياً';
      case HomeFeedTab.newest:
        return 'لا توجد منتجات جديدة';
      case HomeFeedTab.topRated:
        return 'لا توجد متاجر مقيّمة بعد';
    }
  }

  bool get showsShops => this == HomeFeedTab.topRated;

  String get iconAsset {
    switch (this) {
      case HomeFeedTab.all:
        return 'assets/images/iconbaner/all.png';
      case HomeFeedTab.offers:
        return 'assets/images/iconbaner/discount.png';
      case HomeFeedTab.bestSellers:
        return 'assets/images/iconbaner/mostpayed.png';
      case HomeFeedTab.forYou:
        return 'assets/images/iconbaner/foryou.png';
      case HomeFeedTab.newest:
        return 'assets/images/iconbaner/new.png';
      case HomeFeedTab.topRated:
        return 'assets/images/iconbaner/bigestreco.png';
    }
  }
}
