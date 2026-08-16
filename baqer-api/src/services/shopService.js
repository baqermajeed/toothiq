const path = require('path');
const fs = require('fs');
const mongoose = require('mongoose');
const { Shop, ShopReview } = require('../models');
const { notFound, forbidden } = require('../utils/errors');

function deleteShopImageIfLocal(imagePath) {
  if (!imagePath || typeof imagePath !== 'string') return;
  const normalized = imagePath.replace(/^\/+/, '');
  if (!normalized.startsWith('uploads/shops/')) return;
  const filePath = path.join(__dirname, '..', '..', normalized);
  try {
    if (fs.existsSync(filePath)) fs.unlinkSync(filePath);
  } catch (_) {}
}

async function list(filters = {}) {
  const { isOpen, page = 1, limit = 20 } = filters;
  const query = { isActive: true, isHidden: { $ne: true } };
  if (typeof isOpen === 'boolean') query.isOpen = isOpen;

  const skip = (Number(page) - 1) * Number(limit);
  const limitNum = Number(limit);
  const pageNum = Number(page);

  const [items, total] = await Promise.all([
    Shop.find(query)
      .sort({ rating: -1, ratingCount: -1, name: 1 })
      .skip(skip)
      .limit(limitNum)
      .lean(),
    Shop.countDocuments(query),
  ]);
  return { items, pagination: { page: pageNum, limit: limitNum, total } };
}

async function create(ownerId, body) {
  const shop = await Shop.create({
    ownerId,
    name: body.name,
    description: body.description,
    location: body.location,
    address: body.address?.trim() || null,
    phone: body.phone?.trim() || null,
    phone2: body.phone2?.trim() || null,
    deliveryFee: 0,
    isOpen: true,
    openHours: { from: '', to: '' },
    image: body.image,
  });
  return shop;
}

async function getByOwnerId(userId) {
  const shop = await Shop.findOne({ ownerId: userId }).populate('ownerId', 'name phone roles').lean();
  if (!shop) throw notFound('Shop not found');
  return shop;
}

async function getById(id) {
  const shop = await Shop.findById(id).populate('ownerId', 'name phone roles');
  if (!shop) throw notFound('Shop not found');
  return shop;
}

async function updateById(shopId, userId, body, userRoles = []) {
  const shop = await Shop.findById(shopId);
  if (!shop) throw notFound('Shop not found');
  const isAdmin = Array.isArray(userRoles) && userRoles.includes('admin');
  const isOwner = shop.ownerId.toString() === userId.toString();
  if (!isAdmin && !isOwner) throw forbidden('Not the shop owner');
  if (shop.image && body.image && shop.image !== body.image) {
    deleteShopImageIfLocal(shop.image);
  }
  Object.assign(shop, body);
  await shop.save();
  return shop;
}

async function refreshShopRating(shopId) {
  const stats = await ShopReview.aggregate([
    { $match: { shopId: new mongoose.Types.ObjectId(shopId) } },
    {
      $group: {
        _id: '$shopId',
        avgRating: { $avg: '$rating' },
        ratingCount: { $sum: 1 },
      },
    },
  ]);

  const avgRating = stats[0]?.avgRating || 0;
  const ratingCount = stats[0]?.ratingCount || 0;

  await Shop.findByIdAndUpdate(shopId, {
    rating: Number(avgRating.toFixed(2)),
    ratingCount,
  });
}

async function upsertReview(shopId, userId, body) {
  const shop = await Shop.findById(shopId);
  if (!shop || !shop.isActive || shop.isHidden) throw notFound('Shop not found');
  if (shop.ownerId.toString() === userId.toString()) {
    throw forbidden('لا يمكن لصاحب المحل تقييم محله');
  }

  const review = await ShopReview.findOneAndUpdate(
    { shopId, userId },
    { rating: body.rating, comment: body.comment },
    { new: true, upsert: true, setDefaultsOnInsert: true }
  ).populate('userId', 'name');

  await refreshShopRating(shopId);
  return review;
}

async function listReviews(shopId, query = {}) {
  const shop = await Shop.findById(shopId).select('_id isActive isHidden');
  if (!shop || !shop.isActive || shop.isHidden) throw notFound('Shop not found');

  const pageNum = Math.max(Number(query.page) || 1, 1);
  const limitNum = Math.min(Math.max(Number(query.limit) || 20, 1), 100);
  const skip = (pageNum - 1) * limitNum;

  const [items, total] = await Promise.all([
    ShopReview.find({ shopId })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limitNum)
      .populate('userId', 'name')
      .lean(),
    ShopReview.countDocuments({ shopId }),
  ]);

  return { items, pagination: { page: pageNum, limit: limitNum, total } };
}

module.exports = { list, create, getById, getByOwnerId, updateById, upsertReview, listReviews };
