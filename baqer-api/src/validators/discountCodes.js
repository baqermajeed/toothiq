const Joi = require('joi');
const { orderItemSchema, shopPortionSchema } = require('./orders');

const quoteDiscountSchema = Joi.object({
  shopPortions: Joi.array().items(shopPortionSchema).min(1).required(),
  discountCode: Joi.string().trim().min(1).required(),
});

function validateQuoteDiscount(body) {
  return quoteDiscountSchema.validate(body, { abortEarly: false });
}

const createDiscountCodeAdminSchema = Joi.object({
  code: Joi.string().trim().min(4).max(32).allow('', null),
  discountAmount: Joi.number().positive().required(),
  maxUses: Joi.number().integer().min(1).required(),
  expiresAt: Joi.alternatives().try(Joi.date(), Joi.string().trim().allow('', null)).allow(null),
  isActive: Joi.boolean(),
});

function validateCreateDiscountCodeAdmin(body) {
  return createDiscountCodeAdminSchema.validate(body, { abortEarly: false });
}

const updateDiscountCodeAdminSchema = Joi.object({
  isActive: Joi.boolean(),
  discountAmount: Joi.number().positive(),
  maxUses: Joi.number().integer().min(1),
})
  .min(1)
  .messages({ 'object.min': 'لا توجد حقول للتحديث' });

function validateUpdateDiscountCodeAdmin(body) {
  return updateDiscountCodeAdminSchema.validate(body, { abortEarly: false });
}

module.exports = {
  validateQuoteDiscount,
  validateCreateDiscountCodeAdmin,
  validateUpdateDiscountCodeAdmin,
};
