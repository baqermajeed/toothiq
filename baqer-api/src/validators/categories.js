const Joi = require('joi');
const mongoose = require('mongoose');

const objectIdString = Joi.string().custom((value, helpers) => {
  if (!mongoose.Types.ObjectId.isValid(value)) return helpers.error('any.invalid');
  return value;
});

const createCategorySchema = Joi.object({
  nameAr: Joi.string().trim().min(1).max(100).required(),
  icon: Joi.string().trim().max(50).allow('').default(''),
  order: Joi.number().integer().min(0),
  isActive: Joi.boolean(),
});

const updateCategorySchema = Joi.object({
  nameAr: Joi.string().trim().min(1).max(100),
  icon: Joi.string().trim().max(50).allow(''),
  order: Joi.number().integer().min(0),
  isActive: Joi.boolean(),
}).min(1);

function validateCreateCategory(body) {
  return createCategorySchema.validate(body, { abortEarly: false });
}

function validateUpdateCategory(body) {
  return updateCategorySchema.validate(body, { abortEarly: false });
}

const reorderCategoriesSchema = Joi.object({
  orderedIds: Joi.array().items(objectIdString).min(1).required(),
});

function validateReorderCategories(body) {
  return reorderCategoriesSchema.validate(body, { abortEarly: false });
}

module.exports = {
  validateCreateCategory,
  validateUpdateCategory,
  validateReorderCategories,
};
