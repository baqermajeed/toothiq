const Joi = require('joi');

const createProductCategorySchema = Joi.object({
  nameAr: Joi.string().trim().min(1).max(100).required(),
  parentCategoryId: Joi.string().trim().allow('', null),
  subcategoryId: Joi.string().trim().allow('', null),
  order: Joi.number().integer().min(0).empty(''),
  isActive: Joi.boolean().truthy('true', '1').falsy('false', '0', ''),
  image: Joi.string().trim().allow('', null),
});

const updateProductCategorySchema = Joi.object({
  nameAr: Joi.string().trim().min(1).max(100),
  parentCategoryId: Joi.string().trim().allow('', null),
  subcategoryId: Joi.string().trim().allow('', null),
  order: Joi.number().integer().min(0).empty(''),
  isActive: Joi.boolean().truthy('true', '1').falsy('false', '0', ''),
  image: Joi.string().trim().allow('', null),
}).min(1);

function validateCreateProductCategory(body) {
  return createProductCategorySchema.validate(body, { abortEarly: false });
}

function validateUpdateProductCategory(body) {
  return updateProductCategorySchema.validate(body, { abortEarly: false });
}

const bulkBodySchema = Joi.object({
  text: Joi.string().required(),
});

const reorderBodySchema = Joi.object({
  categoryIds: Joi.array().items(Joi.string().trim().required()).min(1).required(),
});

function validateBulkBody(body) {
  return bulkBodySchema.validate(body, { abortEarly: false });
}

function validateReorderBody(body) {
  return reorderBodySchema.validate(body, { abortEarly: false });
}

module.exports = {
  validateCreateProductCategory,
  validateUpdateProductCategory,
  validateBulkBody,
  validateReorderBody,
};
