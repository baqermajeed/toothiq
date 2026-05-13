const Joi = require('joi');
const mongoose = require('mongoose');

/**
 * Normalize a single Mongo ObjectId from params/body (string, number, ObjectId, { _id }, { $oid }).
 * @returns {{ empty: true } | { invalid: true } | { id: string }}
 */
function extractObjectIdHex(value) {
  if (value === undefined || value === null || value === '') {
    return { empty: true };
  }
  const raw = Array.isArray(value) ? value[0] : value;
  if (raw == null || raw === '') {
    return { empty: true };
  }
  let part = raw;
  if (typeof part === 'object') {
    if (typeof part.$oid === 'string') {
      part = part.$oid;
    } else if (part._id != null) {
      part = part._id;
    }
  }
  if (part == null || part === '') {
    return { empty: true };
  }
  const s = typeof part === 'string' ? part.trim() : String(part).trim();
  if (!s || s === '[object Object]') {
    return { invalid: true };
  }
  if (!mongoose.Types.ObjectId.isValid(s)) {
    return { invalid: true };
  }
  return { id: s };
}

function joiRequiredObjectId() {
  return Joi.any()
    .required()
    .custom((value, helpers) => {
      const r = extractObjectIdHex(value);
      if (r.empty) {
        return helpers.error('any.required');
      }
      if (r.invalid) {
        return helpers.error('any.invalid');
      }
      return r.id;
    });
}

function joiOptionalObjectId() {
  return Joi.any()
    .optional()
    .custom((value, helpers) => {
      const r = extractObjectIdHex(value);
      if (r.empty) {
        return undefined;
      }
      if (r.invalid) {
        return helpers.error('any.invalid');
      }
      return r.id;
    });
}

function objectIdParam(field) {
  return (params) => {
    const schema = Joi.object({
      [field]: joiRequiredObjectId(),
    });
    return schema.validate(params, { abortEarly: false });
  };
}

function shopIdAndIdParams(params) {
  const schema = Joi.object({
    shopId: joiRequiredObjectId(),
    id: joiRequiredObjectId(),
  });
  return schema.validate(params, { abortEarly: false });
}

module.exports = {
  objectIdParam,
  shopIdAndIdParams,
  extractObjectIdHex,
  joiOptionalObjectId,
};
