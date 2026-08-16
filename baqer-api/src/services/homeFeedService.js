const mongoose = require('mongoose');
const { Product, Shop, Order, HomeSectionPin } = require('../models');
const { ORDER_STATUS } = require('../config/constants');
const { badRequest, conflict, notFound } = require('../utils/errors');
const productService = require('./productService');

const PRODUCT_SECTIONS = new Set(['best_sellers', 'for_you', 'new']);
const SHOP_SECTIONS = new Set(['top_rated']);
const PRODUCT_POPULATE = [
  { path: 'shopId', select: 'name isOpen' },
  { path: 'productCategoryId', select: 'nameAr' },
  { path: 'categoryId', select: 'nameAr icon' },
  { path: 'subcategoryId', select: 'nameAr' },
  { path: 'brandId', select: 'nameAr' },
];

function parsePage(opts = {}) {
  const page = Math.max(1, Number(opts.page) || 1);
  const limit = Math.min(50, Math.max(1, Number(opts.limit) || 12));
  return { page, limit, skip: (page - 1) * limit };
}

function toId(value) {
  if (value == null) return '';
  if (typeof value === 'object' && value._id) return String(value._id);
  return String(value);
}

function idSet(ids) {
  return new Set((ids || []).map((id) => String(id)).filter(Boolean));
}

async function mergePaged({ pinItems, countAuto, fetchAuto, page, limit }) {
  const pinCount = pinItems.length;
  const autoTotal = await countAuto();
  const total = pinCount + autoTotal;
  const skip = (page - 1) * limit;
  if (skip >= total) {
    return { items: [], pagination: { page, limit, total } };
  }

  let items = [];
  if (skip < pinCount) {
    const pinSlice = pinItems.slice(skip, skip + limit);
    const need = limit - pinSlice.length;
    items = need > 0 ? pinSlice.concat(await fetchAuto(0, need)) : pinSlice;
  } else {
    items = await fetchAuto(skip - pinCount, limit);
  }
  return { items, pagination: { page, limit, total } };
}

async function loadActivePins(section) {
  return HomeSectionPin.find({ section, isActive: { $ne: false } })
    .sort({ order: 1, createdAt: 1 })
    .lean();
}

async function mapPinnedProducts(pins, visibleShopIds) {
  const ids = pins
    .map((pin) => pin.productId)
    .filter((id) => id && mongoose.Types.ObjectId.isValid(String(id)))
    .map((id) => new mongoose.Types.ObjectId(String(id)));
  if (!ids.length) return [];
  const docs = await Product.find({
    _id: { $in: ids },
    isAvailable: true,
    shopId: { $in: visibleShopIds },
  })
    .populate(PRODUCT_POPULATE)
    .lean();
  const byId = new Map(docs.map((doc) => [String(doc._id), doc]));
  return ids
    .map((id) => byId.get(String(id)))
    .filter(Boolean)
    .map((doc) => productService.mapProductForCatalog(doc));
}

async function mapPinnedShops(pins) {
  const ids = pins
    .map((pin) => pin.shopId)
    .filter((id) => id && mongoose.Types.ObjectId.isValid(String(id)))
    .map((id) => new mongoose.Types.ObjectId(String(id)));
  if (!ids.length) return [];
  const docs = await Shop.find({
    _id: { $in: ids },
    isActive: true,
    isHidden: { $ne: true },
  }).lean();
  const byId = new Map(docs.map((doc) => [String(doc._id), doc]));
  return ids.map((id) => byId.get(String(id))).filter(Boolean);
}

async function visibleProductQuery(excludeIds) {
  const visibleShopIds = await productService.getVisibleShopIds();
  const query = { isAvailable: true, shopId: { $in: visibleShopIds } };
  if (excludeIds.length) {
    query._id = { $nin: excludeIds.map((id) => new mongoose.Types.ObjectId(String(id))) };
  }
  return { query, visibleShopIds };
}

async function listNewestAuto(excludeIds, skip, limit) {
  const { query } = await visibleProductQuery(excludeIds);
  const docs = await Product.find(query)
    .populate(PRODUCT_POPULATE)
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(limit)
    .lean();
  return docs.map((doc) => productService.mapProductForCatalog(doc));
}

async function countNewestAuto(excludeIds) {
  const { query } = await visibleProductQuery(excludeIds);
  return Product.countDocuments(query);
}

async function rankedSoldIds(visibleShopIds, excludeSet) {
  const rows = await Order.aggregate([
    { $match: { status: ORDER_STATUS.DELIVERED } },
    {
      $addFields: {
        lineItems: {
          $concatArrays: [
            { $ifNull: ['$items', []] },
            {
              $reduce: {
                input: { $ifNull: ['$shopPortions', []] },
                initialValue: [],
                in: { $concatArrays: ['$$value', { $ifNull: ['$$this.items', []] }] },
              },
            },
          ],
        },
      },
    },
    { $unwind: '$lineItems' },
    {
      $addFields: {
        productId: {
          $switch: {
            branches: [
              {
                case: { $eq: [{ $type: '$lineItems.productId' }, 'objectId'] },
                then: '$lineItems.productId',
              },
              {
                case: { $eq: [{ $type: '$lineItems.productId' }, 'string'] },
                then: {
                  $convert: {
                    input: '$lineItems.productId',
                    to: 'objectId',
                    onError: null,
                    onNull: null,
                  },
                },
              },
            ],
            default: null,
          },
        },
        quantity: { $ifNull: ['$lineItems.quantity', 1] },
      },
    },
    { $match: { productId: { $ne: null } } },
    { $group: { _id: '$productId', sold: { $sum: '$quantity' } } },
    { $match: { sold: { $gt: 0 } } },
    { $sort: { sold: -1 } },
    { $limit: 500 },
  ]);
  const orderedIds = rows.map((row) => row._id).filter(Boolean);
  if (!orderedIds.length) return [];
  const available = await Product.find({
    _id: { $in: orderedIds },
    isAvailable: true,
    shopId: { $in: visibleShopIds },
  })
    .select('_id')
    .lean();
  const availableSet = new Set(available.map((doc) => String(doc._id)));
  return orderedIds
    .map((id) => String(id))
    .filter((id) => availableSet.has(id) && !excludeSet.has(id));
}

async function productsByOrderedIds(ids, skip, limit) {
  const slice = ids.slice(skip, skip + limit);
  if (!slice.length) return [];
  const objectIds = slice.map((id) => new mongoose.Types.ObjectId(id));
  const docs = await Product.find({ _id: { $in: objectIds } })
    .populate(PRODUCT_POPULATE)
    .lean();
  const byId = new Map(docs.map((doc) => [String(doc._id), doc]));
  return slice
    .map((id) => byId.get(id))
    .filter(Boolean)
    .map((doc) => productService.mapProductForCatalog(doc));
}

async function listOffers(opts = {}) {
  const { page, limit, skip } = parsePage(opts);
  const { query } = await visibleProductQuery([]);
  productService.applyActiveOfferFilter(query, true);
  const [docs, total] = await Promise.all([
    Product.find(query)
      .populate(PRODUCT_POPULATE)
      .sort({ updatedAt: -1, createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .lean(),
    Product.countDocuments(query),
  ]);
  return {
    items: docs.map((doc) => productService.mapProductForCatalog(doc)),
    pagination: { page, limit, total },
  };
}

async function listNew(opts = {}) {
  const { page, limit } = parsePage(opts);
  const pins = await loadActivePins('new');
  const pinItems = await mapPinnedProducts(pins, await productService.getVisibleShopIds());
  const exclude = pinItems.map((item) => toId(item._id || item.id));
  return mergePaged({
    pinItems,
    page,
    limit,
    countAuto: () => countNewestAuto(exclude),
    fetchAuto: (skip, take) => listNewestAuto(exclude, skip, take),
  });
}

async function listBestSellers(opts = {}) {
  const { page, limit } = parsePage(opts);
  const visibleShopIds = await productService.getVisibleShopIds();
  const pins = await loadActivePins('best_sellers');
  const pinItems = await mapPinnedProducts(pins, visibleShopIds);
  const exclude = idSet(pinItems.map((item) => toId(item._id || item.id)));
  const ranked = await rankedSoldIds(visibleShopIds, exclude);
  return mergePaged({
    pinItems,
    page,
    limit,
    countAuto: async () => ranked.length,
    fetchAuto: (skip, take) => productsByOrderedIds(ranked, skip, take),
  });
}

function collectIdsFromOrder(order, orderedProductIds, shopIds) {
  if (order.shopId) shopIds.add(String(order.shopId));
  for (const item of order.items || []) {
    if (item.productId) orderedProductIds.push(String(item.productId));
  }
  for (const portion of order.shopPortions || []) {
    if (portion.shopId) shopIds.add(String(portion.shopId));
    for (const item of portion.items || []) {
      if (item.productId) orderedProductIds.push(String(item.productId));
    }
  }
}

async function personalizedProductIds(userId, visibleShopIds, excludeSet) {
  if (!userId) return [];
  const orders = await Order.find({
    customerId: userId,
    status: ORDER_STATUS.DELIVERED,
  })
    .sort({ createdAt: -1 })
    .limit(40)
    .select('items.productId shopId shopPortions.shopId shopPortions.items.productId')
    .lean();

  const orderedProductIds = [];
  const shopIds = new Set();
  for (const order of orders) {
    collectIdsFromOrder(order, orderedProductIds, shopIds);
  }
  if (!orderedProductIds.length && !shopIds.size) return [];

  const bought = await Product.find({
    _id: {
      $in: orderedProductIds
        .filter((id) => mongoose.Types.ObjectId.isValid(id))
        .map((id) => new mongoose.Types.ObjectId(id)),
    },
  })
    .select('categoryId brandId shopId')
    .lean();

  const categoryIds = [...new Set(bought.map((p) => p.categoryId).filter(Boolean).map(String))];
  const brandIds = [...new Set(bought.map((p) => p.brandId).filter(Boolean).map(String))];
  bought.forEach((p) => {
    if (p.shopId) shopIds.add(String(p.shopId));
  });

  const or = [];
  if (shopIds.size) {
    or.push({
      shopId: { $in: [...shopIds].map((id) => new mongoose.Types.ObjectId(id)) },
    });
  }
  if (categoryIds.length) {
    or.push({
      categoryId: { $in: categoryIds.map((id) => new mongoose.Types.ObjectId(id)) },
    });
  }
  if (brandIds.length) {
    or.push({
      brandId: { $in: brandIds.map((id) => new mongoose.Types.ObjectId(id)) },
    });
  }
  if (!or.length) return [];

  const skipIds = [...excludeSet, ...orderedProductIds];
  const query = {
    isAvailable: true,
    shopId: { $in: visibleShopIds },
    $or: or,
  };
  if (skipIds.length) {
    query._id = {
      $nin: skipIds
        .filter((id) => mongoose.Types.ObjectId.isValid(id))
        .map((id) => new mongoose.Types.ObjectId(id)),
    };
  }

  const docs = await Product.find(query).select('_id').sort({ createdAt: -1 }).limit(400).lean();
  return docs.map((doc) => String(doc._id));
}

async function listForYou(opts = {}) {
  const { page, limit } = parsePage(opts);
  const visibleShopIds = await productService.getVisibleShopIds();
  const pins = await loadActivePins('for_you');
  const pinItems = await mapPinnedProducts(pins, visibleShopIds);
  const exclude = idSet(pinItems.map((item) => toId(item._id || item.id)));
  let ranked = await personalizedProductIds(opts.userId, visibleShopIds, exclude);
  if (!ranked.length) {
    return mergePaged({
      pinItems,
      page,
      limit,
      countAuto: () => countNewestAuto([...exclude]),
      fetchAuto: (skip, take) => listNewestAuto([...exclude], skip, take),
    });
  }
  return mergePaged({
    pinItems,
    page,
    limit,
    countAuto: async () => ranked.length,
    fetchAuto: (skip, take) => productsByOrderedIds(ranked, skip, take),
  });
}

async function listTopRated(opts = {}) {
  const { page, limit } = parsePage(opts);
  const pins = await loadActivePins('top_rated');
  const pinItems = await mapPinnedShops(pins);
  const exclude = idSet(pinItems.map((item) => toId(item._id)));
  const base = {
    isActive: true,
    isHidden: { $ne: true },
  };
  if (exclude.size) {
    base._id = { $nin: [...exclude].map((id) => new mongoose.Types.ObjectId(id)) };
  }

  const ratedQuery = { ...base, rating: { $gt: 0 } };
  const ratedCount = await Shop.countDocuments(ratedQuery);
  const autoQuery = ratedCount > 0 ? ratedQuery : base;

  return mergePaged({
    pinItems,
    page,
    limit,
    countAuto: () => Shop.countDocuments(autoQuery),
    fetchAuto: (skip, take) =>
      Shop.find(autoQuery)
        .sort({ rating: -1, ratingCount: -1, name: 1 })
        .skip(skip)
        .limit(take)
        .lean(),
  });
}

function assertSection(section) {
  if (!HomeSectionPin.SECTIONS.includes(section)) {
    throw badRequest('قسم غير صالح');
  }
  return section;
}

async function listPins(section) {
  assertSection(section);
  const items = await HomeSectionPin.find({ section })
    .sort({ order: 1, createdAt: 1 })
    .populate('productId', 'name price image isAvailable')
    .populate('shopId', 'name image rating isActive isHidden')
    .lean();
  return { section, itemType: SHOP_SECTIONS.has(section) ? 'shop' : 'product', items };
}

async function createPin(body = {}) {
  const section = assertSection(String(body.section || '').trim());
  const wantsShop = SHOP_SECTIONS.has(section);
  if (wantsShop) {
    const shopId = String(body.shopId || '').trim();
    if (!mongoose.Types.ObjectId.isValid(shopId)) throw badRequest('معرّف المتجر غير صالح');
    const shop = await Shop.findById(shopId).lean();
    if (!shop) throw notFound('المتجر غير موجود');
    const exists = await HomeSectionPin.findOne({ section, shopId });
    if (exists) throw conflict('هذا المتجر مضاف مسبقاً في القسم');
    const last = await HomeSectionPin.findOne({ section }).sort({ order: -1 }).select('order').lean();
    const pin = await HomeSectionPin.create({
      section,
      itemType: 'shop',
      shopId,
      order: (last?.order ?? -1) + 1,
      isActive: body.isActive !== false,
    });
    return pin.toObject();
  }

  const productId = String(body.productId || '').trim();
  if (!mongoose.Types.ObjectId.isValid(productId)) throw badRequest('معرّف المنتج غير صالح');
  const product = await Product.findById(productId).lean();
  if (!product) throw notFound('المنتج غير موجود');
  const exists = await HomeSectionPin.findOne({ section, productId });
  if (exists) throw conflict('هذا المنتج مضاف مسبقاً في القسم');
  const last = await HomeSectionPin.findOne({ section }).sort({ order: -1 }).select('order').lean();
  const pin = await HomeSectionPin.create({
    section,
    itemType: 'product',
    productId,
    order: (last?.order ?? -1) + 1,
    isActive: body.isActive !== false,
  });
  return pin.toObject();
}

async function updatePin(id, body = {}) {
  if (!mongoose.Types.ObjectId.isValid(id)) throw badRequest('معرّف غير صالح');
  const pin = await HomeSectionPin.findById(id);
  if (!pin) throw notFound('العنصر غير موجود');
  if (body.order != null && body.order !== '') pin.order = Number(body.order) || 0;
  if (body.isActive !== undefined) pin.isActive = body.isActive === true || body.isActive === 'true';
  await pin.save();
  return pin.toObject();
}

async function removePin(id) {
  if (!mongoose.Types.ObjectId.isValid(id)) throw badRequest('معرّف غير صالح');
  const pin = await HomeSectionPin.findByIdAndDelete(id);
  if (!pin) throw notFound('العنصر غير موجود');
  return { deleted: true };
}

module.exports = {
  PRODUCT_SECTIONS,
  SHOP_SECTIONS,
  listOffers,
  listNew,
  listBestSellers,
  listForYou,
  listTopRated,
  listPins,
  createPin,
  updatePin,
  removePin,
};
