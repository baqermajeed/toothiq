const { badRequest } = require('../utils/errors');

function validate(schema, source = 'body') {
  return (req, res, next) => {
    const data = source === 'body' ? req.body : source === 'query' ? req.query : req.params;
    const result = typeof schema.validate === 'function'
      ? schema.validate(data, { abortEarly: false, stripUnknown: true })
      : schema(data);
    const { error, value } = result;
    if (error) {
      const message = error.details ? error.details.map((d) => d.message).join('; ') : error.message;
      return next(badRequest(message, 'VALIDATION_ERROR'));
    }
    if (source === 'body') {
      req.body = value;
    } else if (source === 'query') {
      // الحفاظ على معاملات أخرى في الرابط (مثل q, page) غير المذكورة في المخطط
      Object.assign(req.query, value);
    } else {
      // مسارات مثل /api/shops/:shopId/products/:id — التحقق من id فقط يجب ألا يحذف shopId
      Object.assign(req.params, value);
    }
    next();
  };
}

function validateBody(schema) {
  return validate(schema, 'body');
}

function validateQuery(schema) {
  return validate(schema, 'query');
}

function validateParams(schema) {
  return validate(schema, 'params');
}

module.exports = { validate, validateBody, validateQuery, validateParams };
