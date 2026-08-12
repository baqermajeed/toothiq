const adminService = require('../services/adminService');
const authService = require('../services/authService');
const { getPlatformSettings, updatePlatformSettings } = require('../services/platformSettingsService');
const env = require('../config/env');
const { parseShopBody } = require('./shopController');
const { validateCreateShopByAdmin, validateUpdateShopByAdmin } = require('../validators/shops');
const { validateCreateUserByAdmin } = require('../validators/users');
const { badRequest } = require('../utils/errors');

async function createUser(req, res, next) {
  try {
    const { error, value } = validateCreateUserByAdmin(req.body);
    if (error) {
      const message = error.details ? error.details.map((d) => d.message).join('; ') : error.message;
      return next(badRequest(message, 'VALIDATION_ERROR'));
    }
    const { password: _omitPassword, ...createUserSafe } = value || {};
    console.log('[Admin createUser] request', createUserSafe);
    const user = await authService.createUser(value);
    console.log('[Admin createUser] success', {
      userId: user?._id?.toString(),
      phone: user?.phone,
      name: user?.name,
      roles: user?.roles,
    });
    res.status(201).json({ success: true, data: user });
  } catch (err) {
    console.log('[Admin createUser] error', {
      error: err.message,
      statusCode: err.statusCode,
      phone: req.body?.phone,
    });
    next(err);
  }
}

async function createShop(req, res, next) {
  try {
    const body = parseShopBody(req.body);
    if (req.file?.path) body.image = req.file.path.replace(/\\/g, '/');
    const { error, value } = validateCreateShopByAdmin(body);
    if (error) {
      const message = error.details ? error.details.map((d) => d.message).join('; ') : error.message;
      return next(badRequest(message, 'VALIDATION_ERROR'));
    }
    const shop = await adminService.createShop(req.userId, value);
    res.status(201).json({ success: true, data: shop });
  } catch (err) {
    next(err);
  }
}

async function updateShop(req, res, next) {
  try {
    const body = parseShopBody(req.body);
    if (req.file?.path) body.image = req.file.path.replace(/\\/g, '/');
    const { error, value } = validateUpdateShopByAdmin(body);
    if (error) {
      const message = error.details ? error.details.map((d) => d.message).join('; ') : error.message;
      return next(badRequest(message, 'VALIDATION_ERROR'));
    }
    const shop = await adminService.updateShop(req.params.id, value);
    res.json({ success: true, data: shop });
  } catch (err) {
    next(err);
  }
}

async function listUsers(req, res, next) {
  try {
    const result = await adminService.listUsers(req.query);
    res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
}

async function getUserById(req, res, next) {
  try {
    const user = await adminService.getUserById(req.params.id);
    res.json({ success: true, data: user });
  } catch (err) {
    next(err);
  }
}

async function listShops(req, res, next) {
  try {
    const result = await adminService.listShops(req.query);
    res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
}

async function listOrders(req, res, next) {
  try {
    const result = await adminService.listOrders(req.query);
    res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
}

async function deliverStaleOnTheWaySilent(req, res, next) {
  try {
    const result = await adminService.deliverStaleOnTheWayBeforeTodayNoNotify(req.userId);
    res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
}

async function getOrderById(req, res, next) {
  try {
    const order = await adminService.getOrderById(req.params.id);
    res.json({ success: true, data: order });
  } catch (err) {
    next(err);
  }
}

async function updateOrderStatus(req, res, next) {
  try {
    const orderService = require('../services/orderService');
    const order = await orderService.updateStatus(
      req.params.id,
      req.userId,
      ['admin'],
      req.body
    );
    res.json({ success: true, data: order });
  } catch (err) {
    next(err);
  }
}

async function deleteOrder(req, res, next) {
  try {
    await adminService.deleteOrder(req.params.id);
    res.json({ success: true, data: { message: 'Order deleted' } });
  } catch (err) {
    next(err);
  }
}

async function listProducts(req, res, next) {
  try {
    const result = await adminService.listProducts(req.query);
    res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
}

async function deleteShop(req, res, next) {
  try {
    await adminService.deleteShop(req.params.id);
    res.json({ success: true, data: { message: 'Shop deleted' } });
  } catch (err) {
    next(err);
  }
}

async function reorderShops(req, res, next) {
  try {
    const shopIds = req.body?.shopIds;
    if (!Array.isArray(shopIds) || shopIds.length === 0) {
      return next(badRequest('shopIds مطلوب (مصفوفة معرفات المحلات بالترتيب المطلوب)'));
    }
    const result = await adminService.reorderShops(shopIds);
    res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
}

async function bulkUpdateShopsOpenHours(req, res, next) {
  try {
    const result = await adminService.bulkUpdateShopsOpenHours(req.body);
    res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
}

async function setUserActive(req, res, next) {
  try {
    const isActive = req.body.isActive !== false;
    const user = await adminService.setUserActive(req.params.id, isActive);
    res.json({ success: true, data: user });
  } catch (err) {
    next(err);
  }
}

async function updateUser(req, res, next) {
  try {
    const user = await adminService.updateUser(req.params.id, req.body);
    res.json({ success: true, data: user });
  } catch (err) {
    next(err);
  }
}

async function deleteUser(req, res, next) {
  try {
    await adminService.deleteUser(req.params.id);
    res.json({ success: true, data: { message: 'User deleted' } });
  } catch (err) {
    next(err);
  }
}

async function getStats(req, res, next) {
  try {
    const stats = await adminService.getStats();
    res.json({ success: true, data: stats });
  } catch (err) {
    next(err);
  }
}

async function getOrdersStats(req, res, next) {
  try {
    const { dateFrom, dateTo, days } = req.query;
    const stats = await adminService.getOrdersStats({
      dateFrom: dateFrom || undefined,
      dateTo: dateTo || undefined,
      days: days ? parseInt(days, 10) : 30,
    });
    res.json({ success: true, data: stats });
  } catch (err) {
    next(err);
  }
}

async function getSettings(req, res, next) {
  try {
    const platform = await getPlatformSettings();
    res.json({
      success: true,
      data: {
        deliveryEnabled: platform.deliveryEnabled,
        deliveryPauseReason: platform.deliveryPauseReason,
        globalDeliveryFee: platform.globalDeliveryFee,
        useDashboardDeliveryFee: platform.useDashboardDeliveryFee,
        platformSettingsSource: env.platformSettingsSource,
        facebookUrl: platform.facebookUrl,
        instagramUrl: platform.instagramUrl,
        supportPhone: platform.supportPhone,
        aboutUs: platform.aboutUs,
      },
    });
  } catch (err) {
    next(err);
  }
}

async function updateSettings(req, res, next) {
  try {
    const body = req.body || {};
    const keys = [
      'deliveryEnabled',
      'deliveryPauseReason',
      'globalDeliveryFee',
      'facebookUrl',
      'instagramUrl',
      'supportPhone',
      'aboutUs',
    ];
    const hasAny = keys.some((k) => Object.prototype.hasOwnProperty.call(body, k));

    if (!hasAny) {
      return next(badRequest('يجب إرسال حقل واحد على الأقل للتحديث'));
    }

    const patch = {};
    if (Object.prototype.hasOwnProperty.call(body, 'deliveryEnabled')) {
      patch.deliveryEnabled = body.deliveryEnabled;
    }
    if (Object.prototype.hasOwnProperty.call(body, 'deliveryPauseReason')) {
      patch.deliveryPauseReason = body.deliveryPauseReason;
    }
    if (Object.prototype.hasOwnProperty.call(body, 'globalDeliveryFee')) {
      patch.globalDeliveryFee = body.globalDeliveryFee;
    }
    if (Object.prototype.hasOwnProperty.call(body, 'facebookUrl')) {
      patch.facebookUrl = body.facebookUrl;
    }
    if (Object.prototype.hasOwnProperty.call(body, 'instagramUrl')) {
      patch.instagramUrl = body.instagramUrl;
    }
    if (Object.prototype.hasOwnProperty.call(body, 'supportPhone')) {
      patch.supportPhone = body.supportPhone;
    }
    if (Object.prototype.hasOwnProperty.call(body, 'aboutUs')) {
      patch.aboutUs = body.aboutUs;
    }

    await updatePlatformSettings(patch);
    const merged = await getPlatformSettings();
    res.json({
      success: true,
      data: {
        deliveryEnabled: merged.deliveryEnabled,
        deliveryPauseReason: merged.deliveryPauseReason,
        globalDeliveryFee: merged.globalDeliveryFee,
        useDashboardDeliveryFee: merged.useDashboardDeliveryFee,
        platformSettingsSource: env.platformSettingsSource,
        facebookUrl: merged.facebookUrl,
        instagramUrl: merged.instagramUrl,
        supportPhone: merged.supportPhone,
        aboutUs: merged.aboutUs,
      },
    });
  } catch (err) {
    next(err);
  }
}

const driverWalletService = require('../services/driverWalletService');

async function getDriverWallet(req, res, next) {
  try {
    const data = await driverWalletService.getWallet(req.params.driverId, {
      page: req.query.page,
      limit: req.query.limit,
    });
    res.json({ success: true, data });
  } catch (err) {
    next(err);
  }
}

async function collectDriverWallet(req, res, next) {
  try {
    const adminName = req.user?.name || 'الإدارة';
    const data = await driverWalletService.collectFromWallet(
      req.params.driverId,
      req.userId,
      adminName,
      req.body.amount
    );
    res.json({ success: true, data });
  } catch (err) {
    next(err);
  }
}

async function broadcastNotification(req, res, next) {
  try {
    const notificationService = require('../services/notificationService');
    const data = await notificationService.broadcastCatalogNotification(req.body);
    res.status(201).json({ success: true, data });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  listUsers,
  getUserById,
  listShops,
  listOrders,
  getOrderById,
  updateOrderStatus,
  deliverStaleOnTheWaySilent,
  deleteOrder,
  listProducts,
  setUserActive,
  updateUser,
  deleteUser,
  getStats,
  getOrdersStats,
  deleteShop,
  createUser,
  createShop,
  updateShop,
  reorderShops,
  bulkUpdateShopsOpenHours,
  getSettings,
  updateSettings,
  getDriverWallet,
  collectDriverWallet,
  broadcastNotification,
};
