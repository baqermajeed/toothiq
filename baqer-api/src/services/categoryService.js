const Category = require('../models/Category');
const ProductSubcategory = require('../models/ProductSubcategory');
const ProductBrand = require('../models/ProductBrand');
const { notFound, badRequest } = require('../utils/errors');

/** List categories for public/app (active only, sorted by order). */
async function list() {
  const items = await Category.find({ isActive: true }).sort({ order: 1, nameAr: 1 }).lean();
  return items.map((c) => ({
    id: c._id.toString(),
    nameAr: c.nameAr,
    icon: c.icon || '',
    order: c.order ?? 0,
  }));
}

/** List all categories for admin (including inactive). */
async function listAll() {
  const items = await Category.find().sort({ order: 1, nameAr: 1 }).lean();
  return items.map((c) => ({
    id: c._id.toString(),
    nameAr: c.nameAr,
    icon: c.icon || '',
    order: c.order ?? 0,
    isActive: c.isActive !== false,
    createdAt: c.createdAt,
    updatedAt: c.updatedAt,
  }));
}

/** Get category names (nameAr) for validation. */
async function getCategoryNames() {
  const docs = await Category.find({ isActive: true }).select('nameAr').lean();
  return docs.map((d) => d.nameAr);
}

/** Create category (admin). */
async function create(body) {
  const { nameAr, icon, order } = body;
  const existing = await Category.findOne({ nameAr: (nameAr || '').trim() });
  if (existing) throw badRequest('تصنيف بنفس الاسم موجود مسبقاً');
  const category = await Category.create({
    nameAr: (nameAr || '').trim(),
    icon: (icon || '').trim(),
    order: order != null ? Number(order) : 0,
    isActive: body.isActive !== false,
  });
  return category;
}

/** Set display order from admin drag-and-drop (must list every category id exactly once). */
async function reorder(orderedIds) {
  const ids = orderedIds.map((id) => String(id).trim());
  const all = await Category.find().select('_id').lean();
  if (all.length === 0) {
    if (ids.length > 0) throw badRequest('لا توجد تصنيفات');
    return listAll();
  }
  if (ids.length !== all.length) {
    throw badRequest('يجب تضمين جميع معرفات التصنيفات بالترتيب الجديد');
  }
  const idSet = new Set(ids);
  if (idSet.size !== ids.length) throw badRequest('معرفات مكررة في القائمة');
  for (const doc of all) {
    if (!idSet.has(doc._id.toString())) throw badRequest('معرف مفقود من القائمة');
  }
  const bulkOps = ids.map((id, i) => ({
    updateOne: {
      filter: { _id: id },
      update: { $set: { order: i } },
    },
  }));
  await Category.bulkWrite(bulkOps);
  return listAll();
}

/** Update category (admin). */
async function update(id, body) {
  const category = await Category.findById(id);
  if (!category) throw notFound('Category not found');
  if (body.nameAr !== undefined) {
    const trimmed = String(body.nameAr).trim();
    const existing = await Category.findOne({ nameAr: trimmed, _id: { $ne: id } });
    if (existing) throw badRequest('تصنيف بنفس الاسم موجود مسبقاً');
    category.nameAr = trimmed;
  }
  if (body.icon !== undefined) category.icon = String(body.icon).trim();
  if (body.order !== undefined) category.order = Number(body.order);
  if (body.isActive !== undefined) category.isActive = body.isActive !== false;
  await category.save();
  return category;
}

/** Delete category (admin). Fails if subcategories exist under it. */
async function remove(id) {
  const category = await Category.findById(id);
  if (!category) throw notFound('Category not found');
  const subCount = await ProductSubcategory.countDocuments({ categoryId: id });
  if (subCount > 0) {
    throw badRequest('لا يمكن حذف التصنيف الرئيسي لوجود تصنيفات فرعية مرتبطة به');
  }
  const brandCount = await ProductBrand.countDocuments({ categoryId: id });
  if (brandCount > 0) {
    throw badRequest('لا يمكن حذف التصنيف الرئيسي لوجود براندات مرتبطة به');
  }
  await Category.findByIdAndDelete(id);
  return { deleted: true };
}

/** Seed initial categories from constants (idempotent: only adds missing nameAr). */
async function seedFromConstants(namesWithIcons = []) {
  const existing = await Category.find().select('nameAr').lean();
  const existingNames = new Set(existing.map((e) => e.nameAr));
  let added = 0;
  for (let i = 0; i < namesWithIcons.length; i++) {
    const item = namesWithIcons[i];
    const nameAr = typeof item === 'string' ? item : (item && item.nameAr) || '';
    const icon = typeof item === 'object' && item && item.icon != null ? item.icon : '';
    if (!nameAr || existingNames.has(nameAr)) continue;
    await Category.create({ nameAr, icon, order: i, isActive: true });
    existingNames.add(nameAr);
    added++;
  }
  return { added };
}

module.exports = {
  list,
  listAll,
  getCategoryNames,
  create,
  update,
  reorder,
  remove,
  seedFromConstants,
};
