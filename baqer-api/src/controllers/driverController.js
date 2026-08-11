const driverService = require('../services/driverService');
const driverWalletService = require('../services/driverWalletService');
const { notifyDriversOrderRemoved } = require('../socket');

async function listOrders(req, res, next) {
  try {
    const result = await driverService.listOrders(req.userId, {
      tab: req.query.tab,
      page: req.query.page,
      limit: req.query.limit,
    });
    res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
}

async function getCounts(req, res, next) {
  try {
    const counts = await driverService.getCounts(req.userId);
    res.json({ success: true, data: counts });
  } catch (err) {
    next(err);
  }
}

async function getById(req, res, next) {
  try {
    const order = await driverService.getOrderById(req.params.id, req.userId);
    res.json({ success: true, data: order });
  } catch (err) {
    next(err);
  }
}

async function acceptOrder(req, res, next) {
  try {
    const order = await driverService.acceptOrder(req.params.id, req.userId);
    notifyDriversOrderRemoved(req.params.id);
    res.json({ success: true, data: order });
  } catch (err) {
    next(err);
  }
}

async function updateStatus(req, res, next) {
  try {
    const order = await driverService.updateOrderStatus(req.params.id, req.userId, req.body);
    res.json({ success: true, data: order });
  } catch (err) {
    next(err);
  }
}

async function getWallet(req, res, next) {
  try {
    const data = await driverWalletService.getWallet(req.userId, {
      page: req.query.page,
      limit: req.query.limit,
    });
    res.json({ success: true, data });
  } catch (err) {
    next(err);
  }
}

async function getWalletTransactions(req, res, next) {
  try {
    const data = await driverWalletService.listTransactions(req.userId, {
      page: req.query.page,
      limit: req.query.limit,
    });
    res.json({ success: true, data });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  listOrders,
  getCounts,
  getById,
  acceptOrder,
  updateStatus,
  getWallet,
  getWalletTransactions,
};
