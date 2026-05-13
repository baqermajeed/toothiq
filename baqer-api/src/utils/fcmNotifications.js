const fcmService = require('../services/fcmService');
const { User } = require('../models');

/**
 * Notify customer that their order has been accepted and is being prepared. Fire-and-forget.
 * @param {object} order - Order document with populated customerId or customerId as ObjectId
 */
function notifyCustomerOrderAccepted(order) {
  const orderId = order._id?.toString?.() || String(order._id);
  const customerId = order.customerId?._id || order.customerId;
  if (!customerId) return;
  User.findById(customerId)
    .select('fcmTokens')
    .lean()
    .then((user) => {
      const tokens = user?.fcmTokens || [];
      if (tokens.length === 0) return;
      return fcmService.sendToTokens(tokens, {
        title: 'Qaryp',
        body: 'جار التسوق وتحضير طلبك',
        data: { type: 'order_accepted', orderId },
      });
    })
    .catch((err) => console.error('[FCM] notifyCustomerOrderAccepted:', err.message));
}

/**
 * Notify customer that their order is on the way. Fire-and-forget.
 * @param {object} order - Order document with populated customerId or customerId as ObjectId
 */
function notifyCustomerOrderOnTheWay(order) {
  const orderId = order._id?.toString?.() || String(order._id);
  const customerId = order.customerId?._id || order.customerId;
  if (!customerId) return;
  User.findById(customerId)
    .select('fcmTokens')
    .lean()
    .then((user) => {
      const tokens = user?.fcmTokens || [];
      if (tokens.length === 0) return;
      return fcmService.sendToTokens(tokens, {
        title: 'Qaryp',
        body: 'طلبك قيد التوصيل، اضغط لتتبع الطلب على الخريطة',
        data: { type: 'order_on_the_way', orderId },
      });
    })
    .catch((err) => console.error('[FCM] notifyCustomerOrderOnTheWay:', err.message));
}

/**
 * Notify customer that their order has been delivered. Fire-and-forget.
 * @param {object} order - Order document with populated customerId or customerId as ObjectId
 */
function notifyCustomerOrderDelivered(order) {
  const orderId = order._id?.toString?.() || String(order._id);
  const customerId = order.customerId?._id || order.customerId;
  if (!customerId) return;
  User.findById(customerId)
    .select('fcmTokens')
    .lean()
    .then((user) => {
      const tokens = user?.fcmTokens || [];
      if (tokens.length === 0) return;
      return fcmService.sendToTokens(tokens, {
        title: 'Qaryp',
        body: 'تم إيصال طلبك بنجاح. شكراً لثقتك بنا.',
        data: { type: 'order_delivered', orderId },
      });
    })
    .catch((err) => console.error('[FCM] notifyCustomerOrderDelivered:', err.message));
}

/**
 * Notify customer that their order was canceled, with optional reason. Fire-and-forget.
 * @param {object} order - Order document with populated customerId, optional cancelReason, and statusHistory
 */
function notifyCustomerOrderCanceled(order) {
  const orderId = order._id?.toString?.() || String(order._id);
  const customerId = order.customerId?._id || order.customerId;
  if (!customerId) return;
  const reason = (order.cancelReason || '').trim();
  const lastEntry = order.statusHistory?.length
    ? order.statusHistory[order.statusHistory.length - 1]
    : null;
  const canceledByAdmin = lastEntry?.changedByRole === 'admin';
  const displayReason =
    reason || (canceledByAdmin ? 'تم رفض الطلب من الإدارة' : null);
  const body = displayReason
    ? `تم إلغاء طلبك. سبب الإلغاء: ${displayReason}`
    : 'تم إلغاء طلبك.';
  User.findById(customerId)
    .select('fcmTokens')
    .lean()
    .then((user) => {
      const tokens = user?.fcmTokens || [];
      if (tokens.length === 0) return;
      return fcmService.sendToTokens(tokens, {
        title: 'Qaryp',
        body,
        data: { type: 'order_canceled', orderId, cancelReason: displayReason || '' },
      });
    })
    .catch((err) => console.error('[FCM] notifyCustomerOrderCanceled:', err.message));
}

module.exports = {
  notifyCustomerOrderAccepted,
  notifyCustomerOrderOnTheWay,
  notifyCustomerOrderDelivered,
  notifyCustomerOrderCanceled,
};
