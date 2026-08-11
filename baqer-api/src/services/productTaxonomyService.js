const mongoose = require('mongoose');
const { Category, ProductSubcategory, ProductBrand, Product } = require('../models');
const { badRequest, notFound } = require('../utils/errors');

function ensureObjectId(id, fieldName) {
  if (!mongoose.Types.ObjectId.isValid(String(id))) {
    throw badRequest(`${fieldName} غير صالح`);
  }
}

async function listAll() {
  const [categories, subcategories, brands] = await Promise.all([
    Category.find().sort({ order: 1, nameAr: 1 }).lean(),
    ProductSubcategory.find().sort({ order: 1, nameAr: 1 }).lean(),
    ProductBrand.find().sort({ order: 1, nameAr: 1 }).lean(),
  ]);
  return { categories, subcategories, brands };
}

async function createSubcategory(body) {
  ensureObjectId(body.categoryId, 'categoryId');
  const category = await Category.findById(body.categoryId).lean();
  if (!category) throw notFound('التصنيف الرئيسي غير موجود');
  const nameAr = String(body.nameAr || '').trim();
  const exists = await ProductSubcategory.findOne({ categoryId: body.categoryId, nameAr }).lean();
  if (exists) throw badRequest('التصنيف الفرعي موجود مسبقاً داخل نفس التصنيف الرئيسي');
  return ProductSubcategory.create({
    categoryId: body.categoryId,
    nameAr,
    order: body.order != null ? Number(body.order) : 0,
    isActive: body.isActive !== false,
  });
}

async function updateSubcategory(id, body) {
  const row = await ProductSubcategory.findById(id);
  if (!row) throw notFound('التصنيف الفرعي غير موجود');
  if (body.categoryId !== undefined) {
    ensureObjectId(body.categoryId, 'categoryId');
    const category = await Category.findById(body.categoryId).lean();
    if (!category) throw notFound('التصنيف الرئيسي غير موجود');
    row.categoryId = body.categoryId;
  }
  if (body.nameAr !== undefined) row.nameAr = String(body.nameAr).trim();
  if (body.order !== undefined) row.order = Number(body.order);
  if (body.isActive !== undefined) row.isActive = body.isActive !== false;
  await row.save();
  return row;
}

async function removeSubcategory(id) {
  const row = await ProductSubcategory.findById(id);
  if (!row) throw notFound('التصنيف الفرعي غير موجود');
  const productsCount = await Product.countDocuments({ subcategoryId: id });
  if (productsCount > 0) throw badRequest('لا يمكن حذف التصنيف الفرعي لوجود منتجات مرتبطة به');
  await ProductSubcategory.findByIdAndDelete(id);
  return { deleted: true };
}

async function createBrand(body) {
  ensureObjectId(body.categoryId, 'categoryId');
  const category = await Category.findById(body.categoryId).lean();
  if (!category) throw notFound('التصنيف الرئيسي غير موجود');
  const nameAr = String(body.nameAr || '').trim();
  const exists = await ProductBrand.findOne({ categoryId: body.categoryId, nameAr }).lean();
  if (exists) throw badRequest('البراند موجود مسبقاً داخل نفس التصنيف الرئيسي');
  return ProductBrand.create({
    categoryId: body.categoryId,
    nameAr,
    order: body.order != null ? Number(body.order) : 0,
    isActive: body.isActive !== false,
  });
}

async function updateBrand(id, body) {
  const row = await ProductBrand.findById(id);
  if (!row) throw notFound('البراند غير موجود');
  if (body.categoryId !== undefined) {
    ensureObjectId(body.categoryId, 'categoryId');
    const category = await Category.findById(body.categoryId).lean();
    if (!category) throw notFound('التصنيف الرئيسي غير موجود');
    row.categoryId = body.categoryId;
  }
  if (body.nameAr !== undefined) row.nameAr = String(body.nameAr).trim();
  if (body.order !== undefined) row.order = Number(body.order);
  if (body.isActive !== undefined) row.isActive = body.isActive !== false;
  await row.save();
  return row;
}

async function removeBrand(id) {
  const row = await ProductBrand.findById(id);
  if (!row) throw notFound('البراند غير موجود');
  const productsCount = await Product.countDocuments({ brandId: id });
  if (productsCount > 0) throw badRequest('لا يمكن حذف البراند لوجود منتجات مرتبطة به');
  await ProductBrand.findByIdAndDelete(id);
  return { deleted: true };
}

module.exports = {
  listAll,
  createSubcategory,
  updateSubcategory,
  removeSubcategory,
  createBrand,
  updateBrand,
  removeBrand,
};
