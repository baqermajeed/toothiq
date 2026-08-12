const { Order, Shop } = require('../models');
const { ORDER_STATUS, DRIVER_ORDER_TABS } = require('../config/constants');
const { notFound, forbidden, badRequest, conflict } = require('../utils/errors');
const { formatOrderForClient } = require('./orderService');

const STATUS_LABELS = {
  [ORDER_STATUS.PENDING]: 'قيد الانتظار',
  [ORDER_STATUS.ACCEPTED]: 'قيد المراجعة',
  [ORDER_STATUS.PREPARING]: 'قيد التحضير',
  [ORDER_STATUS.ON_THE_WAY]: 'في الطريق',
  [ORDER_STATUS.DELIVERED]: 'تم التوصيل',
  [ORDER_STATUS.CANCELED]: 'ملغي',
  [ORDER_STATUS.POSTPONED]: 'مؤجل',
};

/** حالات تظهر في تبويب «قيد الانتظار»: مقبولة من المتجر بلا سائق */
const PENDING_DRIVER_STATUSES = [ORDER_STATUS.ACCEPTED, ORDER_STATUS.PREPARING];

/** حالات تبويب «قيد التنفيذ» بعد قبول السائق */
const IN_PROGRESS_DRIVER_STATUSES = [
  ORDER_STATUS.ACCEPTED,
  ORDER_STATUS.PREPARING,
  ORDER_STATUS.ON_THE_WAY,
  ORDER_STATUS.POSTPONED,
];

const COMPLETED_DRIVER_STATUSES = [ORDER_STATUS.DELIVERED, ORDER_STATUS.CANCELED];

function coordsToLatLng(point) {
  const coords = point?.coordinates;
  if (!Array.isArray(coords) || coords.length < 2) return { lat: null, lng: null };
  const lng = Number(coords[0]);
  const lat = Number(coords[1]);
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) return { lat: null, lng: null };
  return { lat, lng };
}

function resolveShopFromOrder(order) {
  if (order.shopId && typeof order.shopId === 'object') {
    return order.shopId;
  }
  if (Array.isArray(order.shopPortions) && order.shopPortions.length > 0) {
    const first = order.shopPortions[0];
    if (first?.shopId && typeof first.shopId === 'object') return first.shopId;
  }
  return null;
}

function collectItems(order) {
  if (Array.isArray(order.items) && order.items.length > 0) {
    return order.items;
  }
  if (Array.isArray(order.shopPortions)) {
    return order.shopPortions.flatMap((p) => p.items || []);
  }
  return [];
}

/**
 * تحويل الطلب لصيغة تطبيق المندوب (بطاقة القائمة + التفاصيل).
 */
function formatOrderForDriver(order) {
  const base = formatOrderForClient(order);
  if (!base) return null;

  const shop = resolveShopFromOrder(base);
  const shopLoc = coordsToLatLng(shop?.location);
  const deliveryLoc = coordsToLatLng(base.deliveryLocation);
  const items = collectItems(base);
  const totalPrice = Number(base.totalPrice ?? 0);
  const deliveryFee = Number(base.deliveryFee ?? 0);
  const productsCount = items.reduce((sum, it) => sum + (Number(it.quantity) || 0), 0);

  const customer =
    base.customerId && typeof base.customerId === 'object'
      ? {
          id: String(base.customerId._id || base.customerId),
          name: base.customerId.name || '',
          phone: base.customerId.phone || '',
        }
      : {
          id: base.customerUserId || (base.customerId ? String(base.customerId) : null),
          name: base.customerName || '',
          phone: base.customerPhone || '',
        };

  return {
    id: String(base._id || base.id),
    orderNumber: base.orderNumber ?? null,
    status: base.status,
    statusLabel: STATUS_LABELS[base.status] || base.status,
    shop: shop
      ? {
          id: String(shop._id || shop.id),
          name: shop.name || '',
          address: shop.address?.trim() || null,
          phone: shop.phone?.trim() || shop.ownerId?.phone || null,
          phone2: shop.phone2?.trim() || null,
          location: shopLoc.lat != null ? { lat: shopLoc.lat, lng: shopLoc.lng } : null,
        }
      : null,
    customer,
    deliveryAddress: base.deliveryAddress?.trim() || null,
    deliveryLocation: deliveryLoc.lat != null ? { lat: deliveryLoc.lat, lng: deliveryLoc.lng } : null,
    items: items.map((it) => ({
      productId: it.productId ? String(it.productId) : null,
      name: it.name || '',
      price: Number(it.price ?? 0),
      quantity: Number(it.quantity ?? 0),
      image: it.image || null,
      lineTotal: Number(it.price ?? 0) * Number(it.quantity ?? 0),
    })),
    productsCount,
    totalPrice,
    deliveryFee,
    /** المبلغ الذي يستلمه السائق من الزبون */
    collectFromCustomer: totalPrice + deliveryFee,
    /** المبلغ الذي يُسلّم للمتجر (بعد خصم أجرة التوصيل) */
    payToStore: totalPrice,
    notes: base.notes || '',
    notesAudioUrl: base.notesAudioUrl || null,
    driverId: base.driverId ? String(base.driverId) : null,
    createdAt: base.createdAt,
    updatedAt: base.updatedAt,
  };
}

function buildTabQuery(tab, driverId) {
  const driverOid = driverId;
  if (tab === DRIVER_ORDER_TABS.PENDING) {
    return {
      status: { $in: PENDING_DRIVER_STATUSES },
      $or: [{ driverId: null }, { driverId: { $exists: false } }],
    };
  }
  if (tab === DRIVER_ORDER_TABS.IN_PROGRESS) {
    return {
      driverId: driverOid,
      status: { $in: IN_PROGRESS_DRIVER_STATUSES },
    };
  }
  if (tab === DRIVER_ORDER_TABS.COMPLETED) {
    return {
      driverId: driverOid,
      status: { $in: COMPLETED_DRIVER_STATUSES },
    };
  }
  throw badRequest('تبويب غير صالح. استخدم pending أو in_progress أو completed', 'INVALID_TAB');
}

function populateDriverOrderQuery(query) {
  return query
    .populate({
      path: 'shopId',
      populate: { path: 'ownerId', select: 'name phone' },
    })
    .populate({
      path: 'shopPortions.shopId',
      populate: { path: 'ownerId', select: 'name phone' },
    })
    .populate('customerId driverId')
    .populate('items.productId', 'image images name')
    .populate('shopPortions.items.productId', 'image images name');
}

async function listOrders(driverId, { tab, page = 1, limit = 20 } = {}) {
  const query = buildTabQuery(tab, driverId);
  const skip = (Number(page) - 1) * Number(limit);
  const [items, total] = await Promise.all([
    populateDriverOrderQuery(
      Order.find(query).sort({ createdAt: -1 }).skip(skip).limit(Number(limit))
    ).lean(),
    Order.countDocuments(query),
  ]);
  return {
    tab,
    items: items.map((o) => formatOrderForDriver(o)),
    pagination: { page: Number(page), limit: Number(limit), total },
  };
}

async function getCounts(driverId) {
  const [pending, inProgress, completed] = await Promise.all([
    Order.countDocuments(buildTabQuery(DRIVER_ORDER_TABS.PENDING, driverId)),
    Order.countDocuments(buildTabQuery(DRIVER_ORDER_TABS.IN_PROGRESS, driverId)),
    Order.countDocuments(buildTabQuery(DRIVER_ORDER_TABS.COMPLETED, driverId)),
  ]);
  return {
    pending,
    in_progress: inProgress,
    completed,
  };
}

async function getOrderById(orderId, driverId) {
  const order = await populateDriverOrderQuery(Order.findById(orderId)).lean();
  if (!order) throw notFound('الطلب غير موجود');

  const isPending =
    PENDING_DRIVER_STATUSES.includes(order.status) &&
    (order.driverId == null || order.driverId === undefined);
  const isAssigned =
    order.driverId != null && String(order.driverId._id || order.driverId) === String(driverId);

  if (!isPending && !isAssigned) {
    throw forbidden('غير مسموح بعرض هذا الطلب');
  }
  return formatOrderForDriver(order);
}

async function acceptOrder(orderId, driverId) {
  const order = await Order.findById(orderId);
  if (!order) throw notFound('الطلب غير موجود');

  if (!PENDING_DRIVER_STATUSES.includes(order.status)) {
    throw badRequest('لا يمكن قبول الطلب في حالته الحالية', 'ACCEPT_NOT_ALLOWED');
  }
  if (order.driverId) {
    throw conflict('الطلب مُعيَّن لسائق آخر', 'ALREADY_ASSIGNED');
  }

  order.driverId = driverId;
  order.statusHistory.push({
    status: order.status,
    changedBy: driverId,
    changedByRole: 'driver',
    changedAt: new Date(),
  });
  await order.save();

  const updated = await populateDriverOrderQuery(Order.findById(orderId)).lean();
  return formatOrderForDriver(updated);
}

async function updateOrderStatus(orderId, driverId, { status }) {
  const order = await Order.findById(orderId);
  if (!order) throw notFound('الطلب غير موجود');

  const assignedId = order.driverId?.toString?.() || (order.driverId ? String(order.driverId) : null);
  if (!assignedId || assignedId !== driverId.toString()) {
    throw forbidden('هذا الطلب غير مُعيَّن لك');
  }

  const allowed = {
    [ORDER_STATUS.ON_THE_WAY]: IN_PROGRESS_DRIVER_STATUSES.filter(
      (s) => s !== ORDER_STATUS.ON_THE_WAY
    ),
    [ORDER_STATUS.DELIVERED]: [ORDER_STATUS.ON_THE_WAY, ORDER_STATUS.PREPARING, ORDER_STATUS.ACCEPTED],
    [ORDER_STATUS.CANCELED]: IN_PROGRESS_DRIVER_STATUSES,
  };

  const current = order.status;
  const permitted = allowed[status];
  if (!permitted || !permitted.includes(current)) {
    throw badRequest(`لا يمكن تغيير الحالة من "${STATUS_LABELS[current] || current}" إلى "${STATUS_LABELS[status] || status}"`, 'INVALID_TRANSITION');
  }

  const previousStatus = order.status;
  order.status = status;
  order.statusHistory.push({
    status,
    changedBy: driverId,
    changedByRole: 'driver',
    changedAt: new Date(),
  });
  await order.save();

  const { notifyOrderStatusChange } = require('../utils/telegram');
  const { notifyCustomerOrderStatusChange } = require('../utils/fcmNotifications');
  const updated = await populateDriverOrderQuery(Order.findById(orderId)).lean();
  notifyOrderStatusChange(updated, previousStatus, 'driver').catch((err) =>
    console.error('[Telegram] notifyOrderStatusChange:', err?.message)
  );

  if (previousStatus !== status) {
    notifyCustomerOrderStatusChange(updated, status);
  }

  if (status === ORDER_STATUS.DELIVERED) {
    const { notifyTrackingEnded } = require('../socket');
    notifyTrackingEnded(orderId, status);
  }

  return formatOrderForDriver(updated);
}

module.exports = {
  formatOrderForDriver,
  listOrders,
  getCounts,
  getOrderById,
  acceptOrder,
  updateOrderStatus,
  PENDING_DRIVER_STATUSES,
  IN_PROGRESS_DRIVER_STATUSES,
  COMPLETED_DRIVER_STATUSES,
};
