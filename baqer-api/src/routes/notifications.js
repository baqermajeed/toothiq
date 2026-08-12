const express = require('express');
const notificationController = require('../controllers/notificationController');
const { authenticate } = require('../middlewares/auth');
const { validateParams } = require('../middlewares/validate');
const { objectIdParam } = require('../validators/common');

const router = express.Router();

router.use(authenticate);

router.get('/', notificationController.list);
router.get('/unread-count', notificationController.unreadCount);
router.patch('/read-all', notificationController.markAllAsRead);
router.patch(
  '/:id/read',
  validateParams(objectIdParam('id')),
  notificationController.markAsRead
);

module.exports = router;
