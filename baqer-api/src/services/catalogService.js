const mongoose = require('mongoose');
const { Category, ProductSubcategory, ProductBrand, Product, Shop, ProductCategory } = require('../models');
const { notFound } = require('../utils/errors');
const productService = require('./productService');

async function getVisibleShopIds() {
  return Shop.find({ isActive: true, isHidden: { $ne: true } }).distinct('_id');
}

function baseProductMatch(visibleShopIds) {
  return {
    isAvailable: true,
    shopId: { $in: visibleShopIds },
    categoryId: { $exists: true, $ne: null },
  };
}

function mapSubcategoryRow(s, countById = {}) {
  return {
    id: s._id.toString(),
    categoryId: s.categoryId.toString(),
    nameAr: s.nameAr,
    order: s.order ?? 0,
    productsCount: countById[s._id.toString()] || 0,
  };
}

function mapBrandRow(b, countById = {}) {
  return {
    id: b._id.toString(),
    categoryId: b.categoryId.toString(),
    nameAr: b.nameAr,
    order: b.order ?? 0,
    productsCount: countById[b._id.toString()] || 0,
  };
}

/**
 * قائمة الأقسام العامة مع عدد المنتجات المتاحة من كل المحلات.
 * تشمل أقسام الإدارة + الأقسام المخصصة التي أضافها أصحاب المتاجر.
 */
async function listCategories() {
  const visibleShopIds = await getVisibleShopIds();
  const categories = await Category.find({ isActive: true }).sort({ order: 1, nameAr: 1 }).lean();
  const countRows = await Product.aggregate([
    { $match: baseProductMatch(visibleShopIds) },
    { $group: { _id: '$categoryId', count: { $sum: 1 } } },
  ]);
  const countById = Object.fromEntries(countRows.map((r) => [r._id.toString(), r.count]));

  const adminCategories = categories.map((c) => ({
    id: c._id.toString(),
    nameAr: c.nameAr,
    icon: c.icon || '',
    order: c.order ?? 0,
    productsCount: countById[c._id.toString()] || 0,
    source: 'admin',
  }));

  const shopCategoryCountRows = await Product.aggregate([
    {
      $match: {
        isAvailable: true,
        shopId: { $in: visibleShopIds },
        productCategoryId: { $exists: true, $ne: null },
      },
    },
    { $group: { _id: '$productCategoryId', count: { $sum: 1 } } },
  ]);
  const shopCategoryCountById = Object.fromEntries(
    shopCategoryCountRows.map((r) => [r._id.toString(), r.count])
  );

  const shopCategoryIds = Object.keys(shopCategoryCountById);
  const shopCategories =
    shopCategoryIds.length > 0
      ? await ProductCategory.find({
          _id: { $in: shopCategoryIds },
          isActive: true,
          $or: [{ parentCategoryId: { $exists: false } }, { parentCategoryId: null }],
        })
          .sort({ order: 1, nameAr: 1 })
          .lean()
      : [];

  const customCategories = shopCategories.map((c) => ({
    id: c._id.toString(),
    nameAr: c.nameAr,
    icon: c.image || '',
    order: (c.order ?? 0) + 10000,
    productsCount: shopCategoryCountById[c._id.toString()] || 0,
    source: 'shop',
    shopId: c.shopId?.toString() || null,
  }));

  return [...adminCategories, ...customCategories].sort(
    (a, b) => (a.order ?? 0) - (b.order ?? 0) || a.nameAr.localeCompare(b.nameAr, 'ar')
  );
}

/**
 * تفاصيل قسم عام: الأقسام الفرعية والبراندات التي لها منتجات + عدد المنتجات الكلي.
 */
async function getCategoryDetail(categoryId) {
  if (!mongoose.Types.ObjectId.isValid(String(categoryId))) {
    throw notFound('التصنيف غير موجود');
  }
  const category = await Category.findOne({ _id: categoryId, isActive: true }).lean();
  if (!category) throw notFound('التصنيف غير موجود');

  const visibleShopIds = await getVisibleShopIds();
  const catOid = new mongoose.Types.ObjectId(String(categoryId));

  const [totalProducts, subCountRows, brandCountRows] = await Promise.all([
    Product.countDocuments({ ...baseProductMatch(visibleShopIds), categoryId: catOid }),
    Product.aggregate([
      { $match: { ...baseProductMatch(visibleShopIds), categoryId: catOid, subcategoryId: { $exists: true, $ne: null } } },
      { $group: { _id: '$subcategoryId', count: { $sum: 1 } } },
    ]),
    Product.aggregate([
      { $match: { ...baseProductMatch(visibleShopIds), categoryId: catOid, brandId: { $exists: true, $ne: null } } },
      { $group: { _id: '$brandId', count: { $sum: 1 } } },
    ]),
  ]);

  const subIdsWithProducts = subCountRows.map((r) => r._id);
  const brandIdsWithProducts = brandCountRows.map((r) => r._id);
  const countBySubId = Object.fromEntries(subCountRows.map((r) => [r._id.toString(), r.count]));
  const countByBrandId = Object.fromEntries(brandCountRows.map((r) => [r._id.toString(), r.count]));

  const [subcategories, brands] = await Promise.all([
    subIdsWithProducts.length > 0
      ? ProductSubcategory.find({ _id: { $in: subIdsWithProducts }, isActive: true })
          .sort({ order: 1, nameAr: 1 })
          .lean()
      : [],
    brandIdsWithProducts.length > 0
      ? ProductBrand.find({ _id: { $in: brandIdsWithProducts }, isActive: true })
          .sort({ order: 1, nameAr: 1 })
          .lean()
      : [],
  ]);

  return {
    id: category._id.toString(),
    nameAr: category.nameAr,
    icon: category.icon || '',
    order: category.order ?? 0,
    productsCount: totalProducts,
    subcategories: subcategories.map((s) => mapSubcategoryRow(s, countBySubId)),
    brands: brands.map((b) => mapBrandRow(b, countByBrandId)),
  };
}

/**
 * الأقسام الفرعية لقسم عام (لاختيار صاحب المحل).
 */
async function listSubcategoriesByCategory(categoryId, { activeOnly = true, withCounts = false } = {}) {
  if (!mongoose.Types.ObjectId.isValid(String(categoryId))) {
    throw notFound('التصنيف غير موجود');
  }
  const category = await Category.findById(categoryId).lean();
  if (!category) throw notFound('التصنيف غير موجود');

  const query = { categoryId };
  if (activeOnly) query.isActive = true;
  const items = await ProductSubcategory.find(query).sort({ order: 1, nameAr: 1 }).lean();

  if (!withCounts) {
    return items.map((s) => ({
      id: s._id.toString(),
      categoryId: s.categoryId.toString(),
      nameAr: s.nameAr,
      order: s.order ?? 0,
    }));
  }

  const visibleShopIds = await getVisibleShopIds();
  const subIds = items.map((s) => s._id);
  const countRows = subIds.length > 0
    ? await Product.aggregate([
        {
          $match: {
            ...baseProductMatch(visibleShopIds),
            categoryId: new mongoose.Types.ObjectId(String(categoryId)),
            subcategoryId: { $in: subIds },
          },
        },
        { $group: { _id: '$subcategoryId', count: { $sum: 1 } } },
      ])
    : [];
  const countById = Object.fromEntries(countRows.map((r) => [r._id.toString(), r.count]));

  return items.map((s) => mapSubcategoryRow(s, countById));
}

/**
 * البراندات لقسم عام (لاختيار صاحب المحل).
 */
async function listBrandsByCategory(categoryId, { activeOnly = true, withCounts = false } = {}) {
  if (!mongoose.Types.ObjectId.isValid(String(categoryId))) {
    throw notFound('التصنيف غير موجود');
  }
  const category = await Category.findById(categoryId).lean();
  if (!category) throw notFound('التصنيف غير موجود');

  const query = { categoryId };
  if (activeOnly) query.isActive = true;
  const items = await ProductBrand.find(query).sort({ order: 1, nameAr: 1 }).lean();

  if (!withCounts) {
    return items.map((b) => ({
      id: b._id.toString(),
      categoryId: b.categoryId.toString(),
      nameAr: b.nameAr,
      order: b.order ?? 0,
    }));
  }

  const visibleShopIds = await getVisibleShopIds();
  const brandIds = items.map((b) => b._id);
  const countRows = brandIds.length > 0
    ? await Product.aggregate([
        {
          $match: {
            ...baseProductMatch(visibleShopIds),
            categoryId: new mongoose.Types.ObjectId(String(categoryId)),
            brandId: { $in: brandIds },
          },
        },
        { $group: { _id: '$brandId', count: { $sum: 1 } } },
      ])
    : [];
  const countById = Object.fromEntries(countRows.map((r) => [r._id.toString(), r.count]));

  return items.map((b) => mapBrandRow(b, countById));
}

/**
 * شجرة التصنيف الكاملة للتطبيق (أقسام + فرعية + براندات).
 */
async function getTaxonomyTree() {
  const categories = await listCategories();
  const [allSubs, allBrands] = await Promise.all([
    ProductSubcategory.find({ isActive: true }).sort({ order: 1, nameAr: 1 }).lean(),
    ProductBrand.find({ isActive: true }).sort({ order: 1, nameAr: 1 }).lean(),
  ]);
  const subsByCategory = {};
  for (const s of allSubs) {
    const key = s.categoryId.toString();
    if (!subsByCategory[key]) subsByCategory[key] = [];
    subsByCategory[key].push({
      id: s._id.toString(),
      categoryId: key,
      nameAr: s.nameAr,
      order: s.order ?? 0,
    });
  }
  const brandsByCategory = {};
  for (const b of allBrands) {
    const key = b.categoryId.toString();
    if (!brandsByCategory[key]) brandsByCategory[key] = [];
    brandsByCategory[key].push({
      id: b._id.toString(),
      categoryId: key,
      nameAr: b.nameAr,
      order: b.order ?? 0,
    });
  }
  return categories.map((c) => ({
    ...c,
    subcategories: subsByCategory[c.id] || [],
    brands: brandsByCategory[c.id] || [],
  }));
}

/**
 * منتجات من كل المحلات حسب القسم/الفرعي/البراند.
 */
async function listProducts(filters = {}) {
  return productService.listCatalogProducts(filters);
}

/**
 * كتالوج داخل محل: قسم عام → أقسام فرعية/براندات → منتجات المحل.
 */
async function getShopCatalog(shopId, categoryId, opts = {}) {
  if (!mongoose.Types.ObjectId.isValid(String(shopId))) {
    throw notFound('المحل غير موجود');
  }
  const shop = await Shop.findOne({ _id: shopId, isActive: true, isHidden: { $ne: true } }).lean();
  if (!shop) throw notFound('المحل غير موجود');

  if (!categoryId || !mongoose.Types.ObjectId.isValid(String(categoryId))) {
    throw notFound('التصنيف غير موجود');
  }
  const category = await Category.findOne({ _id: categoryId, isActive: true }).lean();
  if (!category) throw notFound('التصنيف غير موجود');

  const shopOid = new mongoose.Types.ObjectId(String(shopId));
  const catOid = new mongoose.Types.ObjectId(String(categoryId));
  const includeProducts = opts.includeProducts === true;
  const includeUnavailable = opts.includeUnavailable === true;

  const productQuery = { shopId: shopOid, categoryId: catOid };
  if (!includeUnavailable) productQuery.isAvailable = true;

  const [subCountRows, brandCountRows, allProductsCount] = await Promise.all([
    Product.aggregate([
      {
        $match: {
          ...productQuery,
          subcategoryId: { $exists: true, $ne: null },
        },
      },
      { $group: { _id: '$subcategoryId', count: { $sum: 1 } } },
    ]),
    Product.aggregate([
      {
        $match: {
          ...productQuery,
          brandId: { $exists: true, $ne: null },
        },
      },
      { $group: { _id: '$brandId', count: { $sum: 1 } } },
    ]),
    Product.countDocuments(productQuery),
  ]);

  const subIds = subCountRows.map((r) => r._id);
  const brandIds = brandCountRows.map((r) => r._id);
  const countBySubId = Object.fromEntries(subCountRows.map((r) => [r._id.toString(), r.count]));
  const countByBrandId = Object.fromEntries(brandCountRows.map((r) => [r._id.toString(), r.count]));

  const [subcategories, brands] = await Promise.all([
    subIds.length > 0
      ? ProductSubcategory.find({ _id: { $in: subIds }, isActive: true }).sort({ order: 1, nameAr: 1 }).lean()
      : [],
    brandIds.length > 0
      ? ProductBrand.find({ _id: { $in: brandIds }, isActive: true }).sort({ order: 1, nameAr: 1 }).lean()
      : [],
  ]);

  let productsBySubId = {};
  let productsByBrandId = {};
  if (includeProducts) {
    if (subIds.length > 0) {
      const products = await Product.find({
        ...productQuery,
        subcategoryId: { $in: subIds },
      })
        .populate('subcategoryId', 'nameAr')
        .sort({ createdAt: -1 })
        .lean();
      for (const p of products) {
        const sid = p.subcategoryId?._id?.toString() ?? p.subcategoryId?.toString();
        if (!sid) continue;
        if (!productsBySubId[sid]) productsBySubId[sid] = [];
        productsBySubId[sid].push(productService.mapProductForCatalog(p));
      }
    }
    if (brandIds.length > 0) {
      const products = await Product.find({
        ...productQuery,
        brandId: { $in: brandIds },
      })
        .populate('brandId', 'nameAr')
        .sort({ createdAt: -1 })
        .lean();
      for (const p of products) {
        const bid = p.brandId?._id?.toString() ?? p.brandId?.toString();
        if (!bid) continue;
        if (!productsByBrandId[bid]) productsByBrandId[bid] = [];
        productsByBrandId[bid].push(productService.mapProductForCatalog(p));
      }
    }
  }

  const subcategoryBlocks = subcategories.map((s) => {
    const sid = s._id.toString();
    return {
      id: sid,
      nameAr: s.nameAr,
      order: s.order ?? 0,
      productsCount: countBySubId[sid] || 0,
      products: includeProducts ? (productsBySubId[sid] || []) : undefined,
    };
  });

  const brandBlocks = brands.map((b) => {
    const bid = b._id.toString();
    return {
      id: bid,
      nameAr: b.nameAr,
      order: b.order ?? 0,
      productsCount: countByBrandId[bid] || 0,
      products: includeProducts ? (productsByBrandId[bid] || []) : undefined,
    };
  });

  let allProducts;
  if (includeProducts) {
    const raw = await Product.find(productQuery).sort({ createdAt: -1 }).lean();
    allProducts = raw.map((p) => productService.mapProductForCatalog(p));
  }

  return {
    shopId: shop._id.toString(),
    shopName: shop.name,
    category: {
      id: category._id.toString(),
      nameAr: category.nameAr,
      icon: category.icon || '',
    },
    productsCount: allProductsCount,
    subcategories: subcategoryBlocks,
    brands: brandBlocks,
    allProducts,
  };
}

module.exports = {
  listCategories,
  getCategoryDetail,
  listSubcategoriesByCategory,
  listBrandsByCategory,
  getTaxonomyTree,
  listProducts,
  getShopCatalog,
};
