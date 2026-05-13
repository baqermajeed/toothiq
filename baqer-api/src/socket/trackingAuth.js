const mongoose = require('mongoose');
const { Order } = require('../models');
const { ORDER_STATUS } = require('../config/constants');

/**
 * Check if the user (customer) can subscribe to driver tracking for this order.
 * Only the order customer can subscribe, and only when status is on_the_way.
 * @param {string} orderId - Order ID
 * @param {mongoose.Types.ObjectId} userId - User ID (must be customer of the order)
 * @returns {Promise<{ ok: boolean, order?: object, error?: string }>}
 */
async function canCustomerSubscribe(orderId, userId) {
  if (!orderId || !mongoose.Types.ObjectId.isValid(orderId)) {
    return { ok: false, error: 'Invalid order id' };
  }
  const order = await Order.findById(orderId).lean();
  if (!order) return { ok: false, error: 'Order not found' };
  const customerIdStr = order.customerId?.toString?.() || order.customerId?.toString();
  if (customerIdStr !== userId.toString()) {
    return { ok: false, error: 'Not allowed to track this order' };
  }
  if (order.status !== ORDER_STATUS.ON_THE_WAY) {
    return { ok: false, error: 'Order is not on the way' };
  }
  return { ok: true, order };
}

/**
 * Check if the user (driver) can send location updates for this order.
 * Only the assigned driver can send, and only when status is on_the_way.
 * @param {string} orderId - Order ID
 * @param {mongoose.Types.ObjectId} userId - User ID (must be driver of the order)
 * @returns {Promise<{ ok: boolean, order?: object, error?: string }>}
 */
async function canDriverSendLocation(orderId, userId) {
  if (!orderId || !mongoose.Types.ObjectId.isValid(orderId)) {
    return { ok: false, error: 'Invalid order id' };
  }
  const order = await Order.findById(orderId).lean();
  if (!order) return { ok: false, error: 'Order not found' };
  const driverIdStr = order.driverId?.toString?.() || order.driverId?.toString();
  if (!driverIdStr || driverIdStr !== userId.toString()) {
    return { ok: false, error: 'Not the driver of this order' };
  }
  if (order.status !== ORDER_STATUS.ON_THE_WAY) {
    return { ok: false, error: 'Order is not on the way' };
  }
  return { ok: true, order };
}

module.exports = { canCustomerSubscribe, canDriverSendLocation };
