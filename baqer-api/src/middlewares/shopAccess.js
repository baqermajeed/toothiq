const { Shop } = require('../models');
const { notFound, forbidden } = require('../utils/errors');

/**
 * يتحقق أن المستخدم مالك المحل أو أدمن. يُرفق req.shop عند النجاح.
 */
async function requireShopOwnerOrAdmin(req, res, next) {
  const shopId = req.params.shopId;
  if (!shopId) return next(forbidden('معرّف المحل مطلوب'));
  const shop = await Shop.findById(shopId).select('ownerId name').lean();
  if (!shop) return next(notFound('المحل غير موجود'));
  const roles = Array.isArray(req.userRoles) ? req.userRoles : [];
  const isAdmin = roles.includes('admin');
  const isOwner =
    shop.ownerId &&
    req.userId &&
    shop.ownerId.toString() === req.userId.toString();
  if (!isAdmin && !isOwner) {
    return next(forbidden('غير مسموح لك بإدارة هذا المحل'));
  }
  req.shop = shop;
  next();
}

module.exports = { requireShopOwnerOrAdmin };
