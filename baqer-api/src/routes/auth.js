const express = require('express');
const authController = require('../controllers/authController');
const { authenticate } = require('../middlewares/auth');
const { validateBody } = require('../middlewares/validate');
const uploadUserAvatar = require('../middlewares/uploadUserAvatar');
const {
  validateRegister,
  validateLogin,
  validateGuestRegister,
} = require('../validators/auth');

const router = express.Router();
//j
router.post(
  '/register',
  uploadUserAvatar,
  validateBody(validateRegister),
  authController.register
);

router.post(
  '/guest-register',
  validateBody(validateGuestRegister),
  authController.guestRegister
);

router.post(
  '/login',
  validateBody(validateLogin),
  authController.login
);

router.post('/logout', authenticate, authController.logout);

module.exports = router;
