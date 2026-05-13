const Joi = require('joi');
const taxonomyService = require('../services/productTaxonomyService');
const { badRequest } = require('../utils/errors');

const createSchema = Joi.object({
  categoryId: Joi.string().trim().required(),
  nameAr: Joi.string().trim().min(1).max(100).required(),
  order: Joi.number().integer().min(0).default(0),
  isActive: Joi.boolean().default(true),
});

const updateSchema = Joi.object({
  categoryId: Joi.string().trim(),
  nameAr: Joi.string().trim().min(1).max(100),
  order: Joi.number().integer().min(0),
  isActive: Joi.boolean(),
}).min(1);

function validate(schema, body) {
  const { error, value } = schema.validate(body, { abortEarly: false });
  if (error) {
    const message = error.details ? error.details.map((d) => d.message).join('; ') : error.message;
    throw badRequest(message, 'VALIDATION_ERROR');
  }
  return value;
}

async function list(req, res, next) {
  try {
    const data = await taxonomyService.listAll();
    res.json({ success: true, data });
  } catch (err) {
    next(err);
  }
}

async function createSubcategory(req, res, next) {
  try {
    const value = validate(createSchema, req.body);
    const item = await taxonomyService.createSubcategory(value);
    res.status(201).json({ success: true, data: item });
  } catch (err) {
    next(err);
  }
}

async function updateSubcategory(req, res, next) {
  try {
    const value = validate(updateSchema, req.body);
    const item = await taxonomyService.updateSubcategory(req.params.id, value);
    res.json({ success: true, data: item });
  } catch (err) {
    next(err);
  }
}

async function removeSubcategory(req, res, next) {
  try {
    const data = await taxonomyService.removeSubcategory(req.params.id);
    res.json({ success: true, data });
  } catch (err) {
    next(err);
  }
}

async function createBrand(req, res, next) {
  try {
    const value = validate(createSchema, req.body);
    const item = await taxonomyService.createBrand(value);
    res.status(201).json({ success: true, data: item });
  } catch (err) {
    next(err);
  }
}

async function updateBrand(req, res, next) {
  try {
    const value = validate(updateSchema, req.body);
    const item = await taxonomyService.updateBrand(req.params.id, value);
    res.json({ success: true, data: item });
  } catch (err) {
    next(err);
  }
}

async function removeBrand(req, res, next) {
  try {
    const data = await taxonomyService.removeBrand(req.params.id);
    res.json({ success: true, data });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  list,
  createSubcategory,
  updateSubcategory,
  removeSubcategory,
  createBrand,
  updateBrand,
  removeBrand,
};
