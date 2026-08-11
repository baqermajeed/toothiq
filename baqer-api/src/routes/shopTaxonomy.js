const express = require('express');
const productTaxonomyController = require('../controllers/productTaxonomyController');
const { authenticate, requireRoles } = require('../middlewares/auth');
const { requireShopOwnerOrAdmin } = require('../middlewares/shopAccess');

const router = express.Router({ mergeParams: true });

router.use(authenticate);
router.use(requireRoles('shop', 'admin'));
router.use(requireShopOwnerOrAdmin);

/** إنشاء براند جديد (عام ضمن تصنيف رئيسي) — لصاحب المحل أو الأدمن */
router.post('/brands', productTaxonomyController.createBrand);

/** إنشاء تصنيف فرعي جديد — لصاحب المحل أو الأدمن */
router.post('/subcategories', productTaxonomyController.createSubcategory);

module.exports = router;
