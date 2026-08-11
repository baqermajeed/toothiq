const Joi = require('joi');
const { ORDER_STATUS } = require('../config/constants');

const orderItemSchema = Joi.object({
  productId: Joi.string().required(),
  name: Joi.string().trim().required(),
  price: Joi.number().min(0).required(),
  quantity: Joi.number().integer().min(1).required(),
});

const deliveryLocationSchema = Joi.object({
  type: Joi.string().valid('Point').default('Point'),
  coordinates: Joi.array().items(Joi.number()).length(2).required(),
}).required();

const shopPortionSchema = Joi.object({
  shopId: Joi.string().required(),
  items: Joi.array().items(orderItemSchema).min(1).required(),
});

const createOrderSchema = Joi.object({
  shopPortions: Joi.array().items(shopPortionSchema).min(1),
  shopId: Joi.string(),
  items: Joi.array().items(orderItemSchema),
  fixedNumber: Joi.number().valid(10),
  deliveryLocation: deliveryLocationSchema,
  deliveryAddress: Joi.string().trim().max(500).allow('', null),
  notes: Joi.string().trim().allow(''),
  notesAudioUrl: Joi.string().trim().uri({ allowRelative: true }).allow('', null),
  discountCode: Joi.string().trim().max(32).allow('', null),
}).xor('shopPortions', 'shopId').with('shopId', 'items').messages({
  'object.xor': 'يجب توفير shopPortions أو shopId مع items',
  'object.with': 'shopId يتطلب items',
});

const createVoiceOrderSchema = Joi.object({
  shopId: Joi.string().allow(null),
  deliveryLocation: Joi.object({
    type: Joi.string().valid('Point').default('Point'),
    coordinates: Joi.array().items(Joi.number()).length(2).required(),
  }).required(),
  deliveryAddress: Joi.string().trim().max(500).allow('', null),
  notesAudioUrl: Joi.string().trim().uri({ allowRelative: true }).required(),
});

const updateStatusSchema = Joi.object({
  status: Joi.string()
    .valid(...Object.values(ORDER_STATUS))
    .required(),
  cancelReason: Joi.string().trim().allow(''),
  postponedReason: Joi.string().trim().allow(''),
}).min(1);

const listOrdersQuerySchema = Joi.object({
  scope: Joi.string().valid('all').optional(),
  status: Joi.string().valid(...Object.values(ORDER_STATUS)),
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
  fromDate: Joi.string().optional().allow('', null),
  toDate: Joi.string().optional().allow('', null),
  search: Joi.string().optional().allow('', null).max(100),
  duplicateOnly: Joi.string().valid('1', 'true').optional(),
});

function validateCreateOrder(body) {
  return createOrderSchema.validate(body, { abortEarly: false });
}

function validateCreateVoiceOrder(body) {
  return createVoiceOrderSchema.validate(body, { abortEarly: false });
}

function validateUpdateStatus(body) {
  return updateStatusSchema.validate(body, { abortEarly: false });
}

function validateListOrdersQuery(query) {
  return listOrdersQuerySchema.validate(query, { abortEarly: false });
}

module.exports = {
  validateCreateOrder,
  validateCreateVoiceOrder,
  validateUpdateStatus,
  validateListOrdersQuery,
  orderItemSchema,
  shopPortionSchema,
};
