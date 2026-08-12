const { Notification, User, Product, Shop } = require('../models');
const { ROLES } = require('../config/constants');
const { notFound, badRequest } = require('../utils/errors');
const fcmService = require('./fcmService');

function mapNotification(doc) {
  const data = doc.data || {};
  return {
    id: doc._id.toString(),
    title: doc.title,
    body: doc.body,
    description: doc.body,
    type: doc.type,
    orderId: doc.orderId ? doc.orderId.toString() : null,
    productId: data.productId ? String(data.productId) : null,
    shopId: data.shopId ? String(data.shopId) : null,
    storeId: data.storeId ? String(data.storeId) : null,
    data,
    isRead: doc.isRead === true,
    createdAt: doc.createdAt,
  };
}

async function createForUser({
  userId,
  title,
  body,
  type,
  orderId = null,
  data = {},
}) {
  if (!userId) return null;
  const doc = await Notification.create({
    userId,
    title,
    body,
    type,
    orderId: orderId || null,
    data,
    isRead: false,
  });
  return mapNotification(doc);
}

async function listForUser(userId, { limit = 50 } = {}) {
  const safeLimit = Math.min(Math.max(Number(limit) || 50, 1), 100);
  const items = await Notification.find({ userId })
    .sort({ createdAt: -1 })
    .limit(safeLimit)
    .lean();
  return items.map(mapNotification);
}

async function unreadCount(userId) {
  return Notification.countDocuments({ userId, isRead: false });
}

async function markAsRead(userId, notificationId) {
  const doc = await Notification.findOne({ _id: notificationId, userId });
  if (!doc) throw notFound('الإشعار غير موجود');
  if (!doc.isRead) {
    doc.isRead = true;
    await doc.save();
  }
  return mapNotification(doc);
}

async function markAllAsRead(userId) {
  await Notification.updateMany(
    { userId, isRead: false },
    { $set: { isRead: true } }
  );
  return { ok: true };
}

/**
 * بث إشعار منتج أو متجر لكل العملاء + FCM.
 */
async function broadcastCatalogNotification({
  title,
  body,
  type,
  productId,
  shopId,
}) {
  const cleanTitle = String(title || '').trim();
  const cleanBody = String(body || '').trim();
  const cleanType = String(type || '').trim();

  if (!cleanTitle || cleanTitle.length < 2) {
    throw badRequest('عنوان الإشعار مطلوب');
  }
  if (!cleanBody || cleanBody.length < 2) {
    throw badRequest('نص الإشعار مطلوب');
  }
  if (cleanType !== 'product' && cleanType !== 'store') {
    throw badRequest('نوع الإشعار يجب أن يكون product أو store');
  }

  let resolvedShopId = shopId ? String(shopId).trim() : '';
  let resolvedProductId = productId ? String(productId).trim() : '';

  if (cleanType === 'product') {
    if (!resolvedProductId) throw badRequest('معرّف المنتج مطلوب');
    const product = await Product.findById(resolvedProductId).lean();
    if (!product) throw notFound('المنتج غير موجود');
    resolvedShopId =
      resolvedShopId ||
      product.shopId?._id?.toString?.() ||
      product.shopId?.toString?.() ||
      '';
    if (!resolvedShopId) throw badRequest('المنتج غير مرتبط بمتجر');
  } else {
    if (!resolvedShopId) throw badRequest('معرّف المتجر مطلوب');
    const shop = await Shop.findById(resolvedShopId).lean();
    if (!shop) throw notFound('المتجر غير موجود');
  }

  const data = {
    type: cleanType,
    ...(cleanType === 'product'
      ? { productId: resolvedProductId, shopId: resolvedShopId }
      : { storeId: resolvedShopId, shopId: resolvedShopId }),
  };

  const customers = await User.find({
    isActive: { $ne: false },
    $or: [
      { roles: ROLES.CUSTOMER },
      { fcmTokens: { $exists: true, $ne: [] } },
    ],
  })
    .select('_id +fcmTokens')
    .lean();

  const docs = customers.map((u) => ({
    userId: u._id,
    title: cleanTitle,
    body: cleanBody,
    type: cleanType,
    orderId: null,
    data,
    isRead: false,
  }));

  let inboxCount = 0;
  const chunkSize = 500;
  for (let i = 0; i < docs.length; i += chunkSize) {
    const chunk = docs.slice(i, i + chunkSize);
    if (chunk.length === 0) continue;
    const inserted = await Notification.insertMany(chunk, { ordered: false });
    inboxCount += inserted.length;
  }

  const tokenSet = new Set();
  for (const user of customers) {
    for (const token of user.fcmTokens || []) {
      if (token && typeof token === 'string') tokenSet.add(token);
    }
  }
  const tokens = [...tokenSet];

  let fcmTokensResult = { successCount: 0, failureCount: 0 };
  for (let i = 0; i < tokens.length; i += 500) {
    const chunk = tokens.slice(i, i + 500);
    const result = await fcmService.sendToTokens(chunk, {
      title: cleanTitle,
      body: cleanBody,
      data,
    });
    fcmTokensResult.successCount += result.successCount || 0;
    fcmTokensResult.failureCount += result.failureCount || 0;
  }

  const topicMessageId = await fcmService.sendToTopic('all_users', {
    title: cleanTitle,
    body: cleanBody,
    data,
  });

  console.log('[Notify] broadcast catalog', {
    type: cleanType,
    productId: resolvedProductId || null,
    shopId: resolvedShopId,
    inboxCount,
    tokens: tokens.length,
    fcmTokensResult,
    topicMessageId,
  });

  return {
    type: cleanType,
    title: cleanTitle,
    body: cleanBody,
    productId: resolvedProductId || null,
    shopId: resolvedShopId,
    inboxCount,
    fcm: {
      tokens: fcmTokensResult,
      topic: topicMessageId ? 'all_users' : null,
    },
  };
}

module.exports = {
  createForUser,
  listForUser,
  unreadCount,
  markAsRead,
  markAllAsRead,
  mapNotification,
  broadcastCatalogNotification,
};
