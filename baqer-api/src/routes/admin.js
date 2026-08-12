const express = require('express');
const adminController = require('../controllers/adminController');
const categoryController = require('../controllers/categoryController');
const productTaxonomyController = require('../controllers/productTaxonomyController');
const bannerAdminController = require('../controllers/bannerAdminController');
const { authenticate, requireRoles } = require('../middlewares/auth');
const { validateBody, validateParams } = require('../middlewares/validate');
const { objectIdParam } = require('../validators/common');
const { validateUpdateUserByAdmin, validateCreateUserByAdmin } = require('../validators/users');
const { validateCreateShopByAdmin, validateUpdateShopByAdmin, validateBulkOpenHours } = require('../validators/shops');
const {
  validateCreateCategory,
  validateUpdateCategory,
  validateReorderCategories,
} = require('../validators/categories');
const { validateUpdateStatus } = require('../validators/orders');
const {
  validateCreateDiscountCodeAdmin,
  validateUpdateDiscountCodeAdmin,
} = require('../validators/discountCodes');
const discountCodeAdminController = require('../controllers/discountCodeAdminController');
const uploadShopImage = require('../middlewares/uploadShopImage');
const uploadBannerImage = require('../middlewares/uploadBannerImage');
const uploadCategoryIcon = require('../middlewares/uploadCategoryIcon');
const uploadBrandImage = require('../middlewares/uploadBrandImage');

const router = express.Router();

router.use(authenticate);
router.use(requireRoles('admin'));

router.get('/discount-codes', discountCodeAdminController.list);
router.post(
  '/discount-codes',
  validateBody((body) => validateCreateDiscountCodeAdmin(body)),
  discountCodeAdminController.create
);
router.patch(
  '/discount-codes/:id',
  validateParams(objectIdParam('id')),
  validateBody((body) => validateUpdateDiscountCodeAdmin(body)),
  discountCodeAdminController.update
);
router.delete(
  '/discount-codes/:id',
  validateParams(objectIdParam('id')),
  discountCodeAdminController.remove
);

router.get('/settings', adminController.getSettings);
router.patch(
  '/settings',
  validateBody((body) => {
    const Joi = require('joi');
    return Joi.object({
      deliveryEnabled: Joi.boolean(),
      deliveryPauseReason: Joi.string().allow('').max(2000),
      globalDeliveryFee: Joi.number().min(0),
      facebookUrl: Joi.string().trim().allow('').max(500),
      instagramUrl: Joi.string().trim().allow('').max(500),
      supportPhone: Joi.string().trim().allow('').max(30),
      aboutUs: Joi.string().trim().allow('').max(20000),
    })
      .or(
        'deliveryEnabled',
        'deliveryPauseReason',
        'globalDeliveryFee',
        'facebookUrl',
        'instagramUrl',
        'supportPhone',
        'aboutUs'
      )
      .validate(body, { abortEarly: false });
  }),
  adminController.updateSettings
);

router.get('/users', adminController.listUsers);
router.get(
  '/users/:id',
  validateParams(objectIdParam('id')),
  adminController.getUserById
);
router.get('/shops', adminController.listShops);
router.get('/products', adminController.listProducts);
router.get('/orders', adminController.listOrders);
router.post(
  '/orders/deliver-stale-on-the-way-silent',
  adminController.deliverStaleOnTheWaySilent
);
router.get('/orders/stats', adminController.getOrdersStats);
router.get(
  '/orders/:id',
  validateParams(objectIdParam('id')),
  adminController.getOrderById
);
router.patch(
  '/orders/:id/status',
  validateParams(objectIdParam('id')),
  validateBody(validateUpdateStatus),
  adminController.updateOrderStatus
);
router.delete(
  '/orders/:id',
  validateParams(objectIdParam('id')),
  adminController.deleteOrder
);
router.get('/stats', adminController.getStats);
router.get('/categories', categoryController.listAdmin);
router.get('/product-taxonomy', productTaxonomyController.list);
router.patch(
  '/categories/reorder',
  validateBody(validateReorderCategories),
  categoryController.reorder
);
router.post(
  '/categories',
  uploadCategoryIcon,
  validateBody(validateCreateCategory),
  categoryController.create
);
router.patch(
  '/categories/:id',
  validateParams(objectIdParam('id')),
  uploadCategoryIcon,
  validateBody(validateUpdateCategory),
  categoryController.update
);
router.delete(
  '/categories/:id',
  validateParams(objectIdParam('id')),
  categoryController.remove
);
router.post('/product-subcategories', productTaxonomyController.createSubcategory);
router.patch(
  '/product-subcategories/:id',
  validateParams(objectIdParam('id')),
  productTaxonomyController.updateSubcategory
);
router.delete(
  '/product-subcategories/:id',
  validateParams(objectIdParam('id')),
  productTaxonomyController.removeSubcategory
);
router.post('/brands', uploadBrandImage, productTaxonomyController.createBrand);
router.patch(
  '/brands/:id',
  validateParams(objectIdParam('id')),
  uploadBrandImage,
  productTaxonomyController.updateBrand
);
router.delete(
  '/brands/:id',
  validateParams(objectIdParam('id')),
  productTaxonomyController.removeBrand
);

router.post(
  '/users',
  validateBody(validateCreateUserByAdmin),
  adminController.createUser
);

router.post(
  '/shops',
  uploadShopImage,
  adminController.createShop
);

router.post(
  '/shops/reorder',
  validateBody((body) => {
    const Joi = require('joi');
    return Joi.object({
      shopIds: Joi.array().items(Joi.string().trim().required()).min(1).required(),
    }).validate(body, { abortEarly: false });
  }),
  adminController.reorderShops
);

router.patch(
  '/shops/bulk-open-hours',
  validateBody(validateBulkOpenHours),
  adminController.bulkUpdateShopsOpenHours
);

router.patch(
  '/shops/:id',
  validateParams(objectIdParam('id')),
  uploadShopImage,
  adminController.updateShop
);

router.delete(
  '/shops/:id',
  validateParams(objectIdParam('id')),
  adminController.deleteShop
);

router.patch(
  '/users/:id/active',
  validateParams(objectIdParam('id')),
  validateBody((body) => {
    const Joi = require('joi');
    return Joi.object({ isActive: Joi.boolean().required() }).validate(body, { abortEarly: false });
  }),
  adminController.setUserActive
);

router.patch(
  '/users/:id',
  validateParams(objectIdParam('id')),
  validateBody(validateUpdateUserByAdmin),
  adminController.updateUser
);

router.delete(
  '/users/:id',
  validateParams(objectIdParam('id')),
  adminController.deleteUser
);

router.get(
  '/drivers/:driverId/wallet',
  validateParams(objectIdParam('driverId')),
  adminController.getDriverWallet
);
router.post(
  '/drivers/:driverId/wallet/collect',
  validateParams(objectIdParam('driverId')),
  validateBody((body) => {
    const Joi = require('joi');
    return Joi.object({
      amount: Joi.number().positive().required(),
    }).validate(body, { abortEarly: false });
  }),
  adminController.collectDriverWallet
);

router.get('/banners', bannerAdminController.list);
router.post('/banners', uploadBannerImage, bannerAdminController.create);
router.patch(
  '/banners/:id',
  validateParams(objectIdParam('id')),
  uploadBannerImage,
  bannerAdminController.update
);
router.delete(
  '/banners/:id',
  validateParams(objectIdParam('id')),
  bannerAdminController.remove
);

router.post('/notifications/broadcast', adminController.broadcastNotification);

module.exports = router;
