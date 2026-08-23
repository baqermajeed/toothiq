const express = require('express');
const productController = require('../controllers/productController');
const { authenticate, optionalAuthenticate, requireRoles } = require('../middlewares/auth');
const { validateParams } = require('../middlewares/validate');
const { shopIdAndIdParams, objectIdParam } = require('../validators/common');
const uploadProductImage = require('../middlewares/uploadProductImage');

const router = express.Router({ mergeParams: true });

router.get('/', optionalAuthenticate, productController.list);

router.get(
  '/best-sellers',
  optionalAuthenticate,
  productController.listBestSellers
);

router.get(
  '/missing-images',
  authenticate,
  requireRoles('shop', 'admin'),
  productController.listMissingImages
);

router.post(
  '/bulk',
  authenticate,
  requireRoles('shop', 'admin'),
  productController.bulkCreate
);

router.post(
  '/bulk-with-categories',
  authenticate,
  requireRoles('shop', 'admin'),
  productController.bulkCreateWithCategories
);

router.post(
  '/import',
  authenticate,
  requireRoles('shop', 'admin'),
  validateParams(objectIdParam('shopId')),
  productController.importMapped
);

router.post(
  '/copy-from',
  authenticate,
  requireRoles('admin'),
  productController.copyFromShop
);

router.get(
  '/:id',
  optionalAuthenticate,
  validateParams(shopIdAndIdParams),
  productController.getById
);

router.get(
  '/:id/recommendations',
  optionalAuthenticate,
  validateParams(shopIdAndIdParams),
  productController.getRecommendations
);

router.post(
  '/',
  authenticate,
  requireRoles('shop', 'admin'),
  uploadProductImage,
  productController.create
);

router.patch(
  '/:id',
  authenticate,
  requireRoles('shop', 'admin'),
  validateParams(shopIdAndIdParams),
  uploadProductImage,
  productController.updateById
);

router.delete(
  '/:id',
  authenticate,
  requireRoles('shop', 'admin'),
  validateParams(shopIdAndIdParams),
  productController.remove
);

module.exports = router;
