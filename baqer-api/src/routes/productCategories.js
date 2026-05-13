const express = require('express');
const productCategoryController = require('../controllers/productCategoryController');
const { authenticate, requireRoles } = require('../middlewares/auth');
const { validateParams, validateBody } = require('../middlewares/validate');
const { objectIdParam } = require('../validators/common');
const uploadProductCategoryImage = require('../middlewares/uploadProductCategoryImage');
const {
  validateCreateProductCategory,
  validateUpdateProductCategory,
  validateReorderBody,
} = require('../validators/productCategories');

const router = express.Router({ mergeParams: true });

router.get('/', productCategoryController.list);

router.put(
  '/reorder',
  authenticate,
  requireRoles('shop', 'admin'),
  validateBody(validateReorderBody),
  productCategoryController.reorder
);

router.post(
  '/bulk',
  authenticate,
  requireRoles('shop', 'admin'),
  productCategoryController.bulkCreate
);

router.post(
  '/',
  authenticate,
  requireRoles('shop', 'admin'),
  uploadProductCategoryImage,
  validateBody(validateCreateProductCategory),
  productCategoryController.create
);

router.get(
  '/:id',
  validateParams(objectIdParam('id')),
  productCategoryController.getById
);

router.patch(
  '/:id',
  authenticate,
  requireRoles('shop', 'admin'),
  uploadProductCategoryImage,
  validateParams(objectIdParam('id')),
  validateBody(validateUpdateProductCategory),
  productCategoryController.update
);

router.delete(
  '/:id',
  authenticate,
  requireRoles('shop', 'admin'),
  validateParams(objectIdParam('id')),
  productCategoryController.remove
);

module.exports = router;
