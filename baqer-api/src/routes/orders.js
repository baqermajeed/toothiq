const express = require('express');
const orderController = require('../controllers/orderController');
const { authenticate, requireRoles } = require('../middlewares/auth');
const { validateBody, validateQuery, validateParams } = require('../middlewares/validate');
const uploadOrderNoteAudio = require('../middlewares/uploadOrderNoteAudio');
const {
  validateCreateOrder,
  validateCreateVoiceOrder,
  validateUpdateStatus,
  validateListOrdersQuery,
} = require('../validators/orders');
const { objectIdParam } = require('../validators/common');

const router = express.Router();

router.get(
  '/',
  authenticate,
  validateQuery(validateListOrdersQuery),
  orderController.list
);

router.post(
  '/',
  authenticate,
  validateBody(validateCreateOrder),
  orderController.create
);

router.post(
  '/voice',
  authenticate,
  validateBody(validateCreateVoiceOrder),
  orderController.createVoiceOrder
);

router.post(
  '/note-audio',
  authenticate,
  (req, res, next) => {
    uploadOrderNoteAudio(req, res, (err) => {
      if (err) {
        return next(err);
      }
      next();
    });
  },
  orderController.uploadNoteAudio
);

router.get(
  '/:id/call-targets',
  authenticate,
  validateParams(objectIdParam('id')),
  orderController.getCallTargets
);

router.get(
  '/:id',
  authenticate,
  validateParams(objectIdParam('id')),
  orderController.getById
);

router.patch(
  '/:id/status',
  authenticate,
  validateParams(objectIdParam('id')),
  validateBody(validateUpdateStatus),
  orderController.updateStatus
);

router.patch(
  '/:id/cancel',
  authenticate,
  requireRoles('customer'),
  validateParams(objectIdParam('id')),
  orderController.cancelByCustomer
);

module.exports = router;
