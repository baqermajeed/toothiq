const express = require('express');
const driverController = require('../controllers/driverController');
const { authenticate, requireRoles } = require('../middlewares/auth');
const { validateBody, validateQuery, validateParams } = require('../middlewares/validate');
const { validateListDriverOrdersQuery, validateDriverUpdateStatus } = require('../validators/driver');
const { objectIdParam } = require('../validators/common');

const router = express.Router();

router.use(authenticate);
router.use(requireRoles('driver'));

router.get('/orders/counts', driverController.getCounts);

router.get(
  '/orders',
  validateQuery(validateListDriverOrdersQuery),
  driverController.listOrders
);

router.get(
  '/orders/:id',
  validateParams(objectIdParam('id')),
  driverController.getById
);

router.post(
  '/orders/:id/accept',
  validateParams(objectIdParam('id')),
  driverController.acceptOrder
);

router.patch(
  '/orders/:id/status',
  validateParams(objectIdParam('id')),
  validateBody(validateDriverUpdateStatus),
  driverController.updateStatus
);

router.get('/wallet', driverController.getWallet);
router.get('/wallet/transactions', driverController.getWalletTransactions);

module.exports = router;
