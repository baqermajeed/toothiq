const Joi = require('joi');
const { GOVERNORATE_IDS } = require('../config/iraqGovernorates');
const { joiOptionalObjectId } = require('./common');

/** وقت بصيغة HH:mm أو حقل فارغ */
const timeHHmm = Joi.alternatives().try(
  Joi.string().allow('', null),
  Joi.string().trim().pattern(/^\d{1,2}:\d{2}$/, { name: 'time' }).messages({
    'string.pattern.base': 'صيغة الوقت يجب أن تكون HH:mm (مثال: 09:00)',
  })
);

const createShopSchema = Joi.object({
  name: Joi.string().trim().min(1).max(200).required(),
  description: Joi.string().trim().allow(''),
  location: Joi.object({
    type: Joi.string().valid('Point').default('Point'),
    coordinates: Joi.array().items(Joi.number()).length(2).required(),
  }).required(),
  deliveryFee: Joi.number().min(0),
  openHours: Joi.object({
    from: timeHHmm,
    to: timeHHmm,
  }),
  image: Joi.string().trim().allow(''),
});

const updateShopSchema = Joi.object({
  name: Joi.string().trim().min(1).max(200),
  description: Joi.string().trim().allow(''),
  location: Joi.object({
    type: Joi.string().valid('Point').default('Point'),
    coordinates: Joi.array().items(Joi.number()).length(2).required(),
  }),
  deliveryFee: Joi.number().min(0),
  isOpen: Joi.boolean(),
  openHours: Joi.object({
    from: timeHHmm,
    to: timeHHmm,
  }),
  isActive: Joi.boolean(),
  isHidden: Joi.boolean(),
  image: Joi.string().trim().allow(''),
}).min(1);

/** Admin create shop: مالك عبر ownerId أو إنشاء/ربط عبر ownerPhone + بيانات الحساب. */
const createShopByAdminSchema = createShopSchema
  .keys({
    ownerId: joiOptionalObjectId(),
    ownerPhone: Joi.string().trim().pattern(/^[0-9\u0660-\u0669]{11}$/),
    ownerPassword: Joi.string().min(8).max(128).allow('', null),
    ownerName: Joi.string().trim().min(1).max(200).allow('', null),
    ownerGovernorateId: Joi.string().trim().valid(...GOVERNORATE_IDS).allow('', null),
    isOpen: Joi.boolean(),
    isHidden: Joi.boolean(),
    /** رسوم التوصيل من إعدادات المنصة فقط — لا تُخزَّن لكل محل من لوحة الأدمن. */
    deliveryFee: Joi.forbidden(),
  })
  .custom((value, helpers) => {
    const oid = value.ownerId && String(value.ownerId).trim();
    const ph = value.ownerPhone && String(value.ownerPhone).trim();
    if (!oid && !ph) {
      return helpers.error('any.custom', { message: 'يجب إرسال ownerId أو ownerPhone لمالك المحل' });
    }
    if (oid && ph) {
      return helpers.error('any.custom', { message: 'أرسل إما ownerId أو ownerPhone وليس الاثنين' });
    }
    return value;
  });

/** Admin update shop: any shop field + ownerId + isHidden. لا تُحدَّث رسوم التوصيل لكل محل (عامة من المنصة). */
const updateShopByAdminSchema = updateShopSchema.keys({
  isHidden: Joi.boolean(),
  ownerId: joiOptionalObjectId(),
  deliveryFee: Joi.forbidden(),
});

const listShopsQuerySchema = Joi.object({
  isOpen: Joi.boolean(),
  lng: Joi.number().optional(),
  lat: Joi.number().optional(),
  maxDistance: Joi.number().min(0).optional(),
  page: Joi.alternatives().try(Joi.number(), Joi.string()).optional().custom((v) => {
    if (v == null || v === '') return undefined;
    const n = Number(v);
    return Number.isFinite(n) ? n : undefined;
  }),
  limit: Joi.alternatives().try(Joi.number(), Joi.string()).optional().custom((v) => {
    if (v == null || v === '') return undefined;
    const n = Number(v);
    return Number.isFinite(n) ? n : undefined;
  }),
});

const createShopReviewSchema = Joi.object({
  rating: Joi.number().integer().min(1).max(5).required(),
  comment: Joi.string().trim().min(1).max(1000).required(),
});

const listShopReviewsQuerySchema = Joi.object({
  page: Joi.alternatives().try(Joi.number(), Joi.string()).optional().custom((v) => {
    if (v == null || v === '') return undefined;
    const n = Number(v);
    return Number.isFinite(n) ? n : undefined;
  }),
  limit: Joi.alternatives().try(Joi.number(), Joi.string()).optional().custom((v) => {
    if (v == null || v === '') return undefined;
    const n = Number(v);
    return Number.isFinite(n) ? n : undefined;
  }),
});

function validateCreateShop(body) {
  return createShopSchema.validate(body, { abortEarly: false });
}

function validateUpdateShop(body) {
  return updateShopSchema.validate(body, { abortEarly: false });
}

function validateListShopsQuery(query) {
  return listShopsQuerySchema.validate(query, { abortEarly: false });
}

function validateCreateShopReview(body) {
  return createShopReviewSchema.validate(body, { abortEarly: false });
}

function validateListShopReviewsQuery(query) {
  return listShopReviewsQuerySchema.validate(query, { abortEarly: false });
}

function validateCreateShopByAdmin(body) {
  return createShopByAdminSchema.validate(body, { abortEarly: false });
}

function validateUpdateShopByAdmin(body) {
  return updateShopByAdminSchema.validate(body, { abortEarly: false });
}

const bulkOpenHoursSchema = Joi.object({
  from: Joi.string().trim().pattern(/^\d{1,2}:\d{2}$/).required().messages({
    'string.pattern.base': 'صيغة الوقت يجب أن تكون HH:mm (مثال: 09:00)',
  }),
  to: Joi.string().trim().pattern(/^\d{1,2}:\d{2}$/).required().messages({
    'string.pattern.base': 'صيغة الوقت يجب أن تكون HH:mm (مثال: 22:00)',
  }),
});

function validateBulkOpenHours(body) {
  return bulkOpenHoursSchema.validate(body, { abortEarly: false });
}

module.exports = {
  validateCreateShop,
  validateUpdateShop,
  validateListShopsQuery,
  validateCreateShopByAdmin,
  validateUpdateShopByAdmin,
  validateBulkOpenHours,
  validateCreateShopReview,
  validateListShopReviewsQuery,
};
