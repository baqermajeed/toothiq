const fcmService = require('../services/fcmService');
const notificationService = require('../services/notificationService');
const { User, Shop } = require('../models');
const { ORDER_STATUS, ROLES } = require('../config/constants');

const APP_TITLE = 'ToothIQ';
const PARTNER_ANDROID_CHANNEL = 'toothiq_partner_notifications';

const STATUS_PAYLOAD = {
  [ORDER_STATUS.ACCEPTED]: {
    type: 'order_accepted',
    body: 'تم قبول طلبك وجارٍ التسوق والتحضير',
  },
  [ORDER_STATUS.PREPARING]: {
    type: 'order_preparing',
    body: 'جارٍ تحضير طلبك الآن',
  },
  [ORDER_STATUS.ON_THE_WAY]: {
    type: 'order_on_the_way',
    body: 'طلبك قيد التوصيل , الطلب في طريقه اليك',
  },
  [ORDER_STATUS.DELIVERED]: {
    type: 'order_delivered',
    body: 'تم إيصال طلبك بنجاح. شكراً لثقتك بنا.',
  },
  [ORDER_STATUS.CANCELED]: {
    type: 'order_canceled',
    body: 'تم إلغاء طلبك.',
  },
  [ORDER_STATUS.POSTPONED]: {
    type: 'order_postponed',
    body: 'تم تأجيل طلبك.',
  },
};

function resolveCustomerId(order) {
  const raw = order?.customerId;
  if (!raw) return null;
  if (typeof raw === 'object') {
    return raw._id || raw.id || null;
  }
  return raw;
}

function resolveOrderId(order) {
  return order?._id?.toString?.() || (order?._id != null ? String(order._id) : '');
}

function canceledBody(order) {
  const reason = (order.cancelReason || '').trim();
  const lastEntry = order.statusHistory?.length
    ? order.statusHistory[order.statusHistory.length - 1]
    : null;
  const canceledByAdmin = lastEntry?.changedByRole === 'admin';
  const displayReason =
    reason || (canceledByAdmin ? 'تم رفض الطلب من الإدارة' : null);
  return {
    body: displayReason
      ? `تم إلغاء طلبك. سبب الإلغاء: ${displayReason}`
      : 'تم إلغاء طلبك.',
    cancelReason: displayReason || '',
  };
}

function postponedBody(order) {
  const reason = (order.postponedReason || '').trim();
  return {
    body: reason ? `تم تأجيل طلبك. السبب: ${reason}` : 'تم تأجيل طلبك.',
    postponedReason: reason,
  };
}

/**
 * يحفظ إشعار الطلب في قاعدة البيانات ثم يحاول إرسال FCM (fire-and-forget).
 */
function notifyCustomerOrderStatusChange(order, newStatus) {
  const status = String(newStatus || order?.status || '').trim();
  if (!status || status === ORDER_STATUS.PENDING) return;

  const payload = STATUS_PAYLOAD[status];
  if (!payload) return;

  const orderId = resolveOrderId(order);
  const customerId = resolveCustomerId(order);
  if (!customerId || !orderId) {
    console.warn('[Notify] skip: missing customerId/orderId', {
      status,
      orderId,
      customerId: customerId ? String(customerId) : null,
    });
    return;
  }

  let body = payload.body;
  const data = { type: payload.type, orderId };

  if (status === ORDER_STATUS.CANCELED) {
    const canceled = canceledBody(order);
    body = canceled.body;
    data.cancelReason = canceled.cancelReason;
  } else if (status === ORDER_STATUS.POSTPONED) {
    const postponed = postponedBody(order);
    body = postponed.body;
    data.postponedReason = postponed.postponedReason;
  }

  const title = APP_TITLE;

  Promise.resolve()
    .then(async () => {
      await notificationService.createForUser({
        userId: customerId,
        title,
        body,
        type: payload.type,
        orderId,
        data,
      });
      console.log('[Notify] saved inbox', {
        userId: String(customerId),
        orderId,
        type: payload.type,
      });

      const user = await User.findById(customerId).select('+fcmTokens').lean();
      const tokens = user?.fcmTokens || [];
      if (tokens.length === 0) {
        console.warn('[Notify] no FCM tokens for user', String(customerId));
        return;
      }

      const result = await fcmService.sendToTokens(tokens, {
        title,
        body,
        data,
      });
      console.log('[Notify] FCM result', {
        userId: String(customerId),
        orderId,
        type: payload.type,
        tokens: tokens.length,
        ...result,
      });
    })
    .catch((err) =>
      console.error('[Notify] notifyCustomerOrderStatusChange:', err.message)
    );
}

function notifyCustomerOrderAccepted(order) {
  notifyCustomerOrderStatusChange(order, ORDER_STATUS.ACCEPTED);
}

function notifyCustomerOrderPreparing(order) {
  notifyCustomerOrderStatusChange(order, ORDER_STATUS.PREPARING);
}

function notifyCustomerOrderOnTheWay(order) {
  notifyCustomerOrderStatusChange(order, ORDER_STATUS.ON_THE_WAY);
}

function notifyCustomerOrderDelivered(order) {
  notifyCustomerOrderStatusChange(order, ORDER_STATUS.DELIVERED);
}

function notifyCustomerOrderCanceled(order) {
  notifyCustomerOrderStatusChange(order, ORDER_STATUS.CANCELED);
}

function notifyCustomerOrderPostponed(order) {
  notifyCustomerOrderStatusChange(order, ORDER_STATUS.POSTPONED);
}

const DRIVER_AVAILABLE_STATUSES = new Set([
  ORDER_STATUS.ACCEPTED,
  ORDER_STATUS.PREPARING,
  ORDER_STATUS.ON_THE_WAY,
]);

function resolveId(raw) {
  if (!raw) return null;
  if (typeof raw === 'object') {
    return raw._id || raw.id || null;
  }
  return raw;
}

function collectShopIds(order) {
  const ids = new Set();
  const shopId = resolveId(order?.shopId);
  if (shopId) ids.add(String(shopId));
  for (const portion of order?.shopPortions || []) {
    const id = resolveId(portion?.shopId);
    if (id) ids.add(String(id));
  }
  return [...ids];
}

function orderLabel(order) {
  const number = order?.orderNumber != null ? String(order.orderNumber) : '';
  return number ? `#${number}` : '';
}

async function sendToUserIds(userIds, { title, body, type, orderId, data = {}, androidChannelId } = {}) {
  const unique = [
    ...new Set(
      (userIds || [])
        .map((id) => (id != null ? String(id) : ''))
        .filter(Boolean)
    ),
  ];
  if (unique.length === 0) return;

  await Promise.allSettled(
    unique.map((userId) =>
      notificationService.createForUser({
        userId,
        title,
        body,
        type,
        orderId,
        data,
      })
    )
  );

  const users = await User.find({ _id: { $in: unique } })
    .select('_id +fcmTokens')
    .lean();
  const tokens = [];
  for (const user of users) {
    for (const token of user.fcmTokens || []) {
      if (token) tokens.push(token);
    }
  }
  if (tokens.length === 0) {
    console.warn('[Notify] no FCM tokens for users', { type, count: unique.length });
    return;
  }
  const result = await fcmService.sendToTokens(tokens, {
    title,
    body,
    data,
    androidChannelId,
  });
  console.log('[Notify] FCM users', {
    type,
    orderId,
    users: unique.length,
    tokens: tokens.length,
    ...result,
  });
}

/**
 * إشعار أصحاب المتاجر بوصول طلب جديد.
 */
function notifyShopOwnersNewOrder(order) {
  const orderId = resolveOrderId(order);
  if (!orderId) return;

  Promise.resolve()
    .then(async () => {
      const shopIds = collectShopIds(order);
      if (shopIds.length === 0) return;

      const shops = await Shop.find({ _id: { $in: shopIds } })
        .select('ownerId')
        .lean();
      const ownerIds = shops
        .map((shop) => resolveId(shop.ownerId))
        .filter(Boolean);

      if (ownerIds.length === 0) {
        console.warn('[Notify] shop new order: no owners', { orderId, shopIds });
        return;
      }

      console.log('[Notify] shop new order', {
        orderId,
        shopIds,
        owners: ownerIds.map(String),
      });

      const label = orderLabel(order);
      const title = APP_TITLE;
      const body = label
        ? `لديك طلب جديد ${label} بانتظار القبول`
        : 'لديك طلب جديد بانتظار القبول';
      const data = { type: 'shop_new_order', orderId, role: 'shop' };

      await sendToUserIds(ownerIds, {
        title,
        body,
        type: 'shop_new_order',
        orderId,
        data,
        androidChannelId: PARTNER_ANDROID_CHANNEL,
      });

      await Promise.allSettled(
        shopIds.map((shopId) =>
          fcmService.sendToTopic(`shop_${shopId}`, {
            title,
            body,
            data,
            androidChannelId: PARTNER_ANDROID_CHANNEL,
          })
        )
      );
    })
    .catch((err) =>
      console.error('[Notify] notifyShopOwnersNewOrder:', err.message)
    );
}

/**
 * إشعار السائقين عندما يصبح الطلب جاهزاً للتوصيل (أول دخول لمجموعة القبول).
 */
function notifyDriversNewOrderAvailable(order, previousStatus) {
  const orderId = resolveOrderId(order);
  const status = String(order?.status || '').trim();
  const driverId = resolveId(order?.driverId);
  const prev = String(previousStatus || '').trim();

  if (!orderId || driverId) return;
  if (!DRIVER_AVAILABLE_STATUSES.has(status)) return;
  if (DRIVER_AVAILABLE_STATUSES.has(prev)) return;

  Promise.resolve()
    .then(async () => {
      const drivers = await User.find({
        isActive: { $ne: false },
        roles: ROLES.DRIVER,
      })
        .select('_id +fcmTokens')
        .lean();
      const driverIds = drivers.map((d) => d._id);

      const label = orderLabel(order);
      const title = APP_TITLE;
      const body = label
        ? `طلب جديد ${label} جاهز للتوصيل`
        : 'طلب جديد جاهز للتوصيل';
      const data = { type: 'driver_new_order', orderId, role: 'driver' };

      await sendToUserIds(driverIds, {
        title,
        body,
        type: 'driver_new_order',
        orderId,
        data,
        androidChannelId: PARTNER_ANDROID_CHANNEL,
      });

      await fcmService.sendToTopic('all_drivers', {
        title,
        body,
        data,
        androidChannelId: PARTNER_ANDROID_CHANNEL,
      });
    })
    .catch((err) =>
      console.error('[Notify] notifyDriversNewOrderAvailable:', err.message)
    );
}

module.exports = {
  notifyCustomerOrderStatusChange,
  notifyCustomerOrderAccepted,
  notifyCustomerOrderPreparing,
  notifyCustomerOrderOnTheWay,
  notifyCustomerOrderDelivered,
  notifyCustomerOrderCanceled,
  notifyCustomerOrderPostponed,
  notifyShopOwnersNewOrder,
  notifyDriversNewOrderAvailable,
};
