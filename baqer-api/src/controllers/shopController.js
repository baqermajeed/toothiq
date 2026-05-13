const shopService = require('../services/shopService');
const { extractObjectIdHex } = require('../validators/common');
const {
  validateCreateShop,
  validateUpdateShop,
  validateCreateShopReview,
  validateListShopReviewsQuery,
} = require('../validators/shops');
const { badRequest } = require('../utils/errors');

function normalizeDigitsToLatin(s) {
  if (s == null || typeof s !== 'string') return s;
  const map = { '٠': '0', '١': '1', '٢': '2', '٣': '3', '٤': '4', '٥': '5', '٦': '6', '٧': '7', '٨': '8', '٩': '9' };
  return s
    .split('')
    .map((c) => map[c] || c)
    .join('');
}

function parseShopBody(raw) {
  const body = {};
  if (raw.name !== undefined) body.name = typeof raw.name === 'string' ? raw.name.trim() : raw.name;
  if (raw.description !== undefined) body.description = typeof raw.description === 'string' ? raw.description.trim() : raw.description;
  if (raw.deliveryFee !== undefined) body.deliveryFee = typeof raw.deliveryFee === 'number' ? raw.deliveryFee : parseFloat(raw.deliveryFee);
  if (raw.isOpen !== undefined) body.isOpen = raw.isOpen === true || raw.isOpen === 'true';
  if (raw.isActive !== undefined) body.isActive = raw.isActive === true || raw.isActive === 'true';
  if (raw.isHidden !== undefined) body.isHidden = raw.isHidden === true || raw.isHidden === 'true';
  if (raw.image !== undefined && raw.image !== '') body.image = typeof raw.image === 'string' ? raw.image.trim() : raw.image;
  if (raw.openHoursFrom !== undefined || raw.openHoursTo !== undefined) {
    body.openHours = {
      from: (raw.openHoursFrom != null && raw.openHoursFrom !== '') ? String(raw.openHoursFrom).trim() : '',
      to: (raw.openHoursTo != null && raw.openHoursTo !== '') ? String(raw.openHoursTo).trim() : '',
    };
  } else if (raw.openHours !== undefined) body.openHours = typeof raw.openHours === 'object' ? raw.openHours : undefined;
  if (raw.ownerId !== undefined && raw.ownerId !== null && raw.ownerId !== '') {
    const r = extractObjectIdHex(raw.ownerId);
    if ('id' in r) {
      body.ownerId = r.id;
    } else if (r.invalid) {
      body.ownerId = raw.ownerId;
    }
  }
  if (raw.ownerPhone !== undefined && raw.ownerPhone !== '') {
    body.ownerPhone = normalizeDigitsToLatin(String(raw.ownerPhone).trim());
  }
  if (raw.ownerPassword !== undefined && raw.ownerPassword !== '') body.ownerPassword = String(raw.ownerPassword);
  if (raw.ownerName !== undefined) body.ownerName = typeof raw.ownerName === 'string' ? raw.ownerName.trim() : raw.ownerName;
  if (raw.ownerGovernorateId !== undefined && raw.ownerGovernorateId !== '') {
    body.ownerGovernorateId = String(raw.ownerGovernorateId).trim();
  }
  if (raw.location !== undefined && raw.location !== null) {
    if (typeof raw.location === 'object' && Array.isArray(raw.location.coordinates)) {
      body.location = raw.location;
    } else if (typeof raw.location === 'string') {
      try {
        body.location = JSON.parse(raw.location);
      } catch (_) {}
    }
  }
  if (body.location == null && raw.lng != null && raw.lat != null) {
    const lng = typeof raw.lng === 'number' ? raw.lng : parseFloat(raw.lng);
    const lat = typeof raw.lat === 'number' ? raw.lat : parseFloat(raw.lat);
    if (Number.isFinite(lng) && Number.isFinite(lat)) {
      body.location = { type: 'Point', coordinates: [lng, lat] };
    }
  }
  return body;
}

async function list(req, res, next) {
  try {
    const filters = { ...req.query };
    const result = await shopService.list(filters);
    res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
}

async function create(req, res, next) {
  try {
    const body = parseShopBody(req.body);
    const { error, value } = validateCreateShop(body);
    if (error) {
      const message = error.details ? error.details.map((d) => d.message).join('; ') : error.message;
      return next(badRequest(message, 'VALIDATION_ERROR'));
    }
    const shop = await shopService.create(req.userId, value);
    res.status(201).json({ success: true, data: shop });
  } catch (err) {
    next(err);
  }
}

async function getMyShop(req, res, next) {
  try {
    const shop = await shopService.getByOwnerId(req.userId);
    res.json({ success: true, data: shop });
  } catch (err) {
    next(err);
  }
}

async function getById(req, res, next) {
  try {
    const shop = await shopService.getById(req.params.id);
    if (shop.isHidden) {
      const isAdmin = Array.isArray(req.userRoles) && req.userRoles.includes('admin');
      const ownerIdStr = shop.ownerId && (shop.ownerId._id ? shop.ownerId._id : shop.ownerId).toString();
      const isOwner = ownerIdStr && req.userId && ownerIdStr === req.userId.toString();
      if (!isAdmin && !isOwner) {
        return next(require('../utils/errors').notFound('Shop not found'));
      }
    }
    res.json({ success: true, data: shop });
  } catch (err) {
    next(err);
  }
}

async function updateById(req, res, next) {
  try {
    const body = parseShopBody(req.body);
    const { error, value } = validateUpdateShop(body);
    if (error) {
      const message = error.details ? error.details.map((d) => d.message).join('; ') : error.message;
      return next(badRequest(message, 'VALIDATION_ERROR'));
    }
    const shop = await shopService.updateById(req.params.id, req.userId, value, req.userRoles);
    res.json({ success: true, data: shop });
  } catch (err) {
    next(err);
  }
}

async function createReview(req, res, next) {
  try {
    const body = {
      rating: typeof req.body.rating === 'number' ? req.body.rating : Number(req.body.rating),
      comment: req.body.comment,
    };
    const { error, value } = validateCreateShopReview(body);
    if (error) {
      const message = error.details ? error.details.map((d) => d.message).join('; ') : error.message;
      return next(badRequest(message, 'VALIDATION_ERROR'));
    }
    const review = await shopService.upsertReview(req.params.id, req.userId, value);
    res.status(201).json({ success: true, data: review });
  } catch (err) {
    next(err);
  }
}

async function listReviews(req, res, next) {
  try {
    const { error, value } = validateListShopReviewsQuery(req.query);
    if (error) {
      const message = error.details ? error.details.map((d) => d.message).join('; ') : error.message;
      return next(badRequest(message, 'VALIDATION_ERROR'));
    }
    const result = await shopService.listReviews(req.params.id, value);
    res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
}

module.exports = { list, create, getById, getMyShop, updateById, createReview, listReviews, parseShopBody };
