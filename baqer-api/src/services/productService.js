const path = require('path');
const fs = require('fs');
const mongoose = require('mongoose');
const { Product, ProductCategory, Shop, Category, ProductSubcategory, ProductBrand } = require('../models');
const { badRequest } = require('../utils/errors');
const { notFound, forbidden } = require('../utils/errors');

/** صورة افتراضية للمنتجات التي لا تحتوي على صورة */
const DEFAULT_PRODUCT_IMAGE = '/uploads/products/photo_2026-03-18 00.25.48.jpeg';

/**
 * شرط MongoDB: المنتج لا يملك صورة حقيقية (فارغ، أو نفس الصورة الافتراضية في العرض).
 * يُستخدم لقائمة «إكمال الصور» وللفلترة في لوحة الأدمن.
 */
function getMissingImageMongoCondition() {
  const def = DEFAULT_PRODUCT_IMAGE;
  const defNoLeading = def.replace(/^\//, '');
  return {
    $or: [
      { image: null },
      { image: '' },
      { image: def },
      { image: defNoLeading },
      { image: { $regex: /^\s*$/ } },
      { images: { $exists: false } },
      { images: { $size: 0 } },
    ],
  };
}

function mapProductMissingImageRow(p) {
  const categoryDoc = p.productCategoryId;
  const productCategoryId = p.productCategoryId?._id?.toString() ?? p.productCategoryId?.toString();
  const categoryName = categoryDoc?.nameAr ?? null;
  const { productCategoryId: _pc, ...rest } = p;
  return {
    ...rest,
    _id: p._id,
    image: null,
    productCategoryId: productCategoryId || undefined,
    categoryName: categoryName || undefined,
    offerPrice: p.offerPrice != null ? p.offerPrice : undefined,
    offerEndsAt: p.offerEndsAt ? p.offerEndsAt.toISOString() : undefined,
  };
}

/**
 * منتجات محل بلا صورة حقيقية (يشمل غير المتاحة) — لصاحب المحل والأدمن.
 */
async function listMissingImagesByShop(shopId, opts = {}) {
  const pageNum = Math.max(1, Number(opts.page) || 1);
  const limitNum = Math.max(1, Math.min(100, Number(opts.limit) || 50));
  const skip = (pageNum - 1) * limitNum;
  const baseQuery = { shopId, ...getMissingImageMongoCondition() };
  const [rawItems, total] = await Promise.all([
    Product.find(baseQuery)
      .populate('productCategoryId', 'nameAr')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limitNum)
      .lean(),
    Product.countDocuments(baseQuery),
  ]);
  const items = rawItems.map((p) => mapProductMissingImageRow(p));
  return { items, pagination: { page: pageNum, limit: limitNum, total } };
}

function deleteProductImageIfLocal(imagePath) {
  if (!imagePath || typeof imagePath !== 'string') return;
  const normalized = imagePath.replace(/^\/+/, '');
  if (!normalized.startsWith('uploads/products/')) return;
  if (normalized === DEFAULT_PRODUCT_IMAGE.replace(/^\/+/, '')) return;
  const filePath = path.join(__dirname, '..', '..', normalized);
  try {
    if (fs.existsSync(filePath)) fs.unlinkSync(filePath);
  } catch (_) {}
}

function deleteProductImagesIfLocal(imagePaths) {
  if (!Array.isArray(imagePaths)) return;
  for (const p of imagePaths) deleteProductImageIfLocal(p);
}

function normalizeProductImages(images, fallbackImage) {
  const list = Array.isArray(images)
    ? images.filter((v) => typeof v === 'string' && v.trim()).map((v) => v.trim())
    : [];
  if (list.length > 0) return list;
  if (fallbackImage && typeof fallbackImage === 'string' && fallbackImage.trim()) {
    return [fallbackImage.trim()];
  }
  return [DEFAULT_PRODUCT_IMAGE];
}

/**
 * جلب منتجات محل معيّن مع pagination اختياري، مع إمكانية البحث بالاسم داخل نفس المحل.
 * @param {string} shopId - معرّف المحل
 * @param {{ page?: number, limit?: number, q?: string, productCategoryId?: string, hasOffer?: boolean, includeUnavailable?: boolean }} opts
 */
async function listByShop(shopId, opts = {}) {
  const { page, limit, q, productCategoryId, categoryId, subcategoryId, brandId, hasOffer, includeUnavailable } = opts;
  const query = { shopId };
  if (!includeUnavailable) query.isAvailable = true;

  if (q && typeof q === 'string' && q.trim()) {
    const safe = q.trim().replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    query.name = new RegExp(safe, 'i');
  }
  if (hasOffer === true) {
    query.offerPrice = { $exists: true, $ne: null, $gt: 0 };
    query.$or = [
      { offerEndsAt: { $exists: false } },
      { offerEndsAt: null },
      { offerEndsAt: { $gt: new Date() } },
    ];
  }
  await applyTaxonomyFilters(query, { productCategoryId, categoryId, subcategoryId, brandId }, shopId);

  const sort = { createdAt: -1 };

  if (page != null && limit != null) {
    const skip = (Number(page) - 1) * Number(limit);
    const limitNum = Number(limit);
    const pageNum = Number(page);
    const [rawItems, total] = await Promise.all([
      Product.find(query)
        .populate(PRODUCT_POPULATE)
        .sort(sort)
        .skip(skip)
        .limit(limitNum)
        .lean(),
      Product.countDocuments(query),
    ]);
    const items = rawItems.map((p) => mapProductWithCategory(p));
    return { items, pagination: { page: pageNum, limit: limitNum, total } };
  }
  const rawProducts = await Product.find(query)
    .populate(PRODUCT_POPULATE)
    .sort(sort)
    .lean();
  return rawProducts.map((p) => mapProductWithCategory(p));
}

async function getVisibleShopIds() {
  return Shop.find({ isActive: true, isHidden: { $ne: true } }).distinct('_id');
}

function toObjectId(id) {
  return new mongoose.Types.ObjectId(String(id).trim());
}

function isObjectId(id) {
  return id != null && mongoose.Types.ObjectId.isValid(String(id));
}

function shopScope(shopId) {
  return isObjectId(shopId) ? { shopId: toObjectId(shopId) } : {};
}

function pushAndClause(query, clause) {
  if (query.$or) {
    const existingOr = query.$or;
    delete query.$or;
    query.$and = [...(query.$and || []), { $or: existingOr }];
  }
  if (query.$and) {
    query.$and.push(clause);
    return;
  }
  query.$and = [clause];
}

function applyOrMatch(query, orClause) {
  if (!Array.isArray(orClause) || orClause.length === 0) return;
  if (orClause.length === 1) {
    const [only] = orClause;
    const clashes = Object.keys(only).some((key) => query[key] !== undefined);
    if (!clashes && !query.$or) {
      Object.assign(query, only);
      return;
    }
  }
  pushAndClause(query, { $or: orClause });
}

/**
 * قسم متجر: المنتجات المرتبطة بالقسم نفسه أو بقسم الإدارة الأب.
 * إذا كان المعرّف قسم إدارة: المنتجات ذات categoryId أو أقسام المتجر المرتبطة به.
 */
async function expandProductCategoryMatch(productCategoryId, shopId) {
  const oid = toObjectId(productCategoryId);
  const section = await ProductCategory.findOne({ _id: oid, ...shopScope(shopId) }).lean();
  const or = [{ productCategoryId: oid }];
  if (section?.parentCategoryId) {
    or.push({ categoryId: section.parentCategoryId });
    return or;
  }
  if (!section) {
    or.push({ categoryId: oid });
    const linked = await ProductCategory.find({
      parentCategoryId: oid,
      ...shopScope(shopId),
    })
      .select('_id')
      .lean();
    if (linked.length > 0) {
      or.push({ productCategoryId: { $in: linked.map((item) => item._id) } });
    }
  }
  return or;
}

/**
 * قسم إدارة: المنتجات ذات categoryId أو المرتبطة بأقسام المتجر التابعة له.
 */
async function expandAdminCategoryMatch(categoryId, shopId) {
  const oid = toObjectId(categoryId);
  const linked = await ProductCategory.find({
    parentCategoryId: oid,
    ...shopScope(shopId),
  })
    .select('_id')
    .lean();
  const or = [{ categoryId: oid }];
  if (linked.length > 0) {
    or.push({ productCategoryId: { $in: linked.map((item) => item._id) } });
  }
  return or;
}

async function applyTaxonomyFilters(query, filters = {}, shopId) {
  const { categoryId, subcategoryId, brandId, productCategoryId } = filters;
  if (isObjectId(subcategoryId)) {
    query.subcategoryId = toObjectId(subcategoryId);
  }
  if (isObjectId(brandId)) {
    query.brandId = toObjectId(brandId);
  }
  if (isObjectId(productCategoryId)) {
    applyOrMatch(query, await expandProductCategoryMatch(productCategoryId, shopId));
  }
  if (isObjectId(categoryId)) {
    applyOrMatch(query, await expandAdminCategoryMatch(categoryId, shopId));
  }
}

async function validateProductTaxonomy(body) {
  let categoryId = body.categoryId;
  const subcategoryId = body.subcategoryId;
  const brandId = body.brandId;
  let subDoc = null;
  let brandDoc = null;

  if (subcategoryId) {
    subDoc = await ProductSubcategory.findById(subcategoryId).lean();
    if (!subDoc) throw badRequest('التصنيف الفرعي غير موجود');
    if (categoryId && subDoc.categoryId.toString() !== String(categoryId)) {
      throw badRequest('التصنيف الفرعي لا يتبع التصنيف الرئيسي المحدد');
    }
    if (!categoryId) {
      categoryId = subDoc.categoryId.toString();
      body.categoryId = categoryId;
    }
  }

  if (brandId) {
    brandDoc = await ProductBrand.findById(brandId).lean();
    if (!brandDoc) throw badRequest('البراند غير موجود');
    if (categoryId && brandDoc.categoryId.toString() !== String(categoryId)) {
      throw badRequest('البراند لا يتبع التصنيف الرئيسي المحدد');
    }
    if (!categoryId) {
      categoryId = brandDoc.categoryId.toString();
      body.categoryId = categoryId;
    }
  }

  if (subDoc && brandDoc && subDoc.categoryId.toString() !== brandDoc.categoryId.toString()) {
    throw badRequest('التصنيف الفرعي والبراند يجب أن يتبعا نفس التصنيف الرئيسي');
  }

  if ((subcategoryId || brandId) && !categoryId) {
    throw badRequest('يجب اختيار التصنيف الرئيسي عند ربط المنتج بتصنيف فرعي أو براند');
  }

  if (categoryId) {
    const cat = await Category.findById(categoryId).lean();
    if (!cat) throw badRequest('التصنيف الرئيسي غير موجود');
  }
}

async function resolveProductCategoryForTaxonomy(shopId, body) {
  if (body.productCategoryId) return body.productCategoryId;
  if (!body.subcategoryId) return undefined;
  const sectionQuery = { shopId, subcategoryId: body.subcategoryId };
  if (body.categoryId) sectionQuery.parentCategoryId = body.categoryId;
  const section = await ProductCategory.findOne(sectionQuery).lean();
  return section?._id;
}

function mapProductWithCategory(p) {
  const sectionDoc = p.productCategoryId;
  const mainCategoryDoc = p.categoryId;
  const subcategoryDoc = p.subcategoryId;
  const brandDoc = p.brandId;
  const productCategoryId = sectionDoc?._id?.toString() ?? p.productCategoryId?.toString?.() ?? (typeof p.productCategoryId === 'string' ? p.productCategoryId : undefined);
  const categoryId = mainCategoryDoc?._id?.toString() ?? p.categoryId?.toString?.() ?? (typeof p.categoryId === 'string' ? p.categoryId : undefined);
  const subcategoryId = subcategoryDoc?._id?.toString() ?? p.subcategoryId?.toString?.() ?? (typeof p.subcategoryId === 'string' ? p.subcategoryId : undefined);
  const brandId = brandDoc?._id?.toString() ?? p.brandId?.toString?.() ?? (typeof p.brandId === 'string' ? p.brandId : undefined);
  const sectionName = sectionDoc?.nameAr ?? null;
  const mainCategoryName = mainCategoryDoc?.nameAr ?? null;
  const subcategoryName = subcategoryDoc?.nameAr ?? null;
  const brandName = brandDoc?.nameAr ?? null;
  const shopRef = p.shopId;
  let shopIdStr;
  let shopName;
  let shopIsOpen = true;
  if (shopRef != null) {
    if (typeof shopRef === 'object' && shopRef._id != null) {
      shopIdStr = shopRef._id.toString();
      shopName = shopRef.name ?? null;
      if (shopRef.isOpen === false) shopIsOpen = false;
    } else {
      shopIdStr = shopRef.toString();
    }
  }
  const { productCategoryId: _pc, shopId: _sid, categoryId: _cid, subcategoryId: _sid2, brandId: _bid, ...rest } = p;
  const images = normalizeProductImages(p.images, p.image);
  const image = images[0];
  const stock = p.stock != null ? Number(p.stock) : 0;
  return {
    ...rest,
    _id: p._id,
    id: p._id?.toString?.() ?? p.id,
    image,
    images,
    stock,
    quantity: stock,
    categoryId: categoryId || undefined,
    subcategoryId: subcategoryId || undefined,
    brandId: brandId || undefined,
    productCategoryId: productCategoryId || undefined,
    mainCategoryName: mainCategoryName || undefined,
    subcategoryName: subcategoryName || undefined,
    brandName: brandName || undefined,
    categoryName: sectionName || subcategoryName || brandName || mainCategoryName || undefined,
    shopId: shopIdStr,
    shopName: shopName ?? p.shopName ?? undefined,
    shopIsOpen,
    offerPrice: p.offerPrice != null ? p.offerPrice : undefined,
    offerEndsAt: p.offerEndsAt ? new Date(p.offerEndsAt).toISOString() : undefined,
  };
}

function mapProductForCatalog(p) {
  return mapProductWithCategory(p);
}

const PRODUCT_POPULATE = [
  { path: 'shopId', select: 'name isOpen' },
  { path: 'productCategoryId', select: 'nameAr' },
  { path: 'categoryId', select: 'nameAr icon' },
  { path: 'subcategoryId', select: 'nameAr' },
  { path: 'brandId', select: 'nameAr' },
];

/**
 * جلب منتجات من كل المحلات مع pagination (دون الاعتماد على shopId).
 * الترتيب عشوائي. عند تمرير excludeIds تُستبعد المنتجات المحمّلة مسبقاً (لتحميل المزيد بدون تكرار).
 */
async function listAll(filters = {}) {
  const {
    page = 1,
    limit = 12,
    excludeIds: rawExcludeIds,
    hasOffer,
    shopId: rawShopId,
    productCategoryId: rawProductCategoryId,
    categoryId: rawCategoryId,
    subcategoryId: rawSubcategoryId,
    brandId: rawBrandId,
  } = filters;
  const limitNum = Number(limit);
  const pageNum = Number(page);

  const visibleShopIds = await getVisibleShopIds();
  const query = { isAvailable: true, shopId: { $in: visibleShopIds } };
  if (hasOffer === true) {
    query.offerPrice = { $gt: 0 };
    query.$or = [
      { offerEndsAt: { $exists: false } },
      { offerEndsAt: null },
      { offerEndsAt: { $gt: new Date() } },
    ];
  }
  const allowedShopIds = visibleShopIds;

  if (rawShopId && mongoose.Types.ObjectId.isValid(String(rawShopId))) {
    const sid = String(rawShopId).trim();
    const allowedSet = new Set(allowedShopIds.map((id) => id.toString()));
    if (allowedSet.has(sid)) {
      query.shopId = new mongoose.Types.ObjectId(sid);
    } else {
      query.shopId = { $in: [] };
    }
  }

  await applyTaxonomyFilters(query, {
    productCategoryId: rawProductCategoryId,
    categoryId: rawCategoryId,
    subcategoryId: rawSubcategoryId,
    brandId: rawBrandId,
  }, rawShopId);

  const excludeIds = Array.isArray(rawExcludeIds)
    ? rawExcludeIds
        .filter((id) => id != null && mongoose.Types.ObjectId.isValid(String(id)))
        .map((id) => new mongoose.Types.ObjectId(String(id)))
    : [];
  if (excludeIds.length > 0) {
    query._id = { $nin: excludeIds };
  }

  const sampleSize = limitNum;
  const pipeline = [
    { $match: query },
    { $sample: { size: sampleSize } },
    {
      $lookup: {
        from: 'shops',
        localField: 'shopId',
        foreignField: '_id',
        as: 'shopDoc',
      },
    },
    {
      $lookup: {
        from: 'productcategories',
        localField: 'productCategoryId',
        foreignField: '_id',
        as: 'categoryDoc',
      },
    },
    {
      $addFields: {
        shopName: { $arrayElemAt: ['$shopDoc.name', 0] },
        categoryName: { $arrayElemAt: ['$categoryDoc.nameAr', 0] },
        shopIsOpen: {
          $ifNull: [{ $arrayElemAt: ['$shopDoc.isOpen', 0] }, true],
        },
      },
    },
    {
      $project: {
        shopDoc: 0,
        categoryDoc: 0,
      },
    },
  ];

  const countQuery = { ...query };
  delete countQuery._id;
  const [rawItems, total] = await Promise.all([
    Product.aggregate(pipeline),
    Product.countDocuments(countQuery),
  ]);

  const items = rawItems.map((p) => mapProductForCatalog({
    ...p,
    shopId: { _id: p.shopId, name: p.shopName, isOpen: p.shopIsOpen },
    productCategoryId: p.productCategoryId ? { _id: p.productCategoryId, nameAr: p.categoryName } : undefined,
  }));

  return { items, pagination: { page: pageNum, limit: limitNum, total } };
}

/**
 * منتجات الكتالوج العام — مرتبة حسب الأحدث مع فلترة بالقسم والفرعي.
 */
async function listCatalogProducts(filters = {}) {
  const {
    page = 1,
    limit = 20,
    categoryId,
    subcategoryId,
    brandId,
    shopId,
    q,
  } = filters;
  const pageNum = Math.max(1, Number(page) || 1);
  const limitNum = Math.min(100, Math.max(1, Number(limit) || 20));
  const skip = (pageNum - 1) * limitNum;

  const visibleShopIds = await getVisibleShopIds();
  const query = { isAvailable: true, shopId: { $in: visibleShopIds } };
  await applyTaxonomyFilters(query, { categoryId, subcategoryId, brandId }, shopId);

  if (shopId && mongoose.Types.ObjectId.isValid(String(shopId))) {
    const sid = String(shopId).trim();
    const allowed = new Set(visibleShopIds.map((id) => id.toString()));
    query.shopId = allowed.has(sid) ? new mongoose.Types.ObjectId(sid) : { $in: [] };
  }

  if (q && typeof q === 'string' && q.trim()) {
    const safe = q.trim().replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    query.name = new RegExp(safe, 'i');
  }

  const [rawItems, total] = await Promise.all([
    Product.find(query)
      .populate(PRODUCT_POPULATE)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limitNum)
      .lean(),
    Product.countDocuments(query),
  ]);

  return {
    items: rawItems.map((p) => mapProductForCatalog(p)),
    pagination: { page: pageNum, limit: limitNum, total },
  };
}

async function create(shopId, userId, body, userRoles = []) {
  const shop = await Shop.findById(shopId);
  if (!shop) throw notFound('Shop not found');
  const isAdmin = Array.isArray(userRoles) && userRoles.includes('admin');
  const isOwner = shop.ownerId.toString() === userId.toString();
  if (!isAdmin && !isOwner) throw forbidden('Not the shop owner');
  await validateProductTaxonomy(body);
  if (body.productCategoryId) {
    const cat = await ProductCategory.findOne({ _id: body.productCategoryId, shopId });
    if (!cat) throw badRequest('تصنيف المنتج غير موجود أو لا يتبع هذا المحل');
    if (!body.categoryId && cat.parentCategoryId) {
      body.categoryId = cat.parentCategoryId.toString();
    }
  }
  const resolvedSectionId = await resolveProductCategoryForTaxonomy(shopId, body);
  const productCategoryId = body.productCategoryId || resolvedSectionId || undefined;
  const product = await Product.create({
    shopId,
    name: body.name,
    description: body.description,
    price: body.price,
    image: body.image,
    images: normalizeProductImages(body.images, body.image),
    isAvailable: body.isAvailable !== false,
    categoryId: body.categoryId || undefined,
    subcategoryId: body.subcategoryId || undefined,
    brandId: body.brandId || undefined,
    productCategoryId,
    offerPrice: body.offerPrice != null ? Number(body.offerPrice) : undefined,
    offerEndsAt: body.offerEndsAt ? new Date(body.offerEndsAt) : undefined,
    stock: body.stock != null ? Number(body.stock) : 0,
    productionDate: body.productionDate ? new Date(body.productionDate) : undefined,
    expiryDate: body.expiryDate ? new Date(body.expiryDate) : undefined,
  });
  const populated = await Product.findById(product._id)
    .populate(PRODUCT_POPULATE)
    .lean();
  return mapProductWithCategory(populated);
}

async function getById(productId, shopId) {
  const product = await Product.findOne({ _id: productId, shopId })
    .populate(PRODUCT_POPULATE)
    .lean();
  if (!product) throw notFound('Product not found');
  return mapProductWithCategory(product);
}

/**
 * ترشيح منتجات مشابهة لمنتج معيّن:
 * 1) نفس المحل + نفس الفئة (إذا المنتج لديه فئة)
 * 2) إكمال الباقي من نفس المحل (بدون المنتج الحالي)
 * إذا المحل لا يستخدم فئات فعلياً تكون النتيجة تلقائياً من نفس المحل فقط.
 * @param {string} shopId
 * @param {string} productId
 * @param {{ limit?: number }} opts
 */
async function getRecommendations(shopId, productId, opts = {}) {
  const limit = Math.max(1, Math.min(Number(opts.limit) || 8, 30));
  const base = await Product.findOne({ _id: productId, shopId }).select('_id productCategoryId').lean();
  if (!base) throw notFound('Product not found');

  const exclusion = { $ne: base._id };
  const baseQuery = { shopId, isAvailable: true, _id: exclusion };
  const hasCategory = !!base.productCategoryId;
  const categoryId = hasCategory ? base.productCategoryId : null;

  let recommended = [];

  if (hasCategory) {
    const sameCategory = await Product.find({ ...baseQuery, productCategoryId: categoryId })
      .populate('productCategoryId', 'nameAr')
      .populate('shopId', 'isOpen')
      .sort({ createdAt: -1 })
      .limit(limit)
      .lean();
    recommended = sameCategory.map((p) => mapProductWithCategory(p));
  }

  if (recommended.length < limit) {
    const need = limit - recommended.length;
    const excludedIds = [base._id, ...recommended.map((p) => p._id)];
    const filler = await Product.find({
      shopId,
      isAvailable: true,
      _id: { $nin: excludedIds },
    })
      .populate('productCategoryId', 'nameAr')
      .populate('shopId', 'isOpen')
      .sort({ createdAt: -1 })
      .limit(need)
      .lean();
    recommended = [...recommended, ...filler.map((p) => mapProductWithCategory(p))];
  }

  return recommended;
}

async function updateById(productId, shopId, userId, body, userRoles = []) {
  const shop = await Shop.findById(shopId);
  if (!shop) throw notFound('Shop not found');
  const isAdmin = Array.isArray(userRoles) && userRoles.includes('admin');
  const isOwner = shop.ownerId.toString() === userId.toString();
  if (!isAdmin && !isOwner) throw forbidden('Not the shop owner');
  const existing = await Product.findOne({ _id: productId, shopId }).lean();
  if (!existing) throw notFound('Product not found');
  if (body.productCategoryId !== undefined && body.productCategoryId) {
    const cat = await ProductCategory.findOne({ _id: body.productCategoryId, shopId });
    if (!cat) throw badRequest('تصنيف المنتج غير موجود أو لا يتبع هذا المحل');
    if (!body.categoryId && cat.parentCategoryId) {
      body.categoryId = cat.parentCategoryId.toString();
    }
  }
  const taxonomyBody = {
    categoryId: body.categoryId !== undefined ? body.categoryId : existing.categoryId,
    subcategoryId: body.subcategoryId !== undefined ? body.subcategoryId : existing.subcategoryId,
    brandId: body.brandId !== undefined ? body.brandId : existing.brandId,
    productCategoryId: body.productCategoryId !== undefined ? body.productCategoryId : existing.productCategoryId,
  };
  if (body.categoryId !== undefined || body.subcategoryId !== undefined || body.brandId !== undefined) {
    await validateProductTaxonomy(taxonomyBody);
    if (body.categoryId === undefined && taxonomyBody.categoryId) body.categoryId = taxonomyBody.categoryId;
    if (body.subcategoryId === undefined && taxonomyBody.subcategoryId === null) body.subcategoryId = null;
    if (body.brandId === undefined && taxonomyBody.brandId === null) body.brandId = null;
  }
  if (!body.productCategoryId && body.subcategoryId) {
    const resolved = await resolveProductCategoryForTaxonomy(shopId, {
      categoryId: body.categoryId ?? existing.categoryId,
      subcategoryId: body.subcategoryId,
    });
    if (resolved) body.productCategoryId = resolved.toString();
  }
  const updateBody = { ...body };
  if (updateBody.quantity !== undefined && updateBody.stock === undefined) {
    updateBody.stock = updateBody.quantity;
  }
  delete updateBody.quantity;
  if (updateBody.images !== undefined || updateBody.image !== undefined) {
    const normalizedImages = normalizeProductImages(updateBody.images, updateBody.image);
    updateBody.images = normalizedImages;
    updateBody.image = normalizedImages[0];
  }
  const product = await Product.findOneAndUpdate(
    { _id: productId, shopId },
    { $set: updateBody },
    { new: true, runValidators: true }
  );
  if (updateBody.images !== undefined || updateBody.image !== undefined) {
    const oldImages = normalizeProductImages(existing.images, existing.image);
    const newImages = normalizeProductImages(updateBody.images, updateBody.image);
    const newSet = new Set(newImages);
    for (const oldPath of oldImages) {
      if (!newSet.has(oldPath)) deleteProductImageIfLocal(oldPath);
    }
  }
  const populated = await Product.findById(product._id)
    .populate(PRODUCT_POPULATE)
    .lean();
  return mapProductWithCategory(populated);
}

async function remove(productId, shopId, userId, userRoles = []) {
  const shop = await Shop.findById(shopId);
  const isAdmin = Array.isArray(userRoles) && userRoles.includes('admin');
  if (shop) {
    const isOwner = shop.ownerId.toString() === userId.toString();
    if (!isAdmin && !isOwner) throw forbidden('Not the shop owner');
  } else if (!isAdmin) {
    throw notFound('Shop not found');
  }
  // إذا كان المحل محذوفاً والأدمن يحذف: السماح بحذف المنتج (orphan cleanup)
  const product = await Product.findOneAndDelete({ _id: productId, shopId });
  if (!product) throw notFound('Product not found');
  deleteProductImagesIfLocal(normalizeProductImages(product.images, product.image));
  return { deleted: true };
}

/**
 * بحث عن منتجات بالاسم عبر كل المحلات مع pagination.
 * لا يعتمد على موقع المستخدم — يبحث في كل المحلات المرئية.
 * @param {string} q - نص البحث (يفرغ أو غير موجود = يرجع قائمة فارغة).
 * @param {{}} locationFilters - غير مستخدم (للتوافق فقط)
 * @param {{ page?: number, limit?: number }} pagination - page و limit (افتراضي 1، 12)
 */
async function search(q, locationFilters = {}, pagination = {}) {
  const { page = 1, limit = 12, categoryId, subcategoryId, brandId } = pagination;
  const searchQuery = (q && typeof q === 'string' ? q.trim() : '') || '';
  if (!searchQuery) {
    console.log('[productService.search] نص البحث فارغ بعد trim — إرجاع صفر نتائج', {
      rawType: q == null ? 'null/undefined' : typeof q,
    });
    return { items: [], pagination: { page: 1, limit: Number(limit), total: 0 } };
  }
  const nfc = searchQuery.normalize('NFC');
  const nfd = searchQuery.normalize('NFD');
  const escapeForRegex = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const patternNfc = escapeForRegex(nfc);
  const patternNfd = nfd === nfc ? patternNfc : escapeForRegex(nfd);
  const regexOpt = { $regex: patternNfc, $options: 'i' };
  const regexOptNfd = patternNfd === patternNfc ? regexOpt : { $regex: patternNfd, $options: 'i' };
  const visibleShopIds = await getVisibleShopIds();
  const baseMatch = { isAvailable: true, shopId: { $in: visibleShopIds } };
  await applyTaxonomyFilters(baseMatch, {
    categoryId: categoryId || locationFilters.categoryId,
    subcategoryId: subcategoryId || locationFilters.subcategoryId,
    brandId: brandId || locationFilters.brandId,
  });
  const query = {
    $and: [
      baseMatch,
      {
        $or: [
          { name: regexOpt },
          { name: regexOptNfd },
          { description: regexOpt },
          { description: regexOptNfd },
        ],
      },
    ],
  };
  void locationFilters;
  const skip = (Number(page) - 1) * Number(limit);
  const limitNum = Number(limit);
  const pageNum = Number(page);
  const [rawItems, total] = await Promise.all([
    Product.find(query)
      .populate(PRODUCT_POPULATE)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limitNum)
      .lean(),
    Product.countDocuments(query),
  ]);
  return {
    items: rawItems.map((p) => mapProductForCatalog(p)),
    pagination: { page: pageNum, limit: limitNum, total },
  };
}

/**
 * جلب منتجات عشوائية من عدة محلات (تنويع حقيقي بين المحلات).
 * - يختار محلات عشوائياً أولاً
 * - ثم يسحب عدداً عشوائياً من المنتجات لكل محل
 * @param {{ shopCount?: number, perShop?: number, hasOffer?: boolean, productCategoryId?: string }} filters
 */
async function listRandomFromMultipleShops(filters = {}) {
  const {
    shopCount = 6,
    perShop = 2,
    hasOffer,
    productCategoryId: rawProductCategoryId,
    categoryId: rawCategoryId,
    subcategoryId: rawSubcategoryId,
  } = filters;

  const shopCountNum = Math.max(1, Math.min(Number(shopCount) || 6, 20));
  const perShopNum = Math.max(1, Math.min(Number(perShop) || 2, 10));

  const visibleShopIds = await getVisibleShopIds();
  const allowedShopIds = visibleShopIds;

  // خلط بسيط للمحلات لاختيار عشوائي بدون تكرار.
  const shuffledShopIds = [...allowedShopIds].sort(() => Math.random() - 0.5);
  const items = [];
  const usedShopIds = [];

  for (const shopId of shuffledShopIds) {
    if (usedShopIds.length >= shopCountNum) break;
    const query = { isAvailable: true, shopId };
    if (hasOffer === true) {
      query.offerPrice = { $gt: 0 };
      query.$or = [
        { offerEndsAt: { $exists: false } },
        { offerEndsAt: null },
        { offerEndsAt: { $gt: new Date() } },
      ];
    }
    await applyTaxonomyFilters(query, {
      productCategoryId: rawProductCategoryId,
      categoryId: rawCategoryId,
      subcategoryId: rawSubcategoryId,
    }, shopId);

    const rawShopProducts = await Product.find(query)
      .populate(PRODUCT_POPULATE)
      .sort({ createdAt: -1 })
      .limit(perShopNum * 4)
      .lean();

    if (rawShopProducts.length === 0) continue;

    const randomizedProducts = [...rawShopProducts].sort(() => Math.random() - 0.5).slice(0, perShopNum);
    for (const p of randomizedProducts) {
      items.push(mapProductForCatalog(p));
    }
    usedShopIds.push(shopId.toString());
  }

  return {
    items,
    meta: {
      shopsRequested: shopCountNum,
      shopsReturned: usedShopIds.length,
      perShop: perShopNum,
    },
  };
}

/**
 * إضافة سريعة لمنتجات متعددة لمحل معيّن.
 * إذا حدث خطأ في أي منتج لا يُضاف أي منتج (يتم حذف ما تم إنشاؤه في نفس الطلب).
 * الأدمن يمكنه الإضافة لأي محل؛ صاحب المحل لمحله فقط.
 * @param {string} shopId - معرّف المحل
 * @param {object} userId - معرّف المستخدم
 * @param {string[]} userRoles - أدوار المستخدم (مثل ['admin'] أو ['shop'])
 * @param {{ name: string, price: number }[]} items - أزواج اسم وسعر صالحة (بعد التحليل)
 * @returns {{ created: object[], failed: { lineIndex?: number, name?: string, reason: string }[] }}
 */
async function bulkCreate(shopId, userId, userRoles, items) {
  const shop = await Shop.findById(shopId);
  if (!shop) throw notFound('المحل غير موجود');
  const isAdmin = (userRoles || []).includes('admin');
  if (!isAdmin && shop.ownerId.toString() !== userId.toString()) {
    throw forbidden('ليس لديك صلاحية إضافة منتجات لهذا المحل');
  }
  const created = [];
  const createdIds = [];
  const failed = [];
  for (let i = 0; i < items.length; i++) {
    const item = items[i];
    try {
      const product = await Product.create({
        shopId,
        name: item.name,
        description: '',
        price: item.price,
        isAvailable: true,
        productCategoryId: item.productCategoryId || undefined,
      });
      created.push({
        _id: product._id,
        name: product.name,
        price: product.price,
      });
      createdIds.push(product._id);
    } catch (err) {
      const reason = err.message || 'خطأ غير معروف عند إنشاء المنتج';
      failed.push({
        lineIndex: i + 1,
        name: item.name,
        reason,
      });
    }
  }
  // إذا وُجد أي فشل نحذف كل المنتجات التي أُنشئت في هذا الطلب
  if (failed.length > 0 && createdIds.length > 0) {
    await Product.deleteMany({ _id: { $in: createdIds } });
    return { created: [], failed };
  }
  return { created, failed };
}

/**
 * إضافة سريعة لمنتجات متعددة مع الفئات لمحل معيّن.
 * العناصر تحتوي name, price, productCategoryId.
 * إذا حدث خطأ في أي منتج لا يُضاف أي منتج.
 * @param {string} shopId
 * @param {object} userId
 * @param {string[]} userRoles
 * @param {{ name: string, price: number, productCategoryId: string }[]} items
 * @returns {{ created: object[], failed: { lineIndex?: number, name?: string, reason: string }[] }}
 */
async function bulkCreateWithCategories(shopId, userId, userRoles, items) {
  const shop = await Shop.findById(shopId);
  if (!shop) throw notFound('المحل غير موجود');
  const isAdmin = (userRoles || []).includes('admin');
  if (!isAdmin && shop.ownerId.toString() !== userId.toString()) {
    throw forbidden('ليس لديك صلاحية إضافة منتجات لهذا المحل');
  }
  const created = [];
  const createdIds = [];
  const failed = [];
  for (let i = 0; i < items.length; i++) {
    const item = items[i];
    try {
      const product = await Product.create({
        shopId,
        name: item.name,
        description: '',
        price: item.price,
        isAvailable: true,
        productCategoryId: item.productCategoryId || undefined,
      });
      created.push({
        _id: product._id,
        name: product.name,
        price: product.price,
      });
      createdIds.push(product._id);
    } catch (err) {
      const reason = err.message || 'خطأ غير معروف عند إنشاء المنتج';
      failed.push({
        lineIndex: i + 1,
        name: item.name,
        reason,
      });
    }
  }
  if (failed.length > 0 && createdIds.length > 0) {
    await Product.deleteMany({ _id: { $in: createdIds } });
    return { created: [], failed };
  }
  return { created, failed };
}

/**
 * نسخ منتجات محددة من محل مصدر إلى محل هدف.
 * الأدمن فقط. يتم نسخ الفئات إن لم تكن موجودة في المحل الهدف.
 * @param {string} targetShopId - معرّف المحل الهدف
 * @param {string} sourceShopId - معرّف المحل المصدر
 * @param {string[]} productIds - معرّفات المنتجات المطلوب نسخها
 * @param {string[]} userRoles - أدوار المستخدم
 * @returns {{ copied: number, total: number }}
 */
async function copyProductsFromShop(targetShopId, sourceShopId, productIds, userRoles = []) {
  const isAdmin = (userRoles || []).includes('admin');
  if (!isAdmin) throw forbidden('ليس لديك صلاحية نسخ المنتجات');

  if (targetShopId === sourceShopId) {
    throw badRequest('لا يمكن نسخ المنتجات من نفس المحل');
  }

  const [targetShop, sourceShop] = await Promise.all([
    Shop.findById(targetShopId),
    Shop.findById(sourceShopId),
  ]);
  if (!targetShop) throw notFound('المحل الهدف غير موجود');
  if (!sourceShop) throw notFound('المحل المصدر غير موجود');

  const validIds = productIds.filter((id) => id && typeof id === 'string' && id.trim());
  if (validIds.length === 0) {
    throw badRequest('يجب تحديد منتج واحد على الأقل للنسخ');
  }

  const sourceProducts = await Product.find({
    _id: { $in: validIds },
    shopId: sourceShopId,
  })
    .populate('productCategoryId', 'nameAr')
    .sort({ createdAt: 1 })
    .lean();

  const total = sourceProducts.length;
  if (total === 0) {
    return { copied: 0, total: 0 };
  }

  const targetCategories = await ProductCategory.find({ shopId: targetShopId }).lean();
  const categoryByName = {};
  for (const c of targetCategories) {
    const name = (c.nameAr || '').trim();
    if (name) categoryByName[name] = c._id;
  }

  let copied = 0;
  for (const p of sourceProducts) {
    let targetCategoryId = null;
    const categoryDoc = p.productCategoryId;
    const categoryName = categoryDoc?.nameAr?.trim?.() || null;
    if (categoryName) {
      if (!categoryByName[categoryName]) {
        const newCat = await ProductCategory.create({
          shopId: targetShopId,
          nameAr: categoryName,
          order: 0,
          isActive: true,
        });
        categoryByName[categoryName] = newCat._id;
      }
      targetCategoryId = categoryByName[categoryName];
    }

    await Product.create({
      shopId: targetShopId,
      name: p.name,
      description: p.description || '',
      price: p.price,
      image: p.image || undefined,
      images: normalizeProductImages(p.images, p.image),
      isAvailable: p.isAvailable !== false,
      categoryId: p.categoryId || undefined,
      subcategoryId: p.subcategoryId || undefined,
      brandId: p.brandId || undefined,
      productCategoryId: targetCategoryId || undefined,
      offerPrice: p.offerPrice != null ? Number(p.offerPrice) : undefined,
      offerEndsAt: p.offerEndsAt ? new Date(p.offerEndsAt) : undefined,
      stock: p.stock != null ? Number(p.stock) : 0,
      productionDate: p.productionDate ? new Date(p.productionDate) : undefined,
      expiryDate: p.expiryDate ? new Date(p.expiryDate) : undefined,
    });
    copied++;
  }

  return { copied, total };
}

module.exports = {
  listByShop,
  listAll,
  listCatalogProducts,
  create,
  getById,
  getRecommendations,
  updateById,
  remove,
  search,
  bulkCreate,
  bulkCreateWithCategories,
  copyProductsFromShop,
  deleteProductImageIfLocal,
  getMissingImageMongoCondition,
  listMissingImagesByShop,
  listRandomFromMultipleShops,
  mapProductForCatalog,
  expandAdminCategoryMatch,
};
