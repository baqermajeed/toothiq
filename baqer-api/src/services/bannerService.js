const path = require('path');
const fs = require('fs');
const { Banner } = require('../models');
const { notFound, badRequest } = require('../utils/errors');

function deleteBannerImageIfLocal(imagePath) {
  if (!imagePath || typeof imagePath !== 'string') return;
  const normalized = imagePath.replace(/^\/+/, '');
  if (!normalized.startsWith('uploads/banners/')) return;
  const filePath = path.join(__dirname, '..', '..', normalized);
  try {
    if (fs.existsSync(filePath)) fs.unlinkSync(filePath);
  } catch (_) {}
}

/**
 * List active banners for the app (public).
 * Returns banners sorted by order, with shopId and productId populated.
 * يُرجع كل البانرات النشطة بدون أي اعتماد على موقع المستخدم.
 */
async function list() {
  const items = await Banner.find({ isActive: true })
    .sort({ order: 1 })
    .populate('shopId')
    .populate({
      path: 'productId',
      populate: { path: 'shopId', select: 'name' },
    })
    .lean();

  return items.map((b) => toAppBanner(b));
}

function toAppBanner(b) {
  const shopRef = b.shopId;
  const shopId =
    shopRef && typeof shopRef === 'object' && shopRef._id
      ? String(shopRef._id)
      : shopRef
        ? String(shopRef)
        : null;
  const productRef = b.productId;
  const productId =
    productRef && typeof productRef === 'object' && productRef._id
      ? String(productRef._id)
      : productRef
        ? String(productRef)
        : null;

  const obj = {
    _id: b._id?.toString(),
    image: b.image,
    title: b.title || null,
    actionType: b.actionType || 'none',
    shopId: b.actionType === 'shop' ? shopId : null,
    productId: b.actionType === 'product' ? productId : null,
  };
  if (b.actionType === 'shop' && shopRef) {
    obj.shop = typeof shopRef === 'object' ? shopRef : { _id: shopId };
  }
  if (b.actionType === 'product' && productRef) {
    if (typeof productRef === 'object') {
      const shop = productRef.shopId;
      obj.product = {
        _id: productId,
        id: productId,
        name: productRef.name,
        description: productRef.description,
        price: productRef.price,
        image: productRef.image,
        isAvailable: productRef.isAvailable,
        shopId: shop?._id?.toString() || shop?.toString?.() || null,
        shopName: shop?.name ?? null,
      };
    }
  }
  if (b.actionType === 'external_url' && b.externalUrl) {
    obj.externalUrl = b.externalUrl;
  }
  return obj;
}

/**
 * List all banners for admin (including inactive).
 */
async function listAdmin() {
  return Banner.find().sort({ order: 1 }).populate('shopId', 'name').populate('productId', 'name price').lean();
}

/**
 * Create banner (admin).
 */
async function create(body) {
  validateActionPayload(body);
  const banner = await Banner.create({
    image: body.image,
    title: body.title,
    actionType: body.actionType || 'none',
    shopId: body.actionType === 'shop' ? body.shopId : null,
    productId: body.actionType === 'product' ? body.productId : null,
    externalUrl: body.actionType === 'external_url' ? body.externalUrl : null,
    order: body.order ?? 0,
    isActive: body.isActive !== false,
    polygon: body.polygon,
  });
  return banner;
}

/**
 * Update banner (admin).
 */
async function updateById(id, body) {
  const existing = await Banner.findById(id);
  if (!existing) throw notFound('البانر غير موجود');
  validateActionPayload({ ...existing.toObject(), ...body });
  if (body.image !== undefined) existing.image = body.image;
  if (body.title !== undefined) existing.title = body.title;
  if (body.actionType !== undefined) existing.actionType = body.actionType;
  const nextType = existing.actionType;
  if (nextType === 'shop') {
    if (body.shopId !== undefined) existing.shopId = body.shopId || undefined;
    if (body.actionType !== undefined) {
      existing.productId = undefined;
      existing.externalUrl = undefined;
    }
  } else if (nextType === 'product') {
    if (body.productId !== undefined) existing.productId = body.productId || undefined;
    if (body.actionType !== undefined) {
      existing.shopId = undefined;
      existing.externalUrl = undefined;
    }
  } else if (nextType === 'external_url') {
    if (body.externalUrl !== undefined) existing.externalUrl = body.externalUrl;
    if (body.actionType !== undefined) {
      existing.shopId = undefined;
      existing.productId = undefined;
    }
  } else if (body.actionType !== undefined) {
    existing.shopId = undefined;
    existing.productId = undefined;
    existing.externalUrl = undefined;
  }
  if (body.order !== undefined) existing.order = body.order;
  if (body.isActive !== undefined) existing.isActive = body.isActive;
  if (body.polygon !== undefined) existing.polygon = body.polygon;
  await existing.save();
  return existing;
}

/**
 * Delete banner (admin).
 */
async function deleteById(id) {
  const banner = await Banner.findByIdAndDelete(id);
  if (!banner) throw notFound('البانر غير موجود');
  deleteBannerImageIfLocal(banner.image);
  return { deleted: true };
}

function validateActionPayload(body) {
  const { actionType, shopId, productId, externalUrl } = body;
  if (!actionType || actionType === 'none') return;
  if (actionType === 'shop') {
    if (!shopId) throw badRequest('يجب اختيار محل عند الربط بمتجر');
  }
  if (actionType === 'product') {
    if (!productId) throw badRequest('يجب اختيار منتج عند الربط بمنتج');
  }
  if (actionType === 'external_url') {
    if (!externalUrl || typeof externalUrl !== 'string' || externalUrl.trim() === '') {
      throw badRequest('يجب إدخال رابط خارجي');
    }
  }
}

module.exports = { list, listAdmin, create, updateById, deleteById };
