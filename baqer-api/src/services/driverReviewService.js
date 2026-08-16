const mongoose = require('mongoose');
const { Order, User, DriverReview } = require('../models');
const { ORDER_STATUS } = require('../config/constants');
const { notFound, forbidden, badRequest } = require('../utils/errors');

function serializeReview(review) {
  if (!review) return null;
  const obj = review.toObject ? review.toObject() : { ...review };
  const customer = obj.customerId;
  const order = obj.orderId;
  return {
    id: String(obj._id || obj.id || ''),
    orderId:
      order && typeof order === 'object'
        ? String(order._id || order.id || '')
        : obj.orderId
          ? String(obj.orderId)
          : '',
    orderNumber:
      order && typeof order === 'object' && order.orderNumber != null
        ? order.orderNumber
        : null,
    driverId: obj.driverId ? String(obj.driverId._id || obj.driverId) : '',
    customerId:
      customer && typeof customer === 'object'
        ? String(customer._id || customer.id || '')
        : obj.customerId
          ? String(obj.customerId)
          : '',
    customerName:
      customer && typeof customer === 'object' ? customer.name || '' : '',
    customerPhone:
      customer && typeof customer === 'object' ? customer.phone || '' : '',
    rating: obj.rating,
    comment: obj.comment || '',
    createdAt: obj.createdAt,
    updatedAt: obj.updatedAt,
  };
}

function toClientReview(review) {
  if (!review) return null;
  const obj = review.toObject ? review.toObject() : review;
  return {
    id: String(obj._id || obj.id || ''),
    rating: obj.rating,
    comment: obj.comment || '',
    createdAt: obj.createdAt,
  };
}

async function refreshDriverRating(driverId) {
  const stats = await DriverReview.aggregate([
    { $match: { driverId: new mongoose.Types.ObjectId(String(driverId)) } },
    {
      $group: {
        _id: '$driverId',
        avgRating: { $avg: '$rating' },
        ratingCount: { $sum: 1 },
      },
    },
  ]);

  const avgRating = stats[0]?.avgRating || 0;
  const ratingCount = stats[0]?.ratingCount || 0;

  await User.findByIdAndUpdate(driverId, {
    rating: Number(avgRating.toFixed(2)),
    ratingCount,
  });
}

async function getForOrder(orderId, customerId) {
  const order = await Order.findById(orderId).select('customerId').lean();
  if (!order) throw notFound('الطلب غير موجود');
  if (String(order.customerId) !== String(customerId)) {
    throw forbidden('غير مسموح بتقييم هذا الطلب');
  }
  const review = await DriverReview.findOne({ orderId }).lean();
  return toClientReview(review);
}

async function upsertForOrder(orderId, customerId, body) {
  const order = await Order.findById(orderId)
    .select('customerId driverId status')
    .lean();
  if (!order) throw notFound('الطلب غير موجود');
  if (String(order.customerId) !== String(customerId)) {
    throw forbidden('غير مسموح بتقييم هذا الطلب');
  }
  if (order.status !== ORDER_STATUS.DELIVERED) {
    throw badRequest('يمكن تقييم السائق بعد استلام الطلب فقط');
  }
  if (!order.driverId) {
    throw badRequest('لا يوجد سائق مرتبط بهذا الطلب');
  }
  if (String(order.driverId) === String(customerId)) {
    throw forbidden('لا يمكن تقييم هذا الطلب');
  }

  const review = await DriverReview.findOneAndUpdate(
    { orderId },
    {
      orderId,
      driverId: order.driverId,
      customerId,
      rating: body.rating,
      comment: body.comment || '',
    },
    { new: true, upsert: true, setDefaultsOnInsert: true }
  );

  await refreshDriverRating(order.driverId);
  return toClientReview(review);
}

async function listForDriver(driverId, query = {}) {
  const driver = await User.findById(driverId).select('_id roles').lean();
  if (!driver || !Array.isArray(driver.roles) || !driver.roles.includes('driver')) {
    throw notFound('السائق غير موجود');
  }

  const pageNum = Math.max(Number(query.page) || 1, 1);
  const limitNum = Math.min(Math.max(Number(query.limit) || 20, 1), 100);
  const skip = (pageNum - 1) * limitNum;

  const [items, total] = await Promise.all([
    DriverReview.find({ driverId })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limitNum)
      .populate('customerId', 'name phone')
      .populate('orderId', 'orderNumber status createdAt totalPrice deliveryFee')
      .lean(),
    DriverReview.countDocuments({ driverId }),
  ]);

  return {
    items: items.map(serializeReview),
    pagination: { page: pageNum, limit: limitNum, total },
  };
}

async function attachToOrder(orderObj) {
  if (!orderObj) return orderObj;
  const orderId = orderObj._id || orderObj.id;
  if (!orderId) {
    orderObj.driverReview = null;
    return orderObj;
  }
  const review = await DriverReview.findOne({ orderId }).lean();
  orderObj.driverReview = toClientReview(review);
  return orderObj;
}

module.exports = {
  upsertForOrder,
  getForOrder,
  listForDriver,
  attachToOrder,
  refreshDriverRating,
};
