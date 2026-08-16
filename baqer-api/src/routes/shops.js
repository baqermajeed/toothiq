const express = require('express');
const homeFeedController = require('../controllers/homeFeedController');
const shopController = require('../controllers/shopController');
const { authenticate, optionalAuthenticate, requireRoles } = require('../middlewares/auth');
const { validateQuery, validateParams } = require('../middlewares/validate');
const { validateListShopsQuery, validateListShopReviewsQuery } = require('../validators/shops');
const { objectIdParam } = require('../validators/common');
const uploadShopImage = require('../middlewares/uploadShopImage');

const router = express.Router();

router.get('/top-rated', optionalAuthenticate, homeFeedController.topRated);

router.get(
  '/',
  optionalAuthenticate,
  validateQuery(validateListShopsQuery),
  shopController.list
);

router.get(
  '/my-shop',
  authenticate,
  requireRoles('shop'),
  shopController.getMyShop
);

router.get(
  '/:id',
  validateParams(objectIdParam('id')),
  shopController.getById
);

router.post(
  '/',
  authenticate,
  requireRoles('shop', 'admin'),
  uploadShopImage,
  shopController.create
);

router.patch(
  '/:id',
  authenticate,
  requireRoles('shop', 'admin'),
  validateParams(objectIdParam('id')),
  uploadShopImage,
  shopController.updateById
);

router.get(
  '/:id/reviews',
  validateParams(objectIdParam('id')),
  validateQuery(validateListShopReviewsQuery),
  shopController.listReviews
);

router.post(
  '/:id/reviews',
  authenticate,
  validateParams(objectIdParam('id')),
  shopController.createReview
);

module.exports = router;
