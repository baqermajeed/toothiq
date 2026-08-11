const express = require('express');
const catalogController = require('../controllers/catalogController');
const { optionalAuthenticate } = require('../middlewares/auth');
const { validateParams } = require('../middlewares/validate');
const { objectIdParam } = require('../validators/common');

const router = express.Router();

router.get('/categories', optionalAuthenticate, catalogController.listCategories);
router.get(
  '/categories/:categoryId',
  optionalAuthenticate,
  validateParams(objectIdParam('categoryId')),
  catalogController.getCategory
);
router.get(
  '/categories/:categoryId/subcategories',
  optionalAuthenticate,
  validateParams(objectIdParam('categoryId')),
  catalogController.listSubcategories
);
router.get(
  '/categories/:categoryId/brands',
  optionalAuthenticate,
  validateParams(objectIdParam('categoryId')),
  catalogController.listBrands
);
router.get('/products', optionalAuthenticate, catalogController.listProducts);

module.exports = router;
