const express = require('express');
const userController = require('../controllers/userController');
const { authenticate } = require('../middlewares/auth');
const { validateBody } = require('../middlewares/validate');
const { validateUpdateMe } = require('../validators/users');
const uploadUserAvatar = require('../middlewares/uploadUserAvatar');

const router = express.Router();

router.use(authenticate);

router.get('/me', userController.getMe);
router.patch('/me', uploadUserAvatar, validateBody(validateUpdateMe), userController.updateMe);

module.exports = router;
