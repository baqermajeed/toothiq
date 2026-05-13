const Joi = require('joi');

const polygonSchema = Joi.object({
  type: Joi.string().valid('Polygon').optional(),
  coordinates: Joi.array()
    .items(
      Joi.array()
        .items(Joi.array().items(Joi.number()).length(2))
        .min(3)
    )
    .min(1)
    .required(),
}).optional();

const createBannerSchema = Joi.object({
  image: Joi.string().trim().required(),
  title: Joi.string().trim().allow('').optional(),
  actionType: Joi.string().valid('shop', 'product', 'external_url').required(),
  shopId: Joi.string().allow(null, '').optional(),
  productId: Joi.string().allow(null, '').optional(),
  externalUrl: Joi.string().trim().allow(null, '').optional(),
  order: Joi.number().optional(),
  isActive: Joi.boolean().optional(),
  polygon: polygonSchema,
});

const updateBannerSchema = Joi.object({
  image: Joi.string().trim().optional(),
  title: Joi.string().trim().allow('').optional(),
  actionType: Joi.string().valid('shop', 'product', 'external_url').optional(),
  shopId: Joi.string().allow(null, '').optional(),
  productId: Joi.string().allow(null, '').optional(),
  externalUrl: Joi.string().trim().allow(null, '').optional(),
  order: Joi.number().optional(),
  isActive: Joi.boolean().optional(),
  polygon: Joi.alternatives().try(polygonSchema, Joi.allow(null)).optional(),
});

function validateCreateBanner(body) {
  return createBannerSchema.validate(body, { abortEarly: false });
}

function validateUpdateBanner(body) {
  return updateBannerSchema.validate(body, { abortEarly: false });
}

module.exports = { validateCreateBanner, validateUpdateBanner };
