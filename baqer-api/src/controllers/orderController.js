const path = require('path');
const orderService = require('../services/orderService');
const {
  notifyTrackingEnded,
  notifyShopNewOrder,
} = require('../socket');
const { notifyNewOrder } = require('../utils/telegram');
const { ORDER_STATUS } = require('../config/constants');
const { notifyDriversNewOrder: emitDriverNewOrder } = require('../socket');

async function list(req, res, next) {
  try {
    const result = await orderService.listByUser(
      req.userId,
      req.userRoles || [],
      req.query
    );
    res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
}

async function uploadNoteAudio(req, res, next) {
  try {
    if (!req.file) {
      return res.status(400).json({ success: false, message: 'لم يُرفع أي ملف صوتي' });
    }
    const relativePath = path.join('uploads', 'order-notes', req.file.filename).replace(/\\/g, '/');
    const url = `/${relativePath}`;
    res.json({ success: true, data: { url } });
  } catch (err) {
    next(err);
  }
}

async function create(req, res, next) {
  try {
    const order = await orderService.create(req.userId, req.body);
    notifyShopNewOrder(order);
    notifyNewOrder(order).catch((err) => console.error('[Telegram] notifyNewOrder:', err?.message));
    res.status(201).json({ success: true, data: order });
  } catch (err) {
    next(err);
  }
}

async function createVoiceOrder(req, res, next) {
  try {
    const order = await orderService.createVoiceOrder(req.userId, req.body);
    notifyShopNewOrder(order);
    notifyNewOrder(order).catch((err) => console.error('[Telegram] notifyNewOrder:', err?.message));
    res.status(201).json({ success: true, data: order });
  } catch (err) {
    next(err);
  }
}

async function getById(req, res, next) {
  try {
    const order = await orderService.getById(
      req.params.id,
      req.userId,
      req.userRoles || []
    );
    res.json({ success: true, data: order });
  } catch (err) {
    next(err);
  }
}

async function getCallTargets(req, res, next) {
  try {
    const data = await orderService.getCallTargets(
      req.params.id,
      req.userId,
      req.userRoles || []
    );
    res.json({ success: true, data });
  } catch (err) {
    next(err);
  }
}

async function updateStatus(req, res, next) {
  try {
    const order = await orderService.updateStatus(
      req.params.id,
      req.userId,
      req.userRoles || [],
      req.body
    );
    if (order) {
      if (order.status !== ORDER_STATUS.ON_THE_WAY) {
        notifyTrackingEnded(req.params.id, order.status);
      }
    }
    if (order && order.status === ORDER_STATUS.ACCEPTED && !order.driverId) {
      emitDriverNewOrder(order);
    }
    if (order && order.status === ORDER_STATUS.PREPARING && !order.driverId) {
      emitDriverNewOrder(order);
    }
    const response = { success: true, data: order };
    console.log('[Order updateStatus]', {
      orderId: req.params.id,
      userId: req.userId,
      reqBody: req.body,
      newStatus: order?.status,
      response: response,
    });
    res.json(response);
  } catch (err) {
    console.log('[Order updateStatus] ERROR', {
      orderId: req.params.id,
      userId: req.userId,
      reqBody: req.body,
      error: err.message,
      statusCode: err.statusCode,
    });
    next(err);
  }
}

async function cancelByCustomer(req, res, next) {
  try {
    const order = await orderService.cancelByCustomer(req.params.id, req.userId);
    res.json({ success: true, data: order });
  } catch (err) {
    next(err);
  }
}

async function getDriverReview(req, res, next) {
  try {
    const driverReviewService = require('../services/driverReviewService');
    const review = await driverReviewService.getForOrder(req.params.id, req.userId);
    res.json({ success: true, data: review });
  } catch (err) {
    next(err);
  }
}

async function createDriverReview(req, res, next) {
  try {
    const driverReviewService = require('../services/driverReviewService');
    const review = await driverReviewService.upsertForOrder(
      req.params.id,
      req.userId,
      req.body
    );
    res.status(201).json({ success: true, data: review });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  list,
  uploadNoteAudio,
  create,
  createVoiceOrder,
  getById,
  getCallTargets,
  updateStatus,
  cancelByCustomer,
  getDriverReview,
  createDriverReview,
};
