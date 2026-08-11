const Joi = require('joi');

const createProductSchema = Joi.object({
  name: Joi.string().trim().min(1).max(200).required(),
  description: Joi.string().trim().allow(''),
  price: Joi.number().min(0).required(),
  image: Joi.string().trim().allow(''),
  images: Joi.array().items(Joi.string().trim().allow('')).optional(),
  isAvailable: Joi.boolean(),
  categoryId: Joi.string().trim().allow('', null).optional(),
  subcategoryId: Joi.string().trim().allow('', null).optional(),
  brandId: Joi.string().trim().allow('', null).optional(),
  productCategoryId: Joi.string().trim().allow('').optional(),
  offerPrice: Joi.number().min(0).allow(null),
  offerEndsAt: Joi.date().iso().allow(null),
  stock: Joi.number().integer().min(0),
  quantity: Joi.number().integer().min(0),
  productionDate: Joi.date().iso().allow(null),
  expiryDate: Joi.date().iso().allow(null),
});

const updateProductSchema = Joi.object({
  name: Joi.string().trim().min(1).max(200),
  description: Joi.string().trim().allow(''),
  price: Joi.number().min(0),
  image: Joi.string().trim().allow(''),
  images: Joi.array().items(Joi.string().trim().allow('')).optional(),
  isAvailable: Joi.boolean(),
  categoryId: Joi.string().trim().allow('', null),
  subcategoryId: Joi.string().trim().allow('', null),
  brandId: Joi.string().trim().allow('', null),
  productCategoryId: Joi.string().trim().allow('', null),
  offerPrice: Joi.number().min(0).allow(null),
  offerEndsAt: Joi.date().iso().allow(null),
  stock: Joi.number().integer().min(0),
  quantity: Joi.number().integer().min(0),
  productionDate: Joi.date().iso().allow(null),
  expiryDate: Joi.date().iso().allow(null),
}).min(1);

function validateCreateProduct(body) {
  return createProductSchema.validate(body, { abortEarly: false });
}

function validateUpdateProduct(body) {
  return updateProductSchema.validate(body, { abortEarly: false });
}

const bulkBodySchema = Joi.object({
  text: Joi.string().required().messages({ 'string.empty': 'نص المنتجات مطلوب' }),
});

function validateBulkBody(body) {
  return bulkBodySchema.validate(body, { abortEarly: false });
}

const copyFromShopBodySchema = Joi.object({
  sourceShopId: Joi.string().trim().required().messages({ 'string.empty': 'معرّف المحل المصدر مطلوب' }),
  productIds: Joi.array().items(Joi.string().trim().required()).min(1).required().messages({
    'array.min': 'يجب تحديد منتج واحد على الأقل للنسخ',
  }),
}).unknown(true);

function validateCopyFromShopBody(body) {
  return copyFromShopBodySchema.validate(body, { abortEarly: false });
}

module.exports = { validateCreateProduct, validateUpdateProduct, validateBulkBody, validateCopyFromShopBody };
