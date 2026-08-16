const mongoose = require('mongoose');
const bcrypt = require('bcrypt');
const { User, Shop, Order, Product } = require('../models');
const authService = require('./authService');
const env = require('../config/env');
const { ROLES } = require('../config/constants');
const { deleteProductImageIfLocal, getMissingImageMongoCondition } = require('./productService');
const { notFound, badRequest } = require('../utils/errors');

/** إجمالي الطلب في تجميعات الإحصائيات: منتجات + توصيل */
const ORDER_GRAND_TOTAL_ADD = {
  $add: ['$totalPrice', '$deliveryFee'],
};

async function listUsers(filters = {}) {
  const { page = 1, limit = 20, isActive, role, q } = filters;
  const query = {};
  if (typeof isActive === 'boolean') query.isActive = isActive;
  if (role) query.roles = role;
  if (q && typeof q === 'string' && q.trim()) {
    const safe = q.trim().replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const regex = new RegExp(safe, 'i');
    query.$or = [
      { name: regex },
      { phone: regex },
      { email: regex },
    ];
  }
  const skip = (Number(page) - 1) * Number(limit);
  const sort = role === ROLES.DRIVER
    ? { rating: -1, ratingCount: -1, name: 1 }
    : { createdAt: -1 };
  const [items, total] = await Promise.all([
    User.find(query).select('-passwordHash -refreshTokenHash').sort(sort).skip(skip).limit(Number(limit)).lean(),
    User.countDocuments(query),
  ]);
  return { items, pagination: { page: Number(page), limit: Number(limit), total } };
}

async function getUserById(userId) {
  const user = await User.findById(userId).select('-passwordHash -refreshTokenHash').lean();
  if (!user) throw notFound('المستخدم غير موجود');
  return user;
}

async function listShops(filters = {}) {
  const { page = 1, limit = 20, isActive } = filters;
  const query = {};
  if (typeof isActive === 'boolean') query.isActive = isActive;
  const skip = (Number(page) - 1) * Number(limit);
  const [items, total] = await Promise.all([
    Shop.find(query).populate('ownerId', 'name phone').sort({ order: 1, createdAt: 1 }).skip(skip).limit(Number(limit)).lean(),
    Shop.countDocuments(query),
  ]);
  return { items, pagination: { page: Number(page), limit: Number(limit), total } };
}

/**
 * طلبات «في الطريق» التي تاريخ إنشائها قبل اليوم (حسب توقيت الخادم) → «تم التوصيل»
 * بدون أي إشعارات (FCM / تيليجرام / سوكت).
 */
async function deliverStaleOnTheWayBeforeTodayNoNotify(adminUserId) {
  const { ORDER_STATUS } = require('../config/constants');
  const startOfToday = new Date();
  startOfToday.setHours(0, 0, 0, 0);

  const changedAt = new Date();
  const statusHistoryEntry = {
    status: ORDER_STATUS.DELIVERED,
    changedBy: adminUserId,
    changedByRole: 'admin',
    changedAt,
  };

  const result = await Order.updateMany(
    {
      status: ORDER_STATUS.ON_THE_WAY,
      createdAt: { $lt: startOfToday },
    },
    {
      $set: { status: ORDER_STATUS.DELIVERED },
      $push: { statusHistory: statusHistoryEntry },
    }
  );

  return { updatedCount: result.modifiedCount };
}

/**
 * تحويل الطلب من صيغة MongoDB المعبأة إلى صيغة مسطحة تناسب لوحة التحكم.
 */
function normalizeOrderForAdmin(order) {
  const o = order && typeof order.toObject === 'function'
    ? order.toObject({ flattenMaps: true })
    : { ...order };

  o.id = String(o._id || o.id || '');

  if (o.customerId && typeof o.customerId === 'object') {
    o.customerName = o.customerId.name || '';
    o.customerPhone = o.customerId.phone || '';
    o.customerId = String(o.customerId._id || o.customerId);
  }

  if (o.shopId && typeof o.shopId === 'object') {
    o.shopName = o.shopId.name || '';
    o.shopId = String(o.shopId._id || o.shopId);
  }

  if (o.driverId && typeof o.driverId === 'object') {
    o.driverName = o.driverId.name || '';
    o.driverPhone = o.driverId.phone || '';
    o.driverId = String(o.driverId._id || o.driverId);
  }

  if (
    o.deliveryLocation &&
    Array.isArray(o.deliveryLocation.coordinates) &&
    o.deliveryLocation.coordinates.length >= 2
  ) {
    o.deliveryLng = o.deliveryLocation.coordinates[0];
    o.deliveryLat = o.deliveryLocation.coordinates[1];
  }

  if (Array.isArray(o.shopPortions)) {
    o.shopPortions = o.shopPortions.map((p) => {
      if (p.shopId && typeof p.shopId === 'object') {
        return { ...p, shopName: p.shopId.name || '', shopId: String(p.shopId._id || p.shopId) };
      }
      return p;
    });
  }

  return o;
}

async function listOrders(filters = {}) {
  const { page = 1, limit = 20, status, search, dateFrom, dateTo, shopId, orderType, excludeCanceled } = filters;
  const { ORDER_STATUS } = require('../config/constants');
  const query = {};
  if (status) query.status = status;
  if ((excludeCanceled === true || excludeCanceled === 'true') && !status) {
    query.status = { $ne: ORDER_STATUS.CANCELED };
  }
  if (dateFrom || dateTo) {
    query.createdAt = {};
    if (dateFrom) query.createdAt.$gte = new Date(dateFrom);
    if (dateTo) {
      const to = new Date(dateTo);
      to.setHours(23, 59, 59, 999);
      query.createdAt.$lte = to;
    }
  }
  if (shopId) {
    query.$or = [{ shopId }, { 'shopPortions.shopId': shopId }];
  }
  if (orderType === 'voice') {
    query.notesAudioUrl = { $exists: true, $nin: [null, ''] };
  } else if (orderType === 'regular') {
    query.$and = query.$and || [];
    query.$and.push({
      $or: [
        { notesAudioUrl: null },
        { notesAudioUrl: { $exists: false } },
        { notesAudioUrl: '' },
      ],
    });
  }
  if (search && typeof search === 'string' && search.trim()) {
    const safe = search.trim().replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const regex = new RegExp(safe, 'i');
    const matchingUsers = await User.find({ $or: [{ name: regex }, { phone: regex }] }).select('_id').lean();
    const userIds = matchingUsers.map((u) => u._id);
    query.customerId = { $in: userIds };
  }
  const skip = (Number(page) - 1) * Number(limit);
  const [items, total] = await Promise.all([
    Order.find(query)
      .populate('shopId customerId driverId shopPortions.shopId')
      .skip(skip)
      .limit(Number(limit))
      .sort({ createdAt: -1 })
      .lean(),
    Order.countDocuments(query),
  ]);
  return { items: items.map(normalizeOrderForAdmin), pagination: { page: Number(page), limit: Number(limit), total } };
}

async function getOrderById(orderId) {
  const order = await Order.findById(orderId)
    .populate('shopId shopPortions.shopId customerId driverId')
    .lean();
  if (!order) throw notFound('الطلب غير موجود');
  const normalized = normalizeOrderForAdmin(order);
  const driverReviewService = require('./driverReviewService');
  return driverReviewService.attachToOrder(normalized);
}

async function updateOrderStatus(orderId, adminUserId, body) {
  const orderService = require('./orderService');
  const updated = await orderService.updateStatus(orderId, adminUserId, ['admin'], body);
  return normalizeOrderForAdmin(updated);
}

async function listProducts(filters = {}) {
  const {
    page = 1,
    limit = 20,
    isAvailable,
    shopId,
    q,
    missingImageOnly,
    categoryId,
    subcategoryId,
    brandId,
    price,
    minPrice,
    maxPrice,
    expiryDate,
    expiryDateFrom,
    expiryDateTo,
  } = filters;
  const missingOnly =
    missingImageOnly === true ||
    missingImageOnly === 'true' ||
    missingImageOnly === '1';
  const parts = [];
  if (typeof isAvailable === 'boolean') parts.push({ isAvailable });
  if (shopId && mongoose.Types.ObjectId.isValid(String(shopId))) {
    parts.push({ shopId: new mongoose.Types.ObjectId(String(shopId).trim()) });
  }
  if (categoryId && mongoose.Types.ObjectId.isValid(String(categoryId))) {
    parts.push({ categoryId: new mongoose.Types.ObjectId(String(categoryId).trim()) });
  }
  if (subcategoryId && mongoose.Types.ObjectId.isValid(String(subcategoryId))) {
    parts.push({ subcategoryId: new mongoose.Types.ObjectId(String(subcategoryId).trim()) });
  }
  if (brandId && mongoose.Types.ObjectId.isValid(String(brandId))) {
    parts.push({ brandId: new mongoose.Types.ObjectId(String(brandId).trim()) });
  }
  if (q && typeof q === 'string' && q.trim()) {
    const safe = q.trim().replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const regex = new RegExp(safe, 'i');
    parts.push({ $or: [{ name: regex }, { description: regex }] });
  }
  if (price !== undefined && price !== '') {
    const exact = Number(price);
    if (Number.isFinite(exact)) parts.push({ price: exact });
  } else {
    const range = {};
    if (minPrice !== undefined && minPrice !== '') {
      const min = Number(minPrice);
      if (Number.isFinite(min)) range.$gte = min;
    }
    if (maxPrice !== undefined && maxPrice !== '') {
      const max = Number(maxPrice);
      if (Number.isFinite(max)) range.$lte = max;
    }
    if (Object.keys(range).length > 0) parts.push({ price: range });
  }
  if (expiryDate) {
    const d = new Date(expiryDate);
    if (!Number.isNaN(d.getTime())) {
      const start = new Date(d);
      start.setHours(0, 0, 0, 0);
      const end = new Date(d);
      end.setHours(23, 59, 59, 999);
      parts.push({ expiryDate: { $gte: start, $lte: end } });
    }
  } else {
    const range = {};
    if (expiryDateFrom) {
      const from = new Date(expiryDateFrom);
      if (!Number.isNaN(from.getTime())) {
        from.setHours(0, 0, 0, 0);
        range.$gte = from;
      }
    }
    if (expiryDateTo) {
      const to = new Date(expiryDateTo);
      if (!Number.isNaN(to.getTime())) {
        to.setHours(23, 59, 59, 999);
        range.$lte = to;
      }
    }
    if (Object.keys(range).length > 0) parts.push({ expiryDate: range });
  }
  if (missingOnly) parts.push(getMissingImageMongoCondition());
  const query = parts.length === 0 ? {} : parts.length === 1 ? parts[0] : { $and: parts };
  const skip = (Number(page) - 1) * Number(limit);
  const limitNum = Number(limit);
  const pageNum = Number(page);
  const [rawItems, total] = await Promise.all([
    Product.find(query)
      .populate('shopId', 'name')
      .populate('productCategoryId', 'nameAr')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limitNum)
      .lean(),
    Product.countDocuments(query),
  ]);
  const items = rawItems.map((p) => {
    const { shopId: shop, productCategoryId: catDoc, ...rest } = p;
    return {
      ...rest,
      shopId: shop?._id?.toString(),
      shopName: shop?.name ?? null,
      productCategoryId: catDoc?._id?.toString(),
      categoryName: catDoc?.nameAr ?? null,
      offerPrice: p.offerPrice != null ? p.offerPrice : undefined,
      offerEndsAt: p.offerEndsAt ? p.offerEndsAt.toISOString() : undefined,
    };
  });
  return { items, pagination: { page: pageNum, limit: limitNum, total } };
}

async function deleteShop(shopId) {
  const shop = await Shop.findById(shopId);
  if (!shop) throw notFound('Shop not found');
  const products = await Product.find({ shopId }).select('image images').lean();
  for (const p of products) {
    const all = Array.isArray(p.images) && p.images.length > 0 ? p.images : [p.image];
    for (const img of all) deleteProductImageIfLocal(img);
  }
  await Product.deleteMany({ shopId });
  await Shop.findByIdAndDelete(shopId);
  return { deleted: true };
}

/** مالك المحل: ownerId صريح، أو ownerPhone (حساب موجود يُضاف له دور shop، أو حساب جديد بكلمة مرور). */
async function resolveShopOwnerForAdmin(body) {
  if (body.ownerId && String(body.ownerId).trim()) {
    const id = String(body.ownerId).trim();
    const u = await User.findById(id);
    if (!u) throw notFound('مالك المحل غير موجود');
    return id;
  }
  const phone = body.ownerPhone && String(body.ownerPhone).trim();
  if (!phone) throw badRequest('هاتف المالك مطلوب');
  const existing = await User.findOne({ phone });
  if (existing) {
    const roles = Array.isArray(existing.roles) ? [...existing.roles] : [];
    if (!roles.includes(ROLES.SHOP)) {
      existing.roles = [...roles, ROLES.SHOP];
      await existing.save();
    }
    return existing._id.toString();
  }
  const pwd = body.ownerPassword;
  if (!pwd || String(pwd).length < 8) {
    throw badRequest('هذا الرقم غير مسجل: أدخل كلمة مرور (٨ أحرف على الأقل) لإنشاء حساب المالك');
  }
  const name =
    body.ownerName && String(body.ownerName).trim() ? String(body.ownerName).trim() : 'مالك المحل';
  const governorateId =
    body.ownerGovernorateId && String(body.ownerGovernorateId).trim()
      ? String(body.ownerGovernorateId).trim()
      : 'baghdad';
  const user = await authService.createUser({
    name,
    phone,
    password: pwd,
    roles: [ROLES.SHOP],
    governorateId,
    clinicName: null,
    email: undefined,
  });
  return user._id.toString();
}

/** Create shop by admin; يحدد المالك عبر ownerId أو ownerPhone (+ إنشاء حساب عند الحاجة). */
async function createShop(adminId, body) {
  const ownerIdStr = await resolveShopOwnerForAdmin(body);
  const ownerId = new mongoose.Types.ObjectId(ownerIdStr);
  const {
    ownerId: _o,
    ownerPhone: _p,
    ownerPassword: _pw,
    ownerName: _n,
    ownerGovernorateId: _g,
    ...rest
  } = body;
  const shop = await Shop.create({
    ownerId,
    name: rest.name,
    description: rest.description,
    location: rest.location,
    address: rest.address?.trim() || null,
    phone: rest.phone?.trim() || null,
    phone2: rest.phone2?.trim() || null,
    deliveryFee: 0,
    isOpen: rest.isOpen !== false,
    isHidden: rest.isHidden === true,
    openHours: rest.openHours,
    image: rest.image,
  });
  return shop;
}

/** Update shop by admin (any field including ownerId). */
async function updateShop(shopId, body) {
  const shop = await Shop.findById(shopId);
  if (!shop) throw notFound('Shop not found');
  const allowed = [
    'name',
    'description',
    'location',
    'address',
    'phone',
    'phone2',
    'isOpen',
    'isActive',
    'isHidden',
    'openHours',
    'image',
    'ownerId',
    'order',
  ];
  for (const key of allowed) {
    if (body[key] !== undefined) shop[key] = body[key];
  }
  await shop.save();
  return shop;
}

/** تطبيق وقت فتح وإغلاق واحد على جميع المحلات (توقيت العراق). */
async function bulkUpdateShopsOpenHours(body) {
  const { from, to } = body;
  const result = await Shop.updateMany(
    {},
    { $set: { openHours: { from: String(from).trim(), to: String(to).trim() } } }
  );
  return { updated: result.modifiedCount };
}

/** تحديث ترتيب المحلات. shopIds مصفوفة بترتيب العرض المطلوب. */
async function reorderShops(shopIds) {
  if (!Array.isArray(shopIds) || shopIds.length === 0) return { updated: 0 };
  const bulkOps = shopIds.map((id, index) => ({
    updateOne: {
      filter: { _id: id },
      update: { $set: { order: index } },
    },
  }));
  const result = await Shop.bulkWrite(bulkOps);
  return { updated: result.modifiedCount };
}

async function setUserActive(userId, isActive) {
  const user = await User.findByIdAndUpdate(
    userId,
    { isActive: !!isActive },
    { new: true, runValidators: true }
  ).select('-passwordHash -refreshTokenHash');
  if (!user) throw notFound('User not found');
  return user;
}

async function updateUser(userId, updates) {
  const allowed = ['name', 'phone', 'email', 'roles'];
  const body = {};
  for (const key of allowed) {
    if (updates[key] !== undefined) body[key] = updates[key];
  }

  const password = typeof updates.password === 'string' ? updates.password.trim() : '';
  if (password) {
    body.passwordHash = await bcrypt.hash(password, env.bcryptRounds);
    body.refreshTokenHash = null;
  }

  if (Object.keys(body).length === 0) {
    const user = await User.findById(userId).select('-passwordHash -refreshTokenHash').lean();
    if (!user) throw notFound('User not found');
    return user;
  }

  const user = await User.findByIdAndUpdate(userId, body, {
    new: true,
    runValidators: true,
  }).select('-passwordHash -refreshTokenHash');
  if (!user) throw notFound('User not found');
  return user;
}

async function deleteUser(userId) {
  const user = await User.findByIdAndDelete(userId);
  if (!user) throw notFound('User not found');
  return { deleted: true };
}

async function getStats() {
  const [usersCount, shopsCount, productsCount, ordersCount, ordersByStatus] = await Promise.all([
    User.countDocuments(),
    Shop.countDocuments(),
    Product.countDocuments(),
    Order.countDocuments(),
    Order.aggregate([{ $group: { _id: '$status', count: { $sum: 1 } } }]),
  ]);
  const statusCounts = Object.fromEntries(ordersByStatus.map((s) => [s._id, s.count]));
  return {
    users: usersCount,
    shops: shopsCount,
    products: productsCount,
    orders: ordersCount,
    ordersByStatus: statusCounts,
  };
}

/**
 * إحصائيات مفصلة للطلبات
 * @param {{ dateFrom?: string, dateTo?: string, days?: number }} filters
 */
async function getOrdersStats(filters = {}) {
  const { dateFrom, dateTo, days = 30 } = filters;
  const match = {};
  if (dateFrom || dateTo) {
    match.createdAt = {};
    if (dateFrom) match.createdAt.$gte = new Date(dateFrom);
    if (dateTo) {
      const to = new Date(dateTo);
      to.setHours(23, 59, 59, 999);
      match.createdAt.$lte = to;
    }
  } else if (days > 0) {
    const start = new Date();
    start.setDate(start.getDate() - days);
    start.setHours(0, 0, 0, 0);
    match.createdAt = { $gte: start };
  }
  const { ORDER_STATUS } = require('../config/constants');
  const addGrandTotal = { $addFields: { grandTotal: ORDER_GRAND_TOTAL_ADD } };
  const matchStage = Object.keys(match).length > 0 ? [{ $match: match }] : [];

  const [ordersByDay, ordersByStatus, ordersByShop, totals] = await Promise.all([
    Order.aggregate([
      ...matchStage,
      {
        $group: {
          _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } },
          count: { $sum: 1 },
          amount: { $sum: ORDER_GRAND_TOTAL_ADD },
        },
      },
      { $sort: { _id: 1 } },
    ]),
    Order.aggregate([
      ...matchStage,
      { $group: { _id: '$status', count: { $sum: 1 } } },
    ]),
    Order.aggregate([
      ...matchStage,
      { $unwind: { path: '$shopPortions', preserveNullAndEmptyArrays: true } },
      {
        $group: {
          _id: { $ifNull: ['$shopPortions.shopId', '$shopId'] },
          count: { $sum: 1 },
        },
      },
      { $match: { _id: { $ne: null } } },
      {
        $lookup: {
          from: 'shops',
          localField: '_id',
          foreignField: '_id',
          as: 'shop',
          pipeline: [{ $project: { name: 1 } }],
        },
      },
      { $unwind: { path: '$shop', preserveNullAndEmptyArrays: true } },
      {
        $project: {
          shopId: { $toString: '$_id' },
          shopName: '$shop.name',
          count: 1,
        },
      },
      { $sort: { count: -1 } },
    ]),
    Order.aggregate([
      ...matchStage,
      addGrandTotal,
      {
        $facet: {
          totalOrders: [{ $count: 'count' }],
          totalRevenue: [
            { $match: { status: ORDER_STATUS.DELIVERED } },
            { $group: { _id: null, amount: { $sum: '$grandTotal' } } },
          ],
          avgOrderValue: [{ $group: { _id: null, avg: { $avg: '$grandTotal' } } }],
        },
      },
    ]),
  ]);

  const totalOrders = totals[0]?.totalOrders?.[0]?.count ?? 0;
  const totalRevenue = totals[0]?.totalRevenue?.[0]?.amount ?? 0;
  const avgOrderValue = totals[0]?.avgOrderValue?.[0]?.avg ?? 0;
  const ordersByStatusMap = Object.fromEntries(ordersByStatus.map((s) => [s._id, s.count]));

  return {
    totalOrders,
    totalRevenue: Math.round(totalRevenue * 100) / 100,
    avgOrderValue: Math.round(avgOrderValue * 100) / 100,
    ordersByDay: ordersByDay.map((d) => ({
      date: d._id,
      count: d.count,
      amount: Math.round((d.amount || 0) * 100) / 100,
    })),
    ordersByStatus: ordersByStatusMap,
    ordersByShop: ordersByShop.map((s) => ({
      shopId: s.shopId,
      shopName: s.shopName ?? 'مجهول',
      count: s.count,
    })),
  };
}

async function listDriverReviews(driverId, query = {}) {
  const driverReviewService = require('./driverReviewService');
  return driverReviewService.listForDriver(driverId, query);
}

async function deleteOrder(orderId) {
  const order = await Order.findByIdAndDelete(orderId);
  if (!order) throw notFound('Order not found');
  return { deleted: true };
}

module.exports = {
  listUsers,
  getUserById,
  listShops,
  deliverStaleOnTheWayBeforeTodayNoNotify,
  listOrders,
  getOrderById,
  listProducts,
  setUserActive,
  updateUser,
  deleteUser,
  getStats,
  getOrdersStats,
  deleteShop,
  deleteOrder,
  listDriverReviews,
  createShop,
  updateShop,
  reorderShops,
  bulkUpdateShopsOpenHours,
};
