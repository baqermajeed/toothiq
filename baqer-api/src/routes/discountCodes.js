const express = require('express');
const discountCodeController = require('../controllers/discountCodeController');
const { authenticate } = require('../middlewares/auth');
const { validateBody } = require('../middlewares/validate');
const { validateQuoteDiscount } = require('../validators/discountCodes');

const router = express.Router();

router.post(
  '/quote',
  authenticate,
  validateBody(validateQuoteDiscount),
  discountCodeController.quote
);

module.exports = router;
