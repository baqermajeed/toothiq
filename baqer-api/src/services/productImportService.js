const { Product, ProductCategory, Shop, Category, ProductSubcategory, ProductBrand } = require('../models');
const { badRequest, notFound, forbidden } = require('../utils/errors');
const { parseIraqiPrice } = require('../utils/iraqiPrice');

const GENERAL_CATEGORY_NAME = 'منتجات عامة';
const DEFAULT_IMAGE = '/uploads/products/photo_2026-03-18 00.25.48.jpeg';

function nameKey(value) {
  return String(value || '')
    .trim()
    .replace(/\.+$/, '')
    .replace(/\s+/g, ' ')
    .toLowerCase();
}

function parseExpiry(raw) {
  if (raw == null || raw === '') return undefined;
  if (raw instanceof Date && !Number.isNaN(raw.getTime())) return raw;
  if (typeof raw === 'number' && Number.isFinite(raw) && raw > 20000 && raw < 80000) {
    const utc = Date.UTC(1899, 11, 30) + Math.round(raw) * 86400000;
    const d = new Date(utc);
    return Number.isNaN(d.getTime()) ? undefined : d;
  }
  const s = String(raw).trim();
  if (!s) return undefined;
  const iso = new Date(s);
  if (!Number.isNaN(iso.getTime())) return iso;
  const m = s.match(/^(\d{1,2})[/.\\-](\d{1,2})[/.\\-](\d{2,4})$/);
  if (m) {
    const year = Number(m[3].length === 2 ? `20${m[3]}` : m[3]);
    const d = new Date(year, Number(m[2]) - 1, Number(m[1]));
    if (!Number.isNaN(d.getTime())) return d;
  }
  return undefined;
}

async function ensureGeneralCategory() {
  let category = await Category.findOne({ nameAr: GENERAL_CATEGORY_NAME }).lean();
  if (category) return category;
  category = await Category.create({
    nameAr: GENERAL_CATEGORY_NAME,
    icon: DEFAULT_IMAGE,
    order: 999,
    isActive: true,
  });
  return category.toObject ? category.toObject() : category;
}

async function getOrCreate(map, key, factory) {
  if (!key) return null;
  if (map.has(key)) return map.get(key);
  const created = await factory();
  const doc = created.toObject ? created.toObject() : created;
  map.set(key, doc);
  return doc;
}

async function resolveShopSection(shopId, general, subcategory) {
  if (!subcategory) return null;
  const bySub = await ProductCategory.findOne({ shopId, subcategoryId: subcategory._id }).lean();
  if (bySub) return bySub;
  const byName = await ProductCategory.findOne({
    shopId,
    nameAr: subcategory.nameAr,
  }).lean();
  if (byName) return byName;

  const existingParent = await ProductCategory.findOne({
    shopId,
    parentCategoryId: general._id,
  }).lean();

  const created = await ProductCategory.create({
    shopId,
    nameAr: subcategory.nameAr,
    parentCategoryId: existingParent ? undefined : general._id,
    subcategoryId: subcategory._id,
    image: general.icon || DEFAULT_IMAGE,
    isActive: true,
  });
  return created.toObject ? created.toObject() : created;
}

/**
 * استيراد منتجات من صفوف جاهزة بعد مطابقة أعمدة الأكسل.
 * الصف الفاشل لا يوقف بقية الدفعة.
 */
async function importMappedProducts(shopId, userId, userRoles, payload) {
  const shop = await Shop.findById(shopId);
  if (!shop) throw notFound('المحل غير موجود');
  const isAdmin = Array.isArray(userRoles) && userRoles.includes('admin');
  if (!isAdmin && shop.ownerId.toString() !== String(userId)) {
    throw forbidden('ليس لديك صلاحية إضافة منتجات لهذا المحل');
  }

  const items = Array.isArray(payload.items) ? payload.items : [];
  if (items.length === 0) throw badRequest('لا توجد صفوف للاستيراد');
  if (items.length > 2000) throw badRequest('الحد الأقصى 2000 منتج في الملف الواحد');

  let shopSection = null;
  if (payload.productCategoryId) {
    shopSection = await ProductCategory.findOne({
      _id: payload.productCategoryId,
      shopId,
    }).lean();
    if (!shopSection) throw badRequest('قسم المتجر غير موجود أو لا يتبع هذا المحل');
  }

  const general = await ensureGeneralCategory();
  const taxonomyParentId = shopSection?.parentCategoryId
    ? String(shopSection.parentCategoryId)
    : String(general._id);

  const [subRows, brandRows] = await Promise.all([
    ProductSubcategory.find({ categoryId: taxonomyParentId }).lean(),
    ProductBrand.find({ categoryId: taxonomyParentId }).lean(),
  ]);
  const subMap = new Map(subRows.map((row) => [nameKey(row.nameAr), row]));
  const brandMap = new Map(brandRows.map((row) => [nameKey(row.nameAr), row]));

  const docs = [];
  const failed = [];

  for (let i = 0; i < items.length; i += 1) {
    const item = items[i] || {};
    const rowNum = Number(item.row) > 0 ? Number(item.row) : i + 2;
    const name = String(item.name || '').trim();
    const price = parseIraqiPrice(item.price);
    const categoryName = String(item.categoryName || '').trim();
    const brandName = String(item.brandName || '').trim();

    if (!name) {
      failed.push({ row: rowNum, name: '', reason: 'الاسم مطلوب' });
      continue;
    }
    if (name.length > 200) {
      failed.push({ row: rowNum, name, reason: 'الاسم أطول من 200 حرف' });
      continue;
    }
    if (price == null) {
      failed.push({ row: rowNum, name, reason: 'السعر غير صالح' });
      continue;
    }
    if (!shopSection && !categoryName && !brandName) {
      failed.push({
        row: rowNum,
        name,
        reason: 'يجب اختيار قسم المتجر أو ربط عمود تصنيف أو براند',
      });
      continue;
    }

    try {
      const subcategory = categoryName
        ? await getOrCreate(subMap, nameKey(categoryName), () =>
            ProductSubcategory.create({
              categoryId: taxonomyParentId,
              nameAr: categoryName,
              isActive: true,
            })
          )
        : null;
      const brand = brandName
        ? await getOrCreate(brandMap, nameKey(brandName), () =>
            ProductBrand.create({
              categoryId: taxonomyParentId,
              nameAr: brandName,
              image: DEFAULT_IMAGE,
              isActive: true,
            })
          )
        : null;

      let section = shopSection;
      if (!section && subcategory) {
        section = await resolveShopSection(shopId, general, subcategory);
      }

      const categoryId = taxonomyParentId;

      docs.push({
        metaRow: rowNum,
        shopId,
        name,
        description: String(item.description || '').trim(),
        price,
        isAvailable: true,
        categoryId,
        subcategoryId: subcategory?._id || section?.subcategoryId || undefined,
        brandId: brand?._id || undefined,
        productCategoryId: section?._id || undefined,
        expiryDate: parseExpiry(item.expiryDate),
        stock: 0,
      });
    } catch (err) {
      failed.push({ row: rowNum, name, reason: err.message || 'فشل تجهيز الصف' });
    }
  }

  const created = [];
  const batchSize = 150;
  for (let i = 0; i < docs.length; i += batchSize) {
    const batch = docs.slice(i, i + batchSize);
    const toInsert = batch.map(({ metaRow: _row, ...doc }) => doc);
    try {
      const inserted = await Product.insertMany(toInsert, { ordered: false });
      for (const product of inserted) {
        created.push({ _id: product._id, name: product.name });
      }
    } catch (err) {
      const insertedDocs = err.insertedDocs || [];
      for (const product of insertedDocs) {
        created.push({ _id: product._id, name: product.name });
      }
      const writeErrors = Array.isArray(err.writeErrors) ? err.writeErrors : [];
      if (writeErrors.length > 0) {
        for (const writeError of writeErrors) {
          const idx = writeError.index;
          const source = batch[idx];
          failed.push({
            row: source?.metaRow || i + idx + 2,
            name: source?.name || '',
            reason: writeError.errmsg || 'فشل حفظ المنتج',
          });
        }
      } else if (insertedDocs.length === 0) {
        for (const source of batch) {
          failed.push({
            row: source.metaRow,
            name: source.name,
            reason: err.message || 'فشل حفظ الدفعة',
          });
        }
      }
    }
  }

  return {
    createdCount: created.length,
    failedCount: failed.length,
    created,
    failed,
  };
}

module.exports = { importMappedProducts, parseIraqiPrice };
