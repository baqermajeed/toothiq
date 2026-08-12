const fcmService = require('../services/fcmService');
const { User } = require('../models');
const { ORDER_STATUS } = require('../config/constants');

const APP_TITLE = 'ToothIQ';

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
    body: 'طلبك قيد التوصيل، اضغط لتتبع الطلب على الخريطة',
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
 * إشعار العميل بأي تحديث لحالة الطلب (fire-and-forget).
 * يتخطى pending والحالة غير المعروفة.
 */
function notifyCustomerOrderStatusChange(order, newStatus) {
  const status = String(newStatus || order?.status || '').trim();
  if (!status || status === ORDER_STATUS.PENDING) return;

  const payload = STATUS_PAYLOAD[status];
  if (!payload) return;

  const orderId = resolveOrderId(order);
  const customerId = resolveCustomerId(order);
  if (!customerId || !orderId) return;

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

  User.findById(customerId)
    .select('fcmTokens')
    .lean()
    .then((user) => {
      const tokens = user?.fcmTokens || [];
      if (tokens.length === 0) return;
      return fcmService.sendToTokens(tokens, {
        title: APP_TITLE,
        body,
        data,
      });
    })
    .catch((err) =>
      console.error('[FCM] notifyCustomerOrderStatusChange:', err.message)
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

module.exports = {
  notifyCustomerOrderStatusChange,
  notifyCustomerOrderAccepted,
  notifyCustomerOrderPreparing,
  notifyCustomerOrderOnTheWay,
  notifyCustomerOrderDelivered,
  notifyCustomerOrderCanceled,
  notifyCustomerOrderPostponed,
};
