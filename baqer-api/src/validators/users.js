const Joi = require('joi');
const mongoose = require('mongoose');
const { ROLES } = require('../config/constants');
const { GOVERNORATE_IDS } = require('../config/iraqGovernorates');

const updateMeSchema = Joi.object({
  name: Joi.string().trim().min(1).max(200),
  email: Joi.string().trim().email().allow('', null),
  avatar: Joi.string().trim().allow('', null),
  governorateId: Joi.string().trim().valid(...GOVERNORATE_IDS),
  clinicName: Joi.string().trim().max(200).allow('', null),
  location: Joi.object({
    type: Joi.string().valid('Point').default('Point'),
    coordinates: Joi.array().items(Joi.number()).length(2).required(),
  }),
  fcmToken: Joi.string().trim().allow(null),
}).min(1);

const objectIdSchema = Joi.string().custom((value, helpers) => {
  if (!mongoose.Types.ObjectId.isValid(value)) return helpers.error('any.invalid');
  return value;
});

const updateUserByAdminSchema = Joi.object({
  name: Joi.string().trim().min(1).max(200),
  phone: Joi.string()
    .trim()
    .pattern(/^[0-9\u0660-\u0669]{11}$/)
    .messages({
      'string.pattern.base': 'رقم الهاتف يجب أن يكون مكوناً من ١١ رقم.',
    }),
  email: Joi.string().trim().email().allow('', null),
  roles: Joi.array().items(Joi.string().valid(...Object.values(ROLES))).min(1),
}).min(1);

const createUserByAdminSchema = Joi.object({
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
  email: Joi.string().trim().email().allow('', null),
  password: Joi.string().min(8).max(128).required(),
  governorateId: Joi.string().trim().valid(...GOVERNORATE_IDS).allow(null, ''),
  clinicName: Joi.string().trim().max(200).allow('', null),
  roles: Joi.array()
    .items(Joi.string().valid(...Object.values(ROLES)))
    .min(1)
    .default([ROLES.SHOP]),
});

function validateUpdateMe(body) {
  return updateMeSchema.validate(body, { abortEarly: false });
}

function validateUpdateUserByAdmin(body) {
  return updateUserByAdminSchema.validate(body, { abortEarly: false });
}

function validateCreateUserByAdmin(body) {
  return createUserByAdminSchema.validate(body, { abortEarly: false });
}

module.exports = {
  validateUpdateMe,
  validateUpdateUserByAdmin,
  validateCreateUserByAdmin,
  objectIdSchema,
};
