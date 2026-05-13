const discountCodeService = require('../services/discountCodeService');
const { badRequest } = require('../utils/errors');
const {
  validateCreateDiscountCodeAdmin,
  validateUpdateDiscountCodeAdmin,
} = require('../validators/discountCodes');

async function list(req, res, next) {
  try {
    const items = await discountCodeService.listForAdmin();
    res.json({ success: true, data: items });
  } catch (err) {
    next(err);
  }
}

async function create(req, res, next) {
  try {
    const { error, value } = validateCreateDiscountCodeAdmin(req.body);
    if (error) {
      const message = error.details ? error.details.map((d) => d.message).join('; ') : error.message;
      return next(badRequest(message, 'VALIDATION_ERROR'));
    }
    const doc = await discountCodeService.createForAdmin(value);
    res.status(201).json({ success: true, data: doc });
  } catch (err) {
    next(err);
  }
}

async function update(req, res, next) {
  try {
    const { error, value } = validateUpdateDiscountCodeAdmin(req.body);
    if (error) {
      const message = error.details ? error.details.map((d) => d.message).join('; ') : error.message;
      return next(badRequest(message, 'VALIDATION_ERROR'));
    }
    const doc = await discountCodeService.updateForAdmin(req.params.id, value);
    res.json({ success: true, data: doc });
  } catch (err) {
    next(err);
  }
}

async function remove(req, res, next) {
  try {
    await discountCodeService.removeForAdmin(req.params.id);
    res.json({ success: true, data: { deleted: true } });
  } catch (err) {
    next(err);
  }
}

module.exports = { list, create, update, remove };
