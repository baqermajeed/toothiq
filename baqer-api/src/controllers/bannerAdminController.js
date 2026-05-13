const bannerService = require('../services/bannerService');
const { validateCreateBanner, validateUpdateBanner } = require('../validators/banners');
const { badRequest } = require('../utils/errors');
const { ensurePolygonClosed } = require('../utils/geo');

function parseBannerBody(raw) {
  const body = {};
  if (raw.image !== undefined && raw.image !== '') body.image = typeof raw.image === 'string' ? raw.image.trim() : raw.image;
  if (raw.title !== undefined) body.title = typeof raw.title === 'string' ? raw.title.trim() : raw.title;
  if (raw.actionType !== undefined) body.actionType = raw.actionType;
  if (raw.shopId !== undefined) body.shopId = raw.shopId ? String(raw.shopId).trim() : null;
  if (raw.productId !== undefined) body.productId = raw.productId ? String(raw.productId).trim() : null;
  if (raw.externalUrl !== undefined) body.externalUrl = typeof raw.externalUrl === 'string' ? raw.externalUrl.trim() : raw.externalUrl;
  if (raw.order !== undefined) body.order = Number(raw.order) || 0;
  if (raw.isActive !== undefined) body.isActive = raw.isActive === true || raw.isActive === 'true';
  if (raw.polygon !== undefined) {
    let polygon = raw.polygon;
    if (typeof polygon === 'string') {
      try {
        polygon = JSON.parse(polygon);
      } catch (_) {
        polygon = null;
      }
    }
    if (polygon && polygon.coordinates) {
      ensurePolygonClosed(polygon);
    }
    body.polygon = polygon || null;
  }
  return body;
}

async function list(req, res, next) {
  try {
    const items = await bannerService.listAdmin();
    res.json({ success: true, data: items });
  } catch (err) {
    next(err);
  }
}

async function create(req, res, next) {
  try {
    const body = parseBannerBody(req.body);
    if (req.body?.image) body.image = req.body.image;
    const { error, value } = validateCreateBanner(body);
    if (error) {
      const message = error.details ? error.details.map((d) => d.message).join('; ') : error.message;
      return next(badRequest(message, 'VALIDATION_ERROR'));
    }
    const banner = await bannerService.create(value);
    res.status(201).json({ success: true, data: banner });
  } catch (err) {
    next(err);
  }
}

async function update(req, res, next) {
  try {
    const body = parseBannerBody(req.body);
    if (req.body?.image) body.image = req.body.image;
    const { error, value } = validateUpdateBanner(body);
    if (error) {
      const message = error.details ? error.details.map((d) => d.message).join('; ') : error.message;
      return next(badRequest(message, 'VALIDATION_ERROR'));
    }
    const banner = await bannerService.updateById(req.params.id, value);
    res.json({ success: true, data: banner });
  } catch (err) {
    next(err);
  }
}

async function remove(req, res, next) {
  try {
    await bannerService.deleteById(req.params.id);
    res.json({ success: true, data: { message: 'Banner deleted' } });
  } catch (err) {
    next(err);
  }
}

module.exports = { list, create, update, remove };
