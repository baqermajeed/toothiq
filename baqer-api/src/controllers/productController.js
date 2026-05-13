const productService = require('../services/productService');
const productCategoryService = require('../services/productCategoryService');
const { validateCreateProduct, validateUpdateProduct, validateBulkBody, validateCopyFromShopBody } = require('../validators/products');
const { badRequest, notFound, forbidden } = require('../utils/errors');
const { Shop } = require('../models');

const NAME_MAX_LENGTH = 200;

/**
 * تحليل السعر من نص قد يحتوي "د.ع" أو "د.ك" أو فواصل.
 * @param {string} priceStr
 * @returns {number|null} الرقم أو null إذا غير صالح
 */
function parsePrice(priceStr) {
  if (typeof priceStr !== 'string') return null;
  const cleaned = priceStr
    .replace(/د\.ع|د\.ك|دينار|د\.ا|IQD|KWD/gi, '')
    .replace(/,/g, '')
    .trim();
  const num = Number(cleaned);
  return Number.isFinite(num) && num >= 0 ? num : null;
}

/**
 * تحليل نص الإضافة السريعة مع الفئات: ثلاثيات (اسم، سعر، فئة).
 * @param {string} text
 * @returns {{ valid: { name: string, price: number, categoryName: string }[], failed: { lineIndex?: number, name?: string, reason: string }[] }}
 */
function parseBulkProductWithCategoryText(text) {
  const valid = [];
  const failed = [];
  const lines = (typeof text === 'string' ? text : '')
    .split(/\r?\n/)
    .map((s) => s.trim())
    .filter((s) => s.length > 0);
  for (let i = 0; i < lines.length; i += 3) {
    const nameLine = lines[i];
    const priceLine = lines[i + 1];
    const categoryLine = lines[i + 2];
    const tripletIndex = Math.floor(i / 3) + 1;
    if (priceLine === undefined) {
      failed.push({
        lineIndex: tripletIndex,
        name: nameLine,
        reason: 'اسم بدون سعر في نهاية النص',
      });
      continue;
    }
    if (categoryLine === undefined) {
      failed.push({
        lineIndex: tripletIndex,
        name: nameLine,
        reason: 'اسم وسعر بدون فئة في نهاية النص',
      });
      continue;
    }
    const name = nameLine.trim();
    if (!name || name.length === 0) {
      failed.push({
        lineIndex: tripletIndex,
        name: nameLine,
        reason: 'الاسم مطلوب ولا يمكن أن يكون فارغاً',
      });
      continue;
    }
    if (name.length > NAME_MAX_LENGTH) {
      failed.push({
        lineIndex: tripletIndex,
        name,
        reason: 'الاسم أطول من 200 حرف',
      });
      continue;
    }
    const price = parsePrice(priceLine);
    if (price === null) {
      failed.push({
        lineIndex: tripletIndex,
        name,
        reason: `السعر غير صالح (السطر ${i + 2}): "${priceLine}" - يجب أن يكون رقماً موجباً`,
      });
      continue;
    }
    const categoryName = (categoryLine || '').replace(/\.+$/, '').trim();
    if (!categoryName || categoryName.length === 0) {
      failed.push({
        lineIndex: tripletIndex,
        name,
        reason: 'اسم الفئة مطلوب ولا يمكن أن يكون فارغاً',
      });
      continue;
    }
    valid.push({ name, price, categoryName });
  }
  return { valid, failed };
}

/**
 * تحليل نص الإضافة السريعة: أزواج (اسم ثم سطر جديد ثم سعر).
 * @param {string} text
 * @returns {{ valid: { name: string, price: number }[], failed: { lineIndex?: number, name?: string, reason: string }[] }}
 */
function parseBulkProductText(text) {
  const valid = [];
  const failed = [];
  const lines = (typeof text === 'string' ? text : '')
    .split(/\r?\n/)
    .map((s) => s.trim())
    .filter((s) => s.length > 0);
  for (let i = 0; i < lines.length; i += 2) {
    const nameLine = lines[i];
    const priceLine = lines[i + 1];
    const pairIndex = Math.floor(i / 2) + 1;
    if (priceLine === undefined) {
      failed.push({
        lineIndex: pairIndex,
        name: nameLine,
        reason: 'اسم بدون سعر في نهاية النص',
      });
      continue;
    }
    const name = nameLine.trim();
    if (!name || name.length === 0) {
      failed.push({
        lineIndex: pairIndex,
        name: nameLine,
        reason: 'الاسم مطلوب ولا يمكن أن يكون فارغاً',
      });
      continue;
    }
    if (name.length > NAME_MAX_LENGTH) {
      failed.push({
        lineIndex: pairIndex,
        name: name,
        reason: 'الاسم أطول من 200 حرف',
      });
      continue;
    }
    const num = Number(priceLine);
    if (Number.isNaN(num) || num < 0) {
      failed.push({
        lineIndex: pairIndex,
        name,
        reason: `السعر يجب أن يكون رقماً موجباً (السطر ${i + 2})`,
      });
      continue;
    }
    valid.push({ name, price: num });
  }
  return { valid, failed };
}

function parseProductBody(raw) {
  const body = {};
  if (raw.name !== undefined) body.name = typeof raw.name === 'string' ? raw.name.trim() : raw.name;
  if (raw.description !== undefined) body.description = typeof raw.description === 'string' ? raw.description.trim() : raw.description;
  if (raw.price !== undefined) body.price = typeof raw.price === 'number' ? raw.price : parseFloat(raw.price);
  if (raw.image !== undefined && raw.image !== '') body.image = typeof raw.image === 'string' ? raw.image.trim() : raw.image;
  if (raw.images !== undefined) {
    let source = raw.images;
    if (typeof source === 'string') {
      const trimmed = source.trim();
      if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
        try {
          const parsed = JSON.parse(trimmed);
          if (Array.isArray(parsed)) source = parsed;
        } catch (_) {}
      }
    }
    source = Array.isArray(source) ? source : [source];
    body.images = source
      .map((v) => (typeof v === 'string' ? v.trim() : v))
      .filter((v) => typeof v === 'string' && v.length > 0);
  }
  if (raw.isAvailable !== undefined) body.isAvailable = raw.isAvailable === true || raw.isAvailable === 'true';
  if (raw.categoryId !== undefined) {
    const v = raw.categoryId;
    body.categoryId = v === '' || v === null ? null : typeof v === 'string' ? v.trim() : v;
  }
  if (raw.subcategoryId !== undefined) {
    const v = raw.subcategoryId;
    body.subcategoryId = v === '' || v === null ? null : typeof v === 'string' ? v.trim() : v;
  }
  if (raw.brandId !== undefined) {
    const v = raw.brandId;
    body.brandId = v === '' || v === null ? null : typeof v === 'string' ? v.trim() : v;
  }
  if (raw.productCategoryId !== undefined) {
    const v = raw.productCategoryId;
    body.productCategoryId = (v === '' || v === null) ? null : (typeof v === 'string' ? v.trim() : v);
  }
  if (raw.offerPrice !== undefined) body.offerPrice = raw.offerPrice === null || raw.offerPrice === '' ? null : (typeof raw.offerPrice === 'number' ? raw.offerPrice : parseFloat(raw.offerPrice));
  if (raw.offerEndsAt !== undefined) body.offerEndsAt = (raw.offerEndsAt === null || raw.offerEndsAt === '') ? null : (raw.offerEndsAt instanceof Date ? raw.offerEndsAt : new Date(raw.offerEndsAt));
  if (raw.productionDate !== undefined) body.productionDate = (raw.productionDate === null || raw.productionDate === '') ? null : (raw.productionDate instanceof Date ? raw.productionDate : new Date(raw.productionDate));
  if (raw.expiryDate !== undefined) body.expiryDate = (raw.expiryDate === null || raw.expiryDate === '') ? null : (raw.expiryDate instanceof Date ? raw.expiryDate : new Date(raw.expiryDate));
  return body;
}

async function listMissingImages(req, res, next) {
  try {
    const shop = await Shop.findById(req.params.shopId).select('isHidden ownerId').lean();
    if (!shop) {
      return next(notFound('Shop not found'));
    }
    const isAdmin = Array.isArray(req.userRoles) && req.userRoles.includes('admin');
    const ownerIdStr = shop.ownerId && shop.ownerId.toString();
    const isOwner = ownerIdStr && req.userId && ownerIdStr === req.userId.toString();
    if (shop.isHidden && !isAdmin && !isOwner) {
      return next(notFound('Shop not found'));
    }
    if (!isAdmin && !isOwner) {
      return next(forbidden('Not the shop owner'));
    }
    const page = req.query.page != null ? Number(req.query.page) : 1;
    const limit = req.query.limit != null ? Number(req.query.limit) : 50;
    const result = await productService.listMissingImagesByShop(req.params.shopId, { page, limit });
    res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
}

async function list(req, res, next) {
  try {
    const shop = await Shop.findById(req.params.shopId).select('isHidden ownerId').lean();
    if (!shop) {
      const hasPagination = req.query.page != null && req.query.limit != null;
      const limitNum = Number(req.query.limit) || 20;
      const pageNum = Number(req.query.page) || 1;
      return res.json({
        success: true,
        data: hasPagination ? { items: [], pagination: { page: pageNum, limit: limitNum, total: 0 } } : [],
      });
    }
    const isAdmin = Array.isArray(req.userRoles) && req.userRoles.includes('admin');
    const ownerIdStr = shop.ownerId && shop.ownerId.toString();
    const isOwner = ownerIdStr && req.userId && ownerIdStr === req.userId.toString();
    const canSeeHiddenShop = isAdmin || isOwner;
    if (shop.isHidden && !canSeeHiddenShop) {
      const hasPagination = req.query.page != null && req.query.limit != null;
      const limitNum = Number(req.query.limit) || 20;
      const pageNum = Number(req.query.page) || 1;
      return res.json({
        success: true,
        data: hasPagination ? { items: [], pagination: { page: pageNum, limit: limitNum, total: 0 } } : [],
      });
    }
    const pagination = req.query.page != null && req.query.limit != null
      ? { page: req.query.page, limit: req.query.limit }
      : {};
    const q = typeof req.query.q === 'string' ? req.query.q.trim() : '';
    const productCategoryId = typeof req.query.productCategoryId === 'string' ? req.query.productCategoryId.trim() || undefined : undefined;
    const hasOffer = req.query.hasOffer === 'true' || req.query.hasOffer === true;
    const includeUnavailable = canSeeHiddenShop;
    const options = {
      ...pagination,
      q: q || undefined,
      productCategoryId,
      hasOffer: hasOffer || undefined,
      includeUnavailable,
    };
    const result = await productService.listByShop(req.params.shopId, options);
    res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
}

async function create(req, res, next) {
  try {
    const body = parseProductBody(req.body);
    const { error, value } = validateCreateProduct(body);
    if (error) {
      const message = error.details ? error.details.map((d) => d.message).join('; ') : error.message;
      return next(badRequest(message, 'VALIDATION_ERROR'));
    }
    const product = await productService.create(
      req.params.shopId,
      req.userId,
      value,
      req.userRoles || []
    );
    res.status(201).json({ success: true, data: product });
  } catch (err) {
    next(err);
  }
}

async function bulkCreate(req, res, next) {
  try {
    const body = req.body && typeof req.body === 'object' ? req.body : {};
    const { error, value } = validateBulkBody(body);
    if (error) {
      const message = error.details ? error.details.map((d) => d.message).join('; ') : error.message;
      return next(badRequest(message || 'نص المنتجات مطلوب', 'VALIDATION_ERROR'));
    }
    const text = typeof value.text === 'string' ? value.text.trim() : '';
    if (!text) {
      return next(badRequest('نص المنتجات مطلوب', 'VALIDATION_ERROR'));
    }
    const { valid, failed: parseFailed } = parseBulkProductText(text);
    // إذا وُجد أي خطأ في التحليل لا نضيف أي منتج
    if (parseFailed.length > 0) {
      return res.status(200).json({
        success: true,
        data: { created: [], failed: parseFailed },
      });
    }
    let created = [];
    let allFailed = [];
    if (valid.length > 0) {
      const result = await productService.bulkCreate(
        req.params.shopId,
        req.userId,
        req.userRoles || [],
        valid
      );
      created = result.created;
      allFailed = result.failed || [];
    }
    res.status(200).json({
      success: true,
      data: { created, failed: allFailed },
    });
  } catch (err) {
    next(err);
  }
}

async function bulkCreateWithCategories(req, res, next) {
  try {
    const body = req.body && typeof req.body === 'object' ? req.body : {};
    const { error, value } = validateBulkBody(body);
    if (error) {
      const message = error.details ? error.details.map((d) => d.message).join('; ') : error.message;
      return next(badRequest(message || 'نص المنتجات مطلوب', 'VALIDATION_ERROR'));
    }
    const text = typeof value.text === 'string' ? value.text.trim() : '';
    if (!text) {
      return next(badRequest('نص المنتجات مطلوب', 'VALIDATION_ERROR'));
    }
    const { valid: parsedItems, failed: parseFailed } = parseBulkProductWithCategoryText(text);
    if (parseFailed.length > 0) {
      return res.status(200).json({
        success: true,
        data: { created: [], failed: parseFailed },
      });
    }
    const categories = await productCategoryService.listByShop(req.params.shopId, { activeOnly: false });
    const categoryMap = {};
    for (const c of categories) {
      const key = (c.nameAr || '').trim().replace(/\.+$/, '');
      if (key) categoryMap[key] = c.id;
    }
    const valid = [];
    const failed = [];
    for (let i = 0; i < parsedItems.length; i++) {
      const item = parsedItems[i];
      const catKey = item.categoryName;
      const productCategoryId = categoryMap[catKey];
      if (!productCategoryId) {
        failed.push({
          lineIndex: i + 1,
          name: item.name,
          reason: `الفئة "${item.categoryName}" غير موجودة في هذا المحل. أضف الفئة أولاً أو تحقق من الاسم.`,
        });
        continue;
      }
      valid.push({ name: item.name, price: item.price, productCategoryId });
    }
    if (failed.length > 0) {
      return res.status(200).json({
        success: true,
        data: { created: [], failed },
      });
    }
    let created = [];
    let allFailed = [];
    if (valid.length > 0) {
      const result = await productService.bulkCreateWithCategories(
        req.params.shopId,
        req.userId,
        req.userRoles || [],
        valid
      );
      created = result.created;
      allFailed = result.failed || [];
    }
    res.status(200).json({
      success: true,
      data: { created, failed: allFailed },
    });
  } catch (err) {
    next(err);
  }
}

async function getById(req, res, next) {
  try {
    const shop = await Shop.findById(req.params.shopId).select('isHidden ownerId').lean();
    if (shop && shop.isHidden) {
      const isAdmin = Array.isArray(req.userRoles) && req.userRoles.includes('admin');
      const ownerIdStr = shop.ownerId && shop.ownerId.toString();
      const isOwner = ownerIdStr && req.userId && ownerIdStr === req.userId.toString();
      if (!isAdmin && !isOwner) {
        return next(require('../utils/errors').notFound('Product not found'));
      }
    }
    const product = await productService.getById(req.params.id, req.params.shopId);
    res.json({ success: true, data: product });
  } catch (err) {
    next(err);
  }
}

async function getRecommendations(req, res, next) {
  try {
    const limit = req.query.limit;
    const products = await productService.getRecommendations(
      req.params.shopId,
      req.params.id,
      { limit }
    );
    res.json({ success: true, data: products });
  } catch (err) {
    next(err);
  }
}

async function updateById(req, res, next) {
  try {
    const body = parseProductBody(req.body);
    const { error, value } = validateUpdateProduct(body);
    if (error) {
      const message = error.details ? error.details.map((d) => d.message).join('; ') : error.message;
      return next(badRequest(message, 'VALIDATION_ERROR'));
    }
    const product = await productService.updateById(
      req.params.id,
      req.params.shopId,
      req.userId,
      value,
      req.userRoles || []
    );
    res.json({ success: true, data: product });
  } catch (err) {
    next(err);
  }
}

async function remove(req, res, next) {
  try {
    await productService.remove(req.params.id, req.params.shopId, req.userId, req.userRoles || []);
    res.json({ success: true, data: { message: 'Product deleted' } });
  } catch (err) {
    next(err);
  }
}

function logProductRequest(route, req, location, extra = {}) {
  const coords = location?.coordinates;
  console.log('[Products API]', route, {
    method: req.method,
    query: { ...req.query },
    body: req.method === 'POST' && req.body ? Object.keys(req.body) : undefined,
    location: coords ? { lng: coords[0], lat: coords[1] } : null,
    hasUser: !!req.user,
    ...extra,
  });
}

function logProductResponse(route, result, extra = {}) {
  const total = result?.pagination?.total ?? result?.items?.length ?? 0;
  const count = result?.items?.length ?? 0;
  console.log('[Products API]', route, 'Response:', { itemsCount: count, total, ...extra });
}

async function listAll(req, res, next) {
  try {
    const filters = { page: req.query.page, limit: req.query.limit };
    if (req.query.excludeIds != null) {
      const raw = req.query.excludeIds;
      filters.excludeIds = typeof raw === 'string'
        ? raw.split(',').map((s) => s.trim()).filter(Boolean)
        : Array.isArray(raw) ? raw : [];
    }
    if (req.query.hasOffer === 'true' || req.query.hasOffer === true) {
      filters.hasOffer = true;
    }
    if (req.query.shopId != null && String(req.query.shopId).trim() !== '') {
      filters.shopId = String(req.query.shopId).trim();
    }
    if (req.query.productCategoryId != null && String(req.query.productCategoryId).trim() !== '') {
      filters.productCategoryId = String(req.query.productCategoryId).trim();
    }
    logProductRequest('listAll', req, null);
    const result = await productService.listAll(filters);
    logProductResponse('listAll', result);
    res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
}

async function search(req, res, next) {
  try {
    const q = req.query.q ?? '';
    const qTrim = typeof q === 'string' ? q.trim() : '';
    const pagination = { page: req.query.page, limit: req.query.limit };
    logProductRequest('search (GET)', req, null, { q });
    console.log('[Products API] search (GET) resolved:', {
      qLength: qTrim.length,
      qPreview: qTrim.length > 80 ? `${qTrim.slice(0, 80)}…` : qTrim,
      emptyAfterTrim: qTrim.length === 0,
      page: pagination.page,
      limit: pagination.limit,
    });
    const result = await productService.search(q, {}, pagination);
    logProductResponse('search (GET)', result, { q });
    res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
}

/** بحث عبر POST — نص البحث في الـ body. يدعم q أو qBase64 (لتجنب مشاكل ترميز UTF-8 على iOS). */
async function searchPost(req, res, next) {
  try {
    const body = req.body && typeof req.body === 'object' ? req.body : {};
    let q = body.q ?? '';
    if (typeof body.qBase64 === 'string' && body.qBase64.length > 0) {
      try {
        q = Buffer.from(body.qBase64, 'base64').toString('utf8');
      } catch (_) {}
    }
    const pagination = { page: body.page, limit: body.limit };
    logProductRequest('search (POST)', req, null, { q, bodyKeys: Object.keys(body) });
    const qTrim = typeof q === 'string' ? q.trim() : '';
    console.log('[Products API] search (POST) resolved:', {
      qLength: qTrim.length,
      qPreview: qTrim.length > 80 ? `${qTrim.slice(0, 80)}…` : qTrim,
      emptyAfterTrim: qTrim.length === 0,
      hadQBase64: typeof body.qBase64 === 'string' && body.qBase64.length > 0,
      page: pagination.page,
      limit: pagination.limit,
    });
    const result = await productService.search(q, {}, pagination);
    logProductResponse('search (POST)', result, { q });
    res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
}

async function listRandomMultiShops(req, res, next) {
  try {
    const filters = {
      shopCount: req.query.shopCount,
      perShop: req.query.perShop,
      hasOffer: req.query.hasOffer === 'true' || req.query.hasOffer === true,
      productCategoryId:
        req.query.productCategoryId != null && String(req.query.productCategoryId).trim() !== ''
          ? String(req.query.productCategoryId).trim()
          : undefined,
    };
    const result = await productService.listRandomFromMultipleShops(filters);
    res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
}

async function copyFromShop(req, res, next) {
  try {
    const body = req.body && typeof req.body === 'object' ? req.body : {};
    const { error, value } = validateCopyFromShopBody(body);
    if (error) {
      const message = error.details ? error.details.map((d) => d.message).join('; ') : error.message;
      console.error('[copyFromShop] Validation error:', message, 'body keys:', Object.keys(body));
      return next(badRequest(message || 'معرّف المحل المصدر مطلوب', 'VALIDATION_ERROR'));
    }
    const targetShopId = req.params.shopId;
    const sourceShopId = value.sourceShopId;
    const productIds = Array.isArray(value.productIds) ? value.productIds : [];
    const result = await productService.copyProductsFromShop(targetShopId, sourceShopId, productIds, req.userRoles || []);
    res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  list,
  listMissingImages,
  listAll,
  create,
  bulkCreate,
  bulkCreateWithCategories,
  copyFromShop,
  getById,
  getRecommendations,
  updateById,
  remove,
  search,
  searchPost,
  listRandomMultiShops,
};
