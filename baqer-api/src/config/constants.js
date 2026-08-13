const ROLES = Object.freeze({
  CUSTOMER: 'customer',
  SHOP: 'shop',
  DRIVER: 'driver',
  ADMIN: 'admin',
});

const DRIVER_ORDER_TABS = Object.freeze({
  PENDING: 'pending',
  IN_PROGRESS: 'in_progress',
  PICKED_UP: 'picked_up',
  COMPLETED: 'completed',
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
  DRIVER_ORDER_TABS,
  SHOP_CATEGORIES,
  ORDER_STATUS,
};
