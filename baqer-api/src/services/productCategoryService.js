const mongoose = require('mongoose');
const ProductCategory = require('../models/ProductCategory');
const Product = require('../models/Product');
const Shop = require('../models/Shop');
const Category = require('../models/Category');
const ProductSubcategory = require('../models/ProductSubcategory');
const { notFound, forbidden } = require('../utils/errors');

async function attachProductCounts(shopId, mappedItems) {
  if (!mappedItems.length || !mongoose.Types.ObjectId.isValid(String(shopId))) {
    return mappedItems.map((s) => ({ ...s, productCount: 0, productsCount: 0 }));
  }

  const sectionIds = mappedItems
    .map((s) => s.id)
    .filter((id) => mongoose.Types.ObjectId.isValid(id))
    .map((id) => new mongoose.Types.ObjectId(id));
  const parentIds = mappedItems
    .map((s) => s.parentCategoryId)
    .filter((id) => id && mongoose.Types.ObjectId.isValid(id))
    .map((id) => new mongoose.Types.ObjectId(id));

  const shopOid = new mongoose.Types.ObjectId(String(shopId));
  const orFilters = [];
  if (sectionIds.length > 0) orFilters.push({ productCategoryId: { $in: sectionIds } });
  if (parentIds.length > 0) orFilters.push({ categoryId: { $in: parentIds } });

  const rows =
    orFilters.length > 0
      ? await Product.aggregate([
          { $match: { shopId: shopOid, $or: orFilters } },
          {
            $group: {
              _id: {
                productCategoryId: '$productCategoryId',
                categoryId: '$categoryId',
              },
              count: { $sum: 1 },
            },
          },
        ])
      : [];

  const bySectionId = {};
  const byParentId = {};
  for (const row of rows) {
    const sectionId = row._id?.productCategoryId?.toString();
    const parentId = row._id?.categoryId?.toString();
    if (sectionId) bySectionId[sectionId] = (bySectionId[sectionId] || 0) + row.count;
    if (parentId) byParentId[parentId] = (byParentId[parentId] || 0) + row.count;
  }

  return mappedItems.map((s) => {
    const count = bySectionId[s.id] || (s.parentCategoryId ? byParentId[s.parentCategoryId] : 0) || 0;
    return { ...s, productCount: count, productsCount: count };
  });
}

function mapProductCategoryRow(c, parentById = {}) {
  const parentId = c.parentCategoryId?.toString() || null;
  const parent = parentId ? parentById[parentId] : null;
  return {
    id: c._id?.toString() || c.id,
    shopId: c.shopId?.toString(),
    parentCategoryId: parentId,
    subcategoryId: c.subcategoryId?.toString() || null,
    nameAr: c.nameAr,
    order: c.order ?? 0,
    isActive: c.isActive !== false,
    image: c.image || parent?.icon || null,
    source: parentId ? 'admin' : 'shop',
    parentNameAr: parent?.nameAr || null,
  };
}

/**
 * List product categories for a shop. For public/admin: active only when activeOnly is true.
 * @param {string} shopId
 * @param {{ activeOnly?: boolean }} opts - activeOnly default true for public
 */
async function listByShop(shopId, opts = {}) {
  const activeOnly = opts.activeOnly !== false;
  const grouped = opts.grouped === true;
  const includeProducts = opts.includeProducts === true;
  const includeUnavailable = opts.includeUnavailable === true;
  const categoryIdFilter = opts.categoryId;
  const query = { shopId };
  if (activeOnly) query.isActive = true;
  if (categoryIdFilter && mongoose.Types.ObjectId.isValid(String(categoryIdFilter))) {
    query.parentCategoryId = new mongoose.Types.ObjectId(String(categoryIdFilter));
  }

  const items = await ProductCategory.find(query)
    .sort({ order: 1, nameAr: 1 })
    .lean();

  const parentIds = [
    ...new Set(
      items
        .map((c) => c.parentCategoryId?.toString())
        .filter((id) => id && mongoose.Types.ObjectId.isValid(id))
    ),
  ];
  const parentCategories =
    parentIds.length > 0
      ? await Category.find({ _id: { $in: parentIds } }).lean()
      : [];
  const parentById = Object.fromEntries(
    parentCategories.map((cat) => [cat._id.toString(), cat])
  );

  const mappedItems = await attachProductCounts(
    shopId,
    items.map((c) => mapProductCategoryRow(c, parentById))
  );

  if (!grouped) return mappedItems;

  const categoryQuery = {};
  if (activeOnly) categoryQuery.isActive = true;
  if (categoryIdFilter && mongoose.Types.ObjectId.isValid(String(categoryIdFilter))) {
    categoryQuery._id = new mongoose.Types.ObjectId(String(categoryIdFilter));
  }
  const categories = await Category.find(categoryQuery).sort({ order: 1, nameAr: 1 }).lean();
  const sectionIds = mappedItems.map((s) => s.id);
  const productsQuery = { shopId };
  if (!includeUnavailable) productsQuery.isAvailable = true;
  if (sectionIds.length > 0) {
    productsQuery.productCategoryId = {
      $in: sectionIds.map((id) => new mongoose.Types.ObjectId(id)),
    };
  } else {
    productsQuery.productCategoryId = { $in: [] };
  }
  const products = includeProducts
    ? await Product.find(productsQuery).sort({ createdAt: -1 }).lean()
    : [];
  const productsBySectionId = {};
  for (const p of products) {
    const sid = p.productCategoryId?.toString();
    if (!sid) continue;
    if (!productsBySectionId[sid]) productsBySectionId[sid] = [];
    productsBySectionId[sid].push({
      id: p._id.toString(),
      name: p.name,
      description: p.description || '',
      price: p.price,
      image: p.image || null,
      images: Array.isArray(p.images) ? p.images : [],
      isAvailable: p.isAvailable !== false,
      offerPrice: p.offerPrice ?? null,
      offerEndsAt: p.offerEndsAt || null,
    });
  }

  const sectionsByCategoryId = {};
  for (const section of mappedItems) {
    const key = section.parentCategoryId || '__unassigned__';
    if (!sectionsByCategoryId[key]) sectionsByCategoryId[key] = [];
    sectionsByCategoryId[key].push({
      ...section,
      products: includeProducts ? (productsBySectionId[section.id] || []) : undefined,
      productsCount: includeProducts ? (productsBySectionId[section.id]?.length || 0) : undefined,
    });
  }

  const groupedCategories = categories.map((cat) => {
    const key = cat._id.toString();
    const sections = sectionsByCategoryId[key] || [];
    const allProducts = includeProducts ? sections.flatMap((s) => s.products || []) : undefined;
    return {
      id: cat._id.toString(),
      nameAr: cat.nameAr,
      icon: cat.icon || '',
      order: cat.order ?? 0,
      isActive: cat.isActive !== false,
      sections,
      allProducts,
      productsCount: includeProducts ? allProducts.length : undefined,
    };
  });

  const unassignedSections = sectionsByCategoryId.__unassigned__ || [];
  if (unassignedSections.length > 0) {
    const unassignedProducts = includeProducts ? unassignedSections.flatMap((s) => s.products || []) : undefined;
    groupedCategories.push({
      id: null,
      nameAr: 'بدون فئة رئيسية',
      icon: '',
      order: Number.MAX_SAFE_INTEGER,
      isActive: true,
      sections: unassignedSections,
      allProducts: unassignedProducts,
      productsCount: includeProducts ? unassignedProducts.length : undefined,
    });
  }

  return groupedCategories;
}

async function getById(categoryId, shopId) {
  const category = await ProductCategory.findOne({ _id: categoryId, shopId });
  if (!category) throw notFound('Product category not found');
  return category;
}

async function validateSectionTaxonomy(body) {
  if (body.subcategoryId) {
    const sub = await ProductSubcategory.findById(body.subcategoryId).lean();
    if (!sub) {
      const { badRequest } = require('../utils/errors');
      throw badRequest('التصنيف الفرعي غير موجود');
    }
    if (body.parentCategoryId && sub.categoryId.toString() !== String(body.parentCategoryId)) {
      const { badRequest } = require('../utils/errors');
      throw badRequest('التصنيف الفرعي لا يتبع القسم الرئيسي المحدد');
    }
    if (!body.parentCategoryId) {
      body.parentCategoryId = sub.categoryId.toString();
    }
    if (!body.nameAr) body.nameAr = sub.nameAr;
  }
}

/**
 * Create product category. Caller must ensure user has permission (admin or shop owner).
 */
async function create(shopId, userId, body, userRoles = []) {
  const shop = await Shop.findById(shopId);
  if (!shop) throw notFound('Shop not found');
  const isAdmin = Array.isArray(userRoles) && userRoles.includes('admin');
  const isOwner = shop.ownerId.toString() === userId.toString();
  if (!isAdmin && !isOwner) throw forbidden('Not the shop owner');
  await validateSectionTaxonomy(body);

  let parentCategory = null;
  if (body.parentCategoryId) {
    parentCategory = await Category.findById(body.parentCategoryId).lean();
    if (!parentCategory) {
      const { badRequest } = require('../utils/errors');
      throw badRequest('الفئة الرئيسية غير موجودة');
    }
    const existing = await ProductCategory.findOne({
      shopId,
      parentCategoryId: body.parentCategoryId,
      isActive: true,
    }).lean();
    if (existing) {
      const { badRequest } = require('../utils/errors');
      throw badRequest('هذا القسم مضاف مسبقاً لمتجرك');
    }
  }

  const nameAr = (body.nameAr || parentCategory?.nameAr || '').trim();
  if (!nameAr) {
    const { badRequest } = require('../utils/errors');
    throw badRequest('اسم القسم مطلوب');
  }

  const imageValue = body.image ? String(body.image).trim() : '';
  const resolvedImage = imageValue || (parentCategory?.icon ? String(parentCategory.icon).trim() : '');
  if (!resolvedImage) {
    const { badRequest } = require('../utils/errors');
    throw badRequest('أيقونة القسم مطلوبة');
  }

  const category = await ProductCategory.create({
    shopId,
    parentCategoryId: body.parentCategoryId || undefined,
    subcategoryId: body.subcategoryId || undefined,
    nameAr,
    order: body.order != null ? Number(body.order) : 0,
    isActive: body.isActive !== false,
    image: resolvedImage,
  });
  return category;
}

async function update(categoryId, shopId, userId, body, userRoles = []) {
  const shop = await Shop.findById(shopId);
  if (!shop) throw notFound('Shop not found');
  const isAdmin = Array.isArray(userRoles) && userRoles.includes('admin');
  const isOwner = shop.ownerId.toString() === userId.toString();
  if (!isAdmin && !isOwner) throw forbidden('Not the shop owner');
  const category = await ProductCategory.findOne({ _id: categoryId, shopId });
  if (!category) throw notFound('Product category not found');
  await validateSectionTaxonomy(body);
  if (body.parentCategoryId) {
    const parent = await Category.findById(body.parentCategoryId).lean();
    if (!parent) {
      const { badRequest } = require('../utils/errors');
      throw badRequest('الفئة الرئيسية غير موجودة');
    }
  }
  if (body.nameAr !== undefined) category.nameAr = String(body.nameAr).trim();
  if (body.parentCategoryId !== undefined) {
    category.parentCategoryId = body.parentCategoryId ? String(body.parentCategoryId).trim() : null;
  }
  if (body.subcategoryId !== undefined) {
    category.subcategoryId = body.subcategoryId ? String(body.subcategoryId).trim() : null;
  }
  if (body.order !== undefined) category.order = Number(body.order);
  if (body.isActive !== undefined) category.isActive = body.isActive !== false;
  if (body.image !== undefined) category.image = body.image ? String(body.image).trim() : null;
  await category.save();
  return category;
}

/**
 * إضافة سريعة لفئات متعددة من نص (سطر = اسم فئة).
 * @param {string} shopId
 * @param {string} userId
 * @param {string[]} userRoles
 * @param {string} text - نص يحتوي أسماء الفئات (سطر واحد لكل فئة)
 * @returns {{ created: object[], failed: { lineIndex?: number, name?: string, reason: string }[] }}
 */
async function bulkCreate(shopId, userId, userRoles, text) {
  const shop = await Shop.findById(shopId);
  if (!shop) throw notFound('Shop not found');
  const isAdmin = Array.isArray(userRoles) && userRoles.includes('admin');
  const isOwner = shop.ownerId.toString() === userId.toString();
  if (!isAdmin && !isOwner) throw forbidden('Not the shop owner');

  const lines = (typeof text === 'string' ? text : '')
    .split(/\r?\n/)
    .map((s) => s.trim())
    .filter((s) => s.length > 0);

  const created = [];
  const failed = [];
  const NAME_MAX_LENGTH = 100;

  for (let i = 0; i < lines.length; i++) {
    const nameAr = lines[i];
    const lineIndex = i + 1;
    if (!nameAr || nameAr.length === 0) continue;
    if (nameAr.length > NAME_MAX_LENGTH) {
      failed.push({
        lineIndex,
        name: nameAr,
        reason: 'الاسم أطول من 100 حرف',
      });
      continue;
    }
    try {
      const category = await ProductCategory.create({
        shopId,
        nameAr,
        order: created.length,
        isActive: true,
      });
      created.push({
        _id: category._id.toString(),
        nameAr: category.nameAr,
      });
    } catch (err) {
      failed.push({
        lineIndex,
        name: nameAr,
        reason: err.message || 'خطأ غير معروف عند إنشاء التصنيف',
      });
    }
  }

  return { created, failed };
}

async function remove(categoryId, shopId, userId, userRoles = []) {
  const shop = await Shop.findById(shopId);
  if (!shop) throw notFound('Shop not found');
  const isAdmin = Array.isArray(userRoles) && userRoles.includes('admin');
  const isOwner = shop.ownerId.toString() === userId.toString();
  if (!isAdmin && !isOwner) throw forbidden('Not the shop owner');
  const category = await ProductCategory.findOne({ _id: categoryId, shopId });
  if (!category) throw notFound('Product category not found');
  const productCount = await Product.countDocuments({ productCategoryId: categoryId });
  if (productCount > 0) {
    const { badRequest } = require('../utils/errors');
    throw badRequest(`لا يمكن الحذف: ${productCount} منتج مرتبط بهذا التصنيف`);
  }
  await ProductCategory.findByIdAndDelete(categoryId);
  return { deleted: true };
}

/**
 * إعادة ترتيب التصنيفات حسب القائمة المعطاة (الفهرس = ترتيب العرض).
 * @param {string} shopId
 * @param {string} userId
 * @param {string[]} categoryIds - معرفات التصنيفات بالترتيب المطلوب
 * @param {string[]} userRoles
 */
async function reorder(shopId, userId, categoryIds, userRoles = []) {
  const shop = await Shop.findById(shopId);
  if (!shop) throw notFound('Shop not found');
  const isAdmin = Array.isArray(userRoles) && userRoles.includes('admin');
  const isOwner = shop.ownerId.toString() === userId.toString();
  if (!isAdmin && !isOwner) throw forbidden('Not the shop owner');
  if (!Array.isArray(categoryIds) || categoryIds.length === 0) {
    const { badRequest } = require('../utils/errors');
    throw badRequest('قائمة معرفات التصنيفات مطلوبة');
  }
  for (let i = 0; i < categoryIds.length; i++) {
    const category = await ProductCategory.findOne({ _id: categoryIds[i], shopId });
    if (!category) {
      const { badRequest } = require('../utils/errors');
      throw badRequest(`التصنيف غير موجود أو لا ينتمي للمحل: ${categoryIds[i]}`);
    }
    category.order = i;
    await category.save();
  }
  return listByShop(shopId, { activeOnly: false });
}

module.exports = { listByShop, getById, create, bulkCreate, update, remove, reorder };
