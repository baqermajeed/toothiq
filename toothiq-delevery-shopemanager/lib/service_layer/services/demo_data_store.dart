import '../../model/partner_order.dart';
import '../../model/shop_brand.dart';
import '../../model/shop_category.dart';
import '../../model/shop_product.dart';
import '../../model/shop_profile.dart';

/// بيانات تجريبية محلية حتى ربط API الحقيقي.
class DemoDataStore {
  DemoDataStore._();
  static final DemoDataStore instance = DemoDataStore._();

  ShopProfile shopProfile = const ShopProfile(
    id: 'shop1',
    name: 'متجر الأسنان المركزي',
    description:
        'متجر متخصص بتوفير احتياجات أطباء الأسنان من الأدوات والمستلزمات الطبية بجودة عالية وضمان الأصالة.',
    address: 'بغداد — الكرادة، شارع أبو نواس',
    phonePrimary: '07701111001',
    phoneSecondary: '07801111002',
  );

  final List<ShopCategory> categories = [
    const ShopCategory(id: 'cat1', nameAr: 'مواد الحشوات', productCount: 1),
    const ShopCategory(id: 'cat2', nameAr: 'أدوات المعاينة', productCount: 0),
    const ShopCategory(id: 'cat3', nameAr: 'مستلزمات وقائية', productCount: 1),
  ];

  final List<ShopBrand> brands = [
    const ShopBrand(id: 'brand1', nameAr: '3M ESPE', productCount: 1),
    const ShopBrand(id: 'brand2', nameAr: 'Dentsply', productCount: 0),
    const ShopBrand(id: 'brand3', nameAr: 'MediSafe', productCount: 1),
  ];

  final List<ShopProduct> products = [
    const ShopProduct(
      id: 'p1',
      name: 'كمبوزيت سنّي',
      description: 'مادة ترميم عالية الجودة للأسنان الأمامية والخلفية',
      price: 45000,
      stock: 24,
      categoryId: 'cat1',
      categoryName: 'مواد الحشوات',
      brandId: 'brand1',
      brandName: '3M ESPE',
      expiryDate: '12 / 2027',
    ),
    const ShopProduct(
      id: 'p2',
      name: 'قفازات طبية',
      description: 'علبة 100 قطعة — مقاومة للثقب ومريحة للاستخدام الطويل',
      price: 12000,
      stock: 80,
      categoryId: 'cat3',
      categoryName: 'مستلزمات وقائية',
      brandId: 'brand3',
      brandName: 'MediSafe',
      expiryDate: '06 / 2026',
    ),
  ];

  final List<PartnerOrder> shopOrders = [
    PartnerOrder(
      id: 'o1',
      orderNumber: '1042',
      customerName: 'د. أحمد كريم',
      customerPhone: '07701234567',
      shopName: 'متجر الأسنان المركزي',
      shopAddress: 'بغداد — الكرادة',
      customerAddress: 'بغداد — المنصور، شارع 14 رمضان',
      totalPrice: 87000,
      itemCount: 3,
      status: PartnerOrderStatus.pending,
      shopLat: 33.3128,
      shopLng: 44.4250,
      customerLat: 33.3152,
      customerLng: 44.3661,
      items: const [
        PartnerOrderItem(name: 'كمبوزيت سنّي', quantity: 1, price: 45000),
        PartnerOrderItem(name: 'قفازات طبية', quantity: 2, price: 24000),
      ],
      createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
    ),
    PartnerOrder(
      id: 'o2',
      orderNumber: '1041',
      customerName: 'د. سارة علي',
      customerPhone: '07809876543',
      shopName: 'متجر الأسنان المركزي',
      shopAddress: 'بغداد — الكرادة',
      customerAddress: 'بغداد — الجادرية',
      totalPrice: 45000,
      itemCount: 1,
      status: PartnerOrderStatus.preparing,
      shopLat: 33.3128,
      shopLng: 44.4250,
      customerLat: 33.2778,
      customerLng: 44.3800,
      items: const [
        PartnerOrderItem(name: 'كمبوزيت سنّي', quantity: 1, price: 45000),
      ],
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ];

  final List<PartnerOrder> driverOrders = [
    PartnerOrder(
      id: 'd1',
      orderNumber: '1045',
      customerName: 'د. حسين ناجي',
      customerPhone: '07705551234',
      shopName: 'متجر الأسنان المركزي',
      shopAddress: 'بغداد — الكرادة، قرب ساحة الواثق',
      customerAddress: 'بغداد — زيونة، شارع الربيعي',
      totalPrice: 112000,
      deliveryFee: 3000,
      shopPhone: '07701111001',
      shopId: '12',
      itemCount: 4,
      status: PartnerOrderStatus.preparing,
      shopLat: 33.3128,
      shopLng: 44.4250,
      customerLat: 33.3400,
      customerLng: 44.4500,
      items: const [
        PartnerOrderItem(name: 'كمبوزيت سنّي', quantity: 2, price: 90000),
        PartnerOrderItem(name: 'قفازات طبية', quantity: 1, price: 12000),
      ],
      createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
    ),
    PartnerOrder(
      id: 'd2',
      orderNumber: '1044',
      customerName: 'د. سارة يوسف',
      customerPhone: '07802223344',
      shopName: 'صيدلية الأسنان',
      shopAddress: 'بغداد — الأعظمية',
      customerAddress: 'بغداد — الكاظمية، شارع الإمام',
      totalPrice: 68000,
      deliveryFee: 2500,
      shopPhone: '07702222002',
      shopId: '28',
      itemCount: 3,
      status: PartnerOrderStatus.pending,
      shopLat: 33.3700,
      shopLng: 44.3600,
      customerLat: 33.3800,
      customerLng: 44.3400,
      items: const [
        PartnerOrderItem(name: 'معجون أسنان طبي', quantity: 2, price: 56000),
        PartnerOrderItem(name: 'فرشاة أسنان', quantity: 1, price: 12000),
      ],
      createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
    ),
    PartnerOrder(
      id: 'd3',
      orderNumber: '1040',
      customerName: 'د. نور محمد',
      customerPhone: '07801112233',
      shopName: 'متجر الأسنان المركزي',
      shopAddress: 'بغداد — الكرادة',
      customerAddress: 'بغداد — المنصور',
      totalPrice: 56000,
      deliveryFee: 2000,
      shopPhone: '07701111001',
      shopId: '12',
      itemCount: 2,
      status: PartnerOrderStatus.onTheWay,
      shopLat: 33.3128,
      shopLng: 44.4250,
      customerLat: 33.3152,
      customerLng: 44.3661,
      items: const [
        PartnerOrderItem(name: 'معجون أسنان طبي', quantity: 2, price: 56000),
      ],
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    PartnerOrder(
      id: 'd4',
      orderNumber: '1035',
      customerName: 'د. علي كريم',
      customerPhone: '07709998877',
      shopName: 'صيدلية الأسنان',
      shopAddress: 'بغداد — الأعظمية',
      customerAddress: 'بغداد — الشعب',
      totalPrice: 45000,
      deliveryFee: 2000,
      shopPhone: '07702222002',
      shopId: '28',
      itemCount: 1,
      status: PartnerOrderStatus.delivered,
      shopLat: 33.3700,
      shopLng: 44.3600,
      customerLat: 33.3500,
      customerLng: 44.4000,
      items: const [
        PartnerOrderItem(name: 'كمبوزيت سنّي', quantity: 1, price: 45000),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    PartnerOrder(
      id: 'd5',
      orderNumber: '1030',
      customerName: 'وهمي',
      customerPhone: '00000000000',
      shopName: 'MMTOLE',
      shopAddress: 'بغداد — الكرادة',
      customerAddress: 'بغداد — الجادرية',
      totalPrice: 12000,
      deliveryFee: 2000,
      shopPhone: '07703333003',
      shopId: '58',
      itemCount: 1,
      status: PartnerOrderStatus.canceled,
      shopLat: 33.3128,
      shopLng: 44.4250,
      customerLat: 33.2778,
      customerLng: 44.3800,
      items: const [
        PartnerOrderItem(name: 'قفازات طبية', quantity: 1, price: 12000),
      ],
      createdAt: DateTime(2026, 7, 22, 5, 33),
    ),
  ];
}
