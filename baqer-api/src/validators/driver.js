const Joi = require('joi');
const { ORDER_STATUS } = require('../config/constants');
const { DRIVER_ORDER_TABS } = require('../config/constants');

const listDriverOrdersQuerySchema = Joi.object({
  tab: Joi.string()
    .valid(...Object.values(DRIVER_ORDER_TABS))
    .required()
    .messages({
      'any.only': 'التبويب يجب أن يكون pending أو in_progress أو picked_up أو completed',
      'any.required': 'معامل tab مطلوب',
    }),
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

const driverUpdateStatusSchema = Joi.object({
  status: Joi.string()
    .valid(ORDER_STATUS.ON_THE_WAY, ORDER_STATUS.DELIVERED, ORDER_STATUS.CANCELED)
    .required(),
});

function validateListDriverOrdersQuery(query) {
  return listDriverOrdersQuerySchema.validate(query, { abortEarly: false });
}

function validateDriverUpdateStatus(body) {
  return driverUpdateStatusSchema.validate(body, { abortEarly: false });
}

module.exports = {
  validateListDriverOrdersQuery,
  validateDriverUpdateStatus,
};
