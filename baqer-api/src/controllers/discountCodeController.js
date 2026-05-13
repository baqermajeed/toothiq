const orderService = require('../services/orderService');

async function quote(req, res, next) {
  try {
    const data = await orderService.quoteDiscountForCart(req.body);
    res.json({ success: true, data });
  } catch (err) {
    next(err);
  }
}

module.exports = { quote };
