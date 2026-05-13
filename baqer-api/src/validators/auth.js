const Joi = require('joi');
const { ROLES } = require('../config/constants');
const { GOVERNORATE_IDS } = require('../config/iraqGovernorates');

const registerSchema = Joi.object({
  name: Joi.string()
    .trim()
    .min(1)
    .max(200)
    .required()
    .messages({
      'string.empty': 'الاسم مطلوب.',
      'any.required': 'الاسم مطلوب.',
    }),
  phone: Joi.string()
    .trim()
    .pattern(/^[0-9\u0660-\u0669]{11}$/)
    .required()
    .messages({
      'string.pattern.base': 'رقم الهاتف يجب أن يكون مكوناً من ١١ رقم.',
      'string.empty': 'رقم الهاتف مطلوب.',
      'any.required': 'رقم الهاتف مطلوب.',
    }),
  /** معرف محافظة من القائمة العراقية — انظر GET /api/governorates */
  governorateId: Joi.string()
    .trim()
    .valid(...GOVERNORATE_IDS)
    .required()
    .messages({
      'any.only': 'المحافظة غير صالحة. استخدم معرفاً من قائمة المحافظات.',
      'any.required': 'المحافظة مطلوبة.',
      'string.empty': 'المحافظة مطلوبة.',
    }),
  clinicName: Joi.string().trim().max(200).allow('', null),
  email: Joi.string().trim().email().allow('', null),
  password: Joi.string()
    .min(8)
    .max(128)
    .required()
    .messages({
      'string.min': 'كلمة المرور يجب أن تكون 8 أحرف على الأقل.',
      'string.empty': 'كلمة المرور مطلوبة.',
      'any.required': 'كلمة المرور مطلوبة.',
    }),
  /** يُعبَّأ تلقائياً عند رفع صورة ضمن multipart تحت الحقل avatar */
  avatar: Joi.string().trim().allow('', null),
  role: Joi.string()
    .valid(ROLES.CUSTOMER, ROLES.SHOP)
    .default(ROLES.CUSTOMER),
  location: Joi.object({
    type: Joi.string().valid('Point').default('Point'),
    coordinates: Joi.array().items(Joi.number()).length(2).required(),
  }).optional(),
});

const loginSchema = Joi.object({
  phone: Joi.string()
    .trim()
    .pattern(/^[0-9\u0660-\u0669]{11}$/)
    .required()
    .messages({
      'string.pattern.base': 'رقم الهاتف يجب أن يكون مكوناً من ١١ رقم.',
      'string.empty': 'رقم الهاتف مطلوب.',
      'any.required': 'رقم الهاتف مطلوب.',
    }),
  password: Joi.string()
    .required()
    .messages({
      'string.empty': 'كلمة المرور مطلوبة.',
      'any.required': 'كلمة المرور مطلوبة.',
    }),
  location: Joi.object({
    type: Joi.string().valid('Point').default('Point'),
    coordinates: Joi.array().items(Joi.number()).length(2).required(),
  }).optional(),
});

const guestRegisterSchema = Joi.object({
  name: Joi.string().trim().min(1).max(200).required(),
  phone: Joi.string()
    .trim()
    .pattern(/^[0-9\u0660-\u0669]{11}$/)
    .required()
    .messages({
      'string.pattern.base': 'رقم الهاتف يجب أن يكون مكوناً من ١١ رقم.',
      'string.empty': 'رقم الهاتف مطلوب.',
      'any.required': 'رقم الهاتف مطلوب.',
    }),
  location: Joi.object({
    type: Joi.string().valid('Point').default('Point'),
    coordinates: Joi.array().items(Joi.number()).length(2).required(),
  }).optional(),
});

function validateRegister(body) {
  return registerSchema.validate(body, { abortEarly: false });
}

function validateLogin(body) {
  return loginSchema.validate(body, { abortEarly: false });
}

function validateGuestRegister(body) {
  return guestRegisterSchema.validate(body, { abortEarly: false });
}

module.exports = {
  validateRegister,
  validateLogin,
  validateGuestRegister,
};
