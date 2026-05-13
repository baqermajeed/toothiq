const ROLES = Object.freeze({
  CUSTOMER: 'customer',
  SHOP: 'shop',
  ADMIN: 'admin',
});

const SHOP_CATEGORIES = Object.freeze([
  'مخضر',
  'غذائية',
  'لحوم',
  'مطاعم',
  'بقالة',
  'حلويات',
  'مشروبات',
  'فواكه',
  'خضروات',
  'ألبان',
]);

const ORDER_STATUS = Object.freeze({
  PENDING: 'pending',
  ACCEPTED: 'accepted',
  PREPARING: 'preparing',
  ON_THE_WAY: 'on_the_way',
  DELIVERED: 'delivered',
  CANCELED: 'canceled',
  POSTPONED: 'postponed',
});

module.exports = {
  ROLES,
  SHOP_CATEGORIES,
  ORDER_STATUS,
};
