const mongoose = require('mongoose');
const { Order, Shop, Product, User } = require('../models');
const { ORDER_STATUS } = require('../config/constants');
const { notFound, forbidden, badRequest } = require('../utils/errors');
const discountCodeService = require('./discountCodeService');
const { notifyOrderStatusChange } = require('../utils/telegram');

/** يُرجع السعر الفعلي للمنتج: سعر العرض إن كان نشطاً، وإلا السعر العادي. */
function getProductEffectivePrice(product) {
  if (!product) return 0;
  const now = new Date();
  const hasActiveOffer =
    product.offerPrice != null &&
    product.offerPrice > 0 &&
    (product.offerEndsAt == null || new Date(product.offerEndsAt) > now);
  return hasActiveOffer ? Number(product.offerPrice) : Number(product.price ?? 0);
}

/** الصورة الافتراضية لأي منتج لا يحتوي على صورة مرفوعة. */
const DEFAULT_PRODUCT_IMAGE = '/uploads/products/photo_2026-03-18 00.25.48.jpeg';

/** يستخرج رابط الصورة من حقل populated أو يُعيد الافتراضي. */
function resolveProductImage(productRaw) {
  if (productRaw && typeof productRaw === 'object') {
    if (Array.isArray(productRaw.images) && productRaw.images.length > 0) {
      const first = productRaw.images.find((v) => typeof v === 'string' && String(v).trim());
      if (first) return String(first).trim();
    }
    const img = productRaw.image;
    if (img && String(img).trim()) return String(img).trim();
  }
  return DEFAULT_PRODUCT_IMAGE;
}

/**
 * تجميع الـ populate المطلوب لأي رد API يتضمّن عناصر طلب (صور المنتجات + المحلات + العميل/السائق).
 * يجب استخدامه في كل re-fetch بعد الحفظ حتى تظهر الصور ولا تُرسل بيانات ناقصة عبر الـ WebSocket.
 */
function populateOrderForResponseQuery(query) {
  return query
    .populate('shopId shopPortions.shopId customerId driverId')
    .populate('items.productId', 'image images name')
    .populate('shopPortions.items.productId', 'image images name');
}

/**
 * يُسطّح حقل productId المُعبّأ ويضمن وجود حقل image لكل عنصر.
 * - productId يصبح string بدلاً من كائن.
 * - image يُضاف إلى مستوى العنصر نفسه (إمّا الصورة الحقيقية أو الافتراضية).
 */
function flattenOrderItems(order) {
  if (!order) return order;
  const flattenItem = (item) => {
    if (!item) return item;
    const productRaw = item.productId;
    const image = item.image && String(item.image).trim()
      ? String(item.image).trim()
      : resolveProductImage(productRaw);
    const name =
      item.name && String(item.name).trim()
        ? String(item.name).trim()
        : productRaw && typeof productRaw === 'object' && productRaw.name
          ? String(productRaw.name).trim()
          : '';
    const productIdStr =
      productRaw && typeof productRaw === 'object' && productRaw._id != null
        ? String(productRaw._id)
        : productRaw != null
          ? String(productRaw)
          : '';
    return { ...item, name, productId: productIdStr, image };
  };
  if (Array.isArray(order.items)) {
    order.items = order.items.map(flattenItem);
  }
  if (Array.isArray(order.shopPortions)) {
    order.shopPortions = order.shopPortions.map((p) => {
      if (p && Array.isArray(p.items)) {
        return { ...p, items: p.items.map(flattenItem) };
      }
      return p;
    });
  }
  return order;
}

/** حقول مسطحة لميزة المكالمات الصوتية (معرّفات User بدون بادئة التطبيق). */
function attachVoiceCallIds(orderLike) {
  if (!orderLike) return orderLike;
  const o =
    typeof orderLike.toObject === 'function'
      ? orderLike.toObject({ flattenMaps: true })
      : { ...orderLike };
  const cid = o.customerId;
  if (cid && typeof cid === 'object' && cid._id != null) {
    o.customerUserId = String(cid._id);
  } else if (cid) {
    o.customerUserId = String(cid);
  }
  const did = o.driverId;
  if (did && typeof did === 'object' && did._id != null) {
    o.driverUserId = String(did._id);
  } else if (did) {
    o.driverUserId = String(did);
  }
  return flattenOrderItems(o);
}

/** توحيد حالة الطلب من الـ DB (مسافات/حالة أحرف) لمطابقة ORDER_STATUS */
function normalizeOrderStatusForTransition(status) {
  if (status == null || status === '') return status;
  const s = String(status).trim().toLowerCase();
  const valid = new Set(Object.values(ORDER_STATUS));
  if (valid.has(s)) return s;
  return String(status).trim();
}

const ALLOWED_TRANSITIONS = {
  [ORDER_STATUS.PENDING]: [ORDER_STATUS.ACCEPTED, ORDER_STATUS.CANCELED, ORDER_STATUS.POSTPONED],
  [ORDER_STATUS.ACCEPTED]: [
    ORDER_STATUS.PREPARING,
    ORDER_STATUS.ON_THE_WAY,
    ORDER_STATUS.DELIVERED,
    ORDER_STATUS.CANCELED,
    ORDER_STATUS.POSTPONED,
  ],
  [ORDER_STATUS.PREPARING]: [
    ORDER_STATUS.ON_THE_WAY,
    ORDER_STATUS.DELIVERED,
    ORDER_STATUS.CANCELED,
    ORDER_STATUS.POSTPONED,
  ],
  [ORDER_STATUS.ON_THE_WAY]: [ORDER_STATUS.DELIVERED, ORDER_STATUS.POSTPONED],
  [ORDER_STATUS.DELIVERED]: [],
  [ORDER_STATUS.CANCELED]: [],
  [ORDER_STATUS.POSTPONED]: [
    ORDER_STATUS.ACCEPTED,
    ORDER_STATUS.PREPARING,
    ORDER_STATUS.ON_THE_WAY,
    ORDER_STATUS.CANCELED,
    ORDER_STATUS.DELIVERED,
  ],
};

async function getNextOrderNumber() {
  const last = await Order.findOne({ orderNumber: { $ne: null } })
    .sort({ orderNumber: -1 })
    .select('orderNumber')
    .lean();
  const next = (last && typeof last.orderNumber === 'number' ? last.orderNumber : 0) + 1;
  return next;
}

/** نافذة «طلب مكرر»: نفس العميل، نفس يوم بغداد، وفارق أقل من 30 دقيقة عن طلب سابق. */
const DUPLICATE_ORDER_WINDOW_MS = 30 * 60 * 1000;
const IRAQ_TZ_BAGHDAD = 'Asia/Baghdad';

function getBaghdadDateKeyFromUtc(utcDate) {
  const d = utcDate instanceof Date ? utcDate : new Date(utcDate);
  const formatter = new Intl.DateTimeFormat('en-CA', {
    timeZone: IRAQ_TZ_BAGHDAD,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  });
  const parts = formatter.formatToParts(d);
  const get = (type) => parts.find((p) => p.type === type)?.value || '0';
  return `${get('year')}-${get('month')}-${get('day')}`;
}

/** بداية يوم تقويم بغداد (UTC) لمخزّن createdAt. */
function getBaghdadDayUtcStart(utcInstant) {
  const key = getBaghdadDateKeyFromUtc(utcInstant);
  return new Date(`${key}T00:00:00+03:00`);
}

/**
 * بعد إنشاء الطلب: إن وُجد طلب أقدم لنفس العميل في نفس يوم بغداد وخلال أقل من 30 دقيقة
 * يُوسَّم الطلب الجديد كمكرر ويُربَط بجذر السلسلة (originalOrderId).
 */
async function applyDuplicateOrderFlagsAfterCreate(orderDoc) {
  if (!orderDoc || !orderDoc._id || !orderDoc.customerId) return;
  const createdAt = orderDoc.createdAt ? new Date(orderDoc.createdAt) : new Date();
  const customerId = orderDoc.customerId;
  const dayStart = getBaghdadDayUtcStart(createdAt);
  const windowStart = new Date(createdAt.getTime() - DUPLICATE_ORDER_WINDOW_MS);
  const lowerBound = windowStart > dayStart ? windowStart : dayStart;

  const prev = await Order.findOne({
    customerId,
    _id: { $ne: orderDoc._id },
    createdAt: {
      $gte: lowerBound,
      $lt: createdAt,
    },
  })
    .sort({ createdAt: -1 })
    .select('_id originalOrderId')
    .lean();

  if (!prev) return;

  const rootId = prev.originalOrderId || prev._id;
  await Order.updateOne(
    { _id: orderDoc._id },
    { $set: { isDuplicate: true, originalOrderId: rootId } },
  );
  if (typeof orderDoc.set === 'function') {
    orderDoc.set({ isDuplicate: true, originalOrderId: rootId });
  } else {
    orderDoc.isDuplicate = true;
    orderDoc.originalOrderId = rootId;
  }
}

function canChangeStatus(currentStatus, newStatus, role, _orderDriverId, _userId) {
  // Admin can change any status; delivered is final; canceled can be reverted by admin to any status
  if (role === 'admin') {
    if (currentStatus === ORDER_STATUS.DELIVERED) return false;
    if (currentStatus === ORDER_STATUS.CANCELED) {
      return [
        ORDER_STATUS.PENDING,
        ORDER_STATUS.ACCEPTED,
        ORDER_STATUS.PREPARING,
        ORDER_STATUS.ON_THE_WAY,
        ORDER_STATUS.DELIVERED,
      ].includes(newStatus);
    }
    return true;
  }

  // For non-admin users, check allowed transitions
  const allowed = ALLOWED_TRANSITIONS[currentStatus] || [];
  if (!allowed.includes(newStatus)) return false;

  // Check role-specific permissions
  if (newStatus === ORDER_STATUS.CANCELED && currentStatus !== ORDER_STATUS.PENDING) {
    return role === 'shop';
  }
  if (newStatus === ORDER_STATUS.ACCEPTED || newStatus === ORDER_STATUS.PREPARING) return role === 'shop';
  if (newStatus === ORDER_STATUS.ON_THE_WAY) return role === 'shop';
  if (newStatus === ORDER_STATUS.POSTPONED) return role === 'shop' || role === 'admin';
  if (newStatus === ORDER_STATUS.DELIVERED) {
    return role === 'shop';
  }
  return true;
}

async function prepareMultiShopOrder(body) {
  const { getGlobalDeliveryFee } = require('./platformSettingsService');
  const shopPortions = [];
  let merchandiseSubtotal = 0;
  const deliveryFee = await getGlobalDeliveryFee();
  for (const portion of body.shopPortions) {
    const shop = await Shop.findById(portion.shopId);
    if (!shop) throw notFound(`Shop ${portion.shopId} not found`);
    if (!shop.isActive || !shop.isOpen) throw badRequest(`محل ${shop.name || 'المحدد'} مغلق في هذا الوقت`);
    const orderItems = await Promise.all(
      portion.items.map(async (it) => {
        const product = await Product.findById(it.productId).lean();
        const effectivePrice = product ? getProductEffectivePrice(product) : Number(it.price ?? 0);
        return {
          productId: it.productId,
          name: it.name,
          price: effectivePrice,
          quantity: it.quantity,
        };
      })
    );
    const subtotal = orderItems.reduce((sum, it) => sum + it.price * it.quantity, 0);
    shopPortions.push({ shopId: portion.shopId, items: orderItems, subtotal });
    merchandiseSubtotal += subtotal;
  }
  return { shopPortions, merchandiseSubtotal, deliveryFee };
}

async function prepareSingleShopOrder(body) {
  const { getGlobalDeliveryFee } = require('./platformSettingsService');
  const shop = await Shop.findById(body.shopId);
  if (!shop) throw notFound('Shop not found');
  if (!shop.isActive || !shop.isOpen) throw badRequest(`محل ${shop.name || 'المحدد'} مغلق في هذا الوقت`);
  const orderItems = await Promise.all(
    body.items.map(async (it) => {
      const product = await Product.findById(it.productId).lean();
      const effectivePrice = product ? getProductEffectivePrice(product) : Number(it.price ?? 0);
      return {
        productId: it.productId,
        name: it.name,
        price: effectivePrice,
        quantity: it.quantity,
      };
    })
  );
  const merchandiseSubtotal = orderItems.reduce((sum, it) => sum + it.price * it.quantity, 0);
  const deliveryFee = await getGlobalDeliveryFee();
  return {
    shopId: body.shopId,
    items: orderItems,
    merchandiseSubtotal,
    deliveryFee,
  };
}

/** تقدير خصم العربة (نفس منطق إنشاء الطلب دون حجز استخدام). */
async function quoteDiscountForCart(body) {
  if (!body.shopPortions || body.shopPortions.length === 0) {
    throw badRequest('shopPortions مطلوب');
  }
  const prepared = await prepareMultiShopOrder(body);
  const preview = await discountCodeService.previewCode(body.discountCode, prepared.merchandiseSubtotal);
  const totalAfterDiscount = Math.max(0, prepared.merchandiseSubtotal - preview.appliedAmount);
  return {
    merchandiseSubtotal: prepared.merchandiseSubtotal,
    discountAmount: preview.appliedAmount,
    discountCode: preview.code,
    totalAfterDiscount,
  };
}

async function create(customerId, body) {
  const normalizedDiscount =
    body.discountCode && String(body.discountCode).trim()
      ? discountCodeService.normalizeCode(body.discountCode)
      : null;

  if (body.shopPortions && body.shopPortions.length > 0) {
    const prepared = await prepareMultiShopOrder(body);
    let discountAmount = 0;
    let discountCodeStored = null;
    let couponId = null;
    if (normalizedDiscount) {
      const consumed = await discountCodeService.consumeCode(normalizedDiscount, prepared.merchandiseSubtotal);
      discountAmount = consumed.appliedAmount;
      discountCodeStored = consumed.code;
      couponId = consumed.couponId;
    }
    const totalPrice = Math.max(0, prepared.merchandiseSubtotal - discountAmount);
    const orderNumber = await getNextOrderNumber();
    try {
      const order = await Order.create({
        customerId,
        shopPortions: prepared.shopPortions,
        totalPrice,
        deliveryFee: prepared.deliveryFee,
        discountCode: discountCodeStored,
        discountAmount,
        deliveryLocation: body.deliveryLocation,
        notes: body.notes,
        notesAudioUrl: body.notesAudioUrl || null,
        statusHistory: [
          { status: ORDER_STATUS.PENDING, changedBy: customerId, changedByRole: 'customer', changedAt: new Date() },
        ],
        orderNumber,
      });
      await applyDuplicateOrderFlagsAfterCreate(order);
      return order.populate(['shopPortions.shopId', 'customerId']);
    } catch (e) {
      if (couponId) await discountCodeService.releaseConsumption(couponId);
      throw e;
    }
  }

  const single = await prepareSingleShopOrder(body);
  let discountAmount = 0;
  let discountCodeStored = null;
  let couponId = null;
  if (normalizedDiscount) {
    const consumed = await discountCodeService.consumeCode(normalizedDiscount, single.merchandiseSubtotal);
    discountAmount = consumed.appliedAmount;
    discountCodeStored = consumed.code;
    couponId = consumed.couponId;
  }
  const totalPrice = Math.max(0, single.merchandiseSubtotal - discountAmount);
  const orderNumber = await getNextOrderNumber();
  try {
    const order = await Order.create({
      customerId,
      shopId: single.shopId,
      items: single.items,
      totalPrice,
      deliveryFee: single.deliveryFee,
      discountCode: discountCodeStored,
      discountAmount,
      deliveryLocation: body.deliveryLocation,
      notes: body.notes,
      notesAudioUrl: body.notesAudioUrl || null,
      statusHistory: [
        { status: ORDER_STATUS.PENDING, changedBy: customerId, changedByRole: 'customer', changedAt: new Date() },
      ],
      orderNumber,
    });
    await applyDuplicateOrderFlagsAfterCreate(order);
    return order.populate(['shopId', 'customerId']);
  } catch (e) {
    if (couponId) await discountCodeService.releaseConsumption(couponId);
    throw e;
  }
}

async function createVoiceOrder(customerId, body) {
  const { getGlobalDeliveryFee } = require('./platformSettingsService');
  if (body.shopId) {
    const shop = await Shop.findById(body.shopId);
    if (!shop) throw notFound('Shop not found');
    if (!shop.isActive || !shop.isOpen) throw badRequest(`محل ${shop.name || 'المحدد'} مغلق في هذا الوقت`);
    const deliveryFee = await getGlobalDeliveryFee();
    const orderNumber = await getNextOrderNumber();
    const order = await Order.create({
      customerId,
      shopId: body.shopId,
      items: [],
      totalPrice: 0,
      deliveryFee,
      deliveryLocation: body.deliveryLocation,
      notes: null,
      notesAudioUrl: body.notesAudioUrl,
      statusHistory: [
        { status: ORDER_STATUS.PENDING, changedBy: customerId, changedByRole: 'customer', changedAt: new Date() },
      ],
      orderNumber,
    });
    await applyDuplicateOrderFlagsAfterCreate(order);
    return order.populate(['shopId', 'customerId']);
  }

  const orderNumber = await getNextOrderNumber();
  const deliveryFeeNoShop = await getGlobalDeliveryFee();
  const order = await Order.create({
    customerId,
    shopId: null,
    items: [],
    totalPrice: 0,
    deliveryFee: deliveryFeeNoShop,
    deliveryLocation: body.deliveryLocation,
    notes: null,
    notesAudioUrl: body.notesAudioUrl,
    statusHistory: [
      { status: ORDER_STATUS.PENDING, changedBy: customerId, changedByRole: 'customer', changedAt: new Date() },
    ],
    orderNumber,
  });
  await applyDuplicateOrderFlagsAfterCreate(order);
  return order.populate(['customerId']);
}

async function listByUser(userId, roles, filters = {}) {
  const { status, page = 1, limit = 20, fromDate, toDate, search, duplicateOnly } = filters;
  const query = {};
  let userShopIds = [];
  if (roles.includes('customer')) query.customerId = userId;
  else if (roles.includes('shop')) {
    userShopIds = await Shop.find({ ownerId: userId }).distinct('_id');
    query.$or = [{ shopId: { $in: userShopIds } }, { 'shopPortions.shopId': { $in: userShopIds } }];
  } else if (!roles.includes('admin')) query.customerId = userId;
  if (status) query.status = status;
  const dateFilter = {};
  if (fromDate) {
    const d = new Date(fromDate);
    if (!isNaN(d.getTime())) dateFilter.$gte = d;
  }
  if (toDate) {
    const d = new Date(toDate);
    if (!isNaN(d.getTime())) dateFilter.$lte = d;
  }
  if (Object.keys(dateFilter).length > 0) query.createdAt = dateFilter;
  if (search && String(search).trim()) {
    const term = String(search).trim();
    const orClauses = [];
    const asNumber = Number(term);
    if (Number.isFinite(asNumber)) {
      orClauses.push({ orderNumber: asNumber });
    }
    try {
      const customerMatches = await User.find({
        $or: [
          { name: { $regex: term, $options: 'i' } },
          { phone: { $regex: term, $options: 'i' } },
        ],
      })
        .select('_id')
        .limit(100)
        .lean();
      if (customerMatches.length > 0) {
        const ids = customerMatches.map((u) => u._id);
        orClauses.push({ customerId: { $in: ids } });
      }
    } catch (_) {}
    if (orClauses.length > 0) {
      if (query.$or) {
        query.$and = [{ $or: query.$or }, { $or: orClauses }];
        delete query.$or;
      } else {
        query.$or = orClauses;
      }
    } else {
      query._id = null;
    }
  }

  const dupOnly =
    duplicateOnly === true ||
    duplicateOnly === 'true' ||
    duplicateOnly === '1' ||
    duplicateOnly === 1;
  if (dupOnly) {
    const dupClause = {
      $or: [{ isDuplicate: true }, { originalOrderId: { $ne: null } }],
    };
    if (query.$and && Array.isArray(query.$and)) {
      query.$and.push(dupClause);
    } else if (query.$or) {
      query.$and = [{ $or: query.$or }, dupClause];
      delete query.$or;
    } else {
      Object.assign(query, dupClause);
    }
  }

  const skip = (Number(page) - 1) * Number(limit);
  const [items, total] = await Promise.all([
    Order.find(query)
      .skip(skip)
      .limit(Number(limit))
      .sort({ createdAt: -1 })
      .populate('shopId shopPortions.shopId customerId driverId')
      .populate('items.productId', 'image images name')
      .populate('shopPortions.items.productId', 'image images name')
      .lean(),
    Order.countDocuments(query),
  ]);
  // For shop role, transform multi-shop orders so each item shows only that shop's portion (items + subtotal).
  if (roles.includes('shop') && userShopIds.length > 0) {
    const transformed = items.map((order) => {
      if (!order.shopPortions || !order.shopPortions.length) return attachVoiceCallIds(order);
      const viewerShopId = userShopIds.find((sid) => {
        const orderShopIds = order.shopPortions.map((p) => (p.shopId?._id || p.shopId)?.toString());
        return orderShopIds.includes(sid.toString());
      });
      if (!viewerShopId) return attachVoiceCallIds(order);
      const portion = _getShopPortionForShop(order, viewerShopId);
      if (!portion) return attachVoiceCallIds(order);
      return attachVoiceCallIds(_toShopViewOrder(order, portion));
    });
    return { items: transformed, pagination: { page: Number(page), limit: Number(limit), total } };
  }
  return {
    items: items.map((order) => attachVoiceCallIds(order)),
    pagination: { page: Number(page), limit: Number(limit), total },
  };
}

function _userOwnsShop(userId, shop) {
  return shop && shop.ownerId && shop.ownerId.toString() === userId.toString();
}

function _getShopPortionForShop(order, shopId) {
  if (!order.shopPortions || !order.shopPortions.length) return null;
  const portion = order.shopPortions.find((p) => {
    const id = p.shopId?._id || p.shopId;
    return id && id.toString() === shopId.toString();
  });
  return portion;
}

/** Returns order shaped for shop view: only that shop's items, totalPrice = portion.subtotal, deliveryFee = 0. */
function _toShopViewOrder(order, portion) {
  const ord = order && typeof order.toObject === 'function' ? order.toObject() : { ...order };
  return {
    ...ord,
    items: portion.items || [],
    totalPrice: portion.subtotal ?? 0,
    deliveryFee: 0,
    isMultiShop: order.shopPortions && order.shopPortions.length > 1,
    shopId: portion.shopId,
    shopPortions: undefined,
  };
}

async function getById(orderId, userId, roles) {
  const order = await populateOrderForResponseQuery(Order.findById(orderId));
  if (!order) throw notFound('Order not found');
  const isCustomer = order.customerId?._id?.toString() === userId.toString();
  let isShop = false;
  let viewerShopId = null;
  if (order.shopPortions && order.shopPortions.length > 0) {
    const shops = await Shop.find({ ownerId: userId }).distinct('_id');
    for (const p of order.shopPortions) {
      const sid = p.shopId?._id || p.shopId;
      if (sid && shops.some((s) => s.toString() === sid.toString())) {
        isShop = true;
        viewerShopId = sid;
        break;
      }
    }
  } else {
    const shop = order.shopId && (typeof order.shopId === 'object' && order.shopId.ownerId)
      ? order.shopId
      : await Shop.findById(order.shopId);
    isShop = _userOwnsShop(userId, shop);
    if (isShop && shop) viewerShopId = shop._id;
  }
  const isAdmin = roles.includes('admin');
  if (!isCustomer && !isShop && !isAdmin) throw forbidden('Not allowed to view this order');
  if (isShop && viewerShopId && order.shopPortions && order.shopPortions.length > 0) {
    const portion = _getShopPortionForShop(order, viewerShopId);
    if (portion) return attachVoiceCallIds(_toShopViewOrder(order, portion));
  }
  return attachVoiceCallIds(order);
}

async function getCallTargets(orderId, userId, roles) {
  const order = await getById(orderId, userId, roles);
  return {
    customerUserId: order.customerUserId ?? null,
    driverUserId: order.driverUserId ?? null,
  };
}

async function updateStatus(orderId, userId, roles, payload) {
  const order = await Order.findById(orderId);
  if (!order) throw notFound('Order not found');
  let isShop = false;
  if (order.shopPortions && order.shopPortions.length > 0) {
    const shops = await Shop.find({ ownerId: userId }).distinct('_id');
    const shopIds = shops.map((s) => s.toString());
    isShop = order.shopPortions.some((p) => {
      const sid = p.shopId && p.shopId.toString ? p.shopId.toString() : null;
      return sid && shopIds.includes(sid);
    });
  } else if (order.shopId) {
    const shop = await Shop.findById(order.shopId);
    isShop = shop && shop.ownerId.toString() === userId.toString();
  }
  const orderDriverIdRaw = order.driverId;
  const orderDriverIdStr = orderDriverIdRaw
    ? typeof orderDriverIdRaw === 'object' && orderDriverIdRaw._id
      ? orderDriverIdRaw._id.toString()
      : orderDriverIdRaw.toString()
    : null;
  const orderDriverId = orderDriverIdStr || null;
  const isAdmin = roles.includes('admin');

  let role;
  if (isAdmin) {
    role = 'admin';
  } else if (isShop) {
    role = 'shop';
  } else {
    role = 'customer';
  }

  const currentStatusNorm = normalizeOrderStatusForTransition(order.status);

  if (!canChangeStatus(currentStatusNorm, payload.status, role, orderDriverId, userId)) {
    const statusAr = {
      [ORDER_STATUS.PENDING]: 'قيد الانتظار',
      [ORDER_STATUS.ACCEPTED]: 'مقبول',
      [ORDER_STATUS.PREPARING]: 'قيد التحضير',
      [ORDER_STATUS.ON_THE_WAY]: 'في الطريق',
      [ORDER_STATUS.DELIVERED]: 'تم التوصيل',
      [ORDER_STATUS.CANCELED]: 'ملغي',
      [ORDER_STATUS.POSTPONED]: 'مؤجل',
    };
    const currentAr = statusAr[currentStatusNorm] || order.status;
    const targetAr = statusAr[payload.status] || payload.status;
    let msg;
    let code = 'INVALID_TRANSITION';
    if (payload.status === ORDER_STATUS.CANCELED) {
      msg = `لا يمكن إلغاء الطلب في الحالة الحالية (${currentAr}).`;
      code = 'CANCEL_NOT_ALLOWED';
    } else if (
      payload.status === ORDER_STATUS.DELIVERED &&
      role !== 'shop' &&
      role !== 'admin'
    ) {
      msg = 'التسليم مسموح لصاحب المحل أو الإدارة فقط.';
      code = 'DELIVER_NOT_ALLOWED';
    } else {
      msg = `لا يمكن تغيير الحالة من "${currentAr}" إلى "${targetAr}". تحقق من حالة الطلب الحالية.`;
    }
    throw badRequest(msg, code);
  }

  if (payload.status === ORDER_STATUS.CANCELED && role === 'shop') {
    const reason = (payload.cancelReason || '').trim();
    if (!reason || reason.length < 3) throw badRequest('سبب الإلغاء مطلوب (3 أحرف على الأقل)');
  }
  if (payload.status === ORDER_STATUS.POSTPONED) {
    const reason = (payload.postponedReason || '').trim();
    if (!reason || reason.length < 3) throw badRequest('سبب التأجيل مطلوب (3 أحرف على الأقل)');
  }

  const updates = { status: payload.status };
  if (payload.status === ORDER_STATUS.CANCELED && payload.cancelReason) {
    order.cancelReason = (payload.cancelReason || '').trim();
  }
  if (payload.status === ORDER_STATUS.POSTPONED && payload.postponedReason) {
    order.postponedReason = (payload.postponedReason || '').trim();
  }
  const previousStatus = order.status;

  order.status = updates.status;
  order.statusHistory.push({
    status: updates.status,
    changedBy: userId,
    changedByRole: role,
    changedAt: new Date(),
  });
  await order.save();
  const updatedOrder = await populateOrderForResponseQuery(Order.findById(orderId));
  notifyOrderStatusChange(updatedOrder, previousStatus, role).catch((err) =>
    console.error('[Telegram] notifyOrderStatusChange:', err?.message)
  );
  return attachVoiceCallIds(updatedOrder);
}

async function cancelByCustomer(orderId, customerId) {
  const order = await Order.findById(orderId);
  if (!order) throw notFound('Order not found');

  if (order.customerId?.toString() !== String(customerId)) {
    throw forbidden('Not allowed to cancel this order');
  }

  if (order.status !== ORDER_STATUS.PENDING) {
    throw badRequest('يمكن إلغاء الطلب فقط عندما تكون حالته قيد الانتظار');
  }

  const previousStatus = order.status;
  order.status = ORDER_STATUS.CANCELED;
  order.statusHistory.push({
    status: ORDER_STATUS.CANCELED,
    changedBy: customerId,
    changedByRole: 'customer',
    changedAt: new Date(),
  });
  await order.save();

  const updatedOrder = await populateOrderForResponseQuery(Order.findById(orderId));
  notifyOrderStatusChange(updatedOrder, previousStatus, 'customer').catch((err) =>
    console.error('[Telegram] notifyOrderStatusChange:', err?.message)
  );
  return attachVoiceCallIds(updatedOrder);
}

module.exports = {
  create,
  quoteDiscountForCart,
  createVoiceOrder,
  listByUser,
  getById,
  getCallTargets,
  updateStatus,
  cancelByCustomer,
  // يضيف customerUserId/driverUserId ويُسطّح عناصر الطلب مع حقل image — للـ WebSocket والردود الموحّدة.
  formatOrderForClient: attachVoiceCallIds,
};
