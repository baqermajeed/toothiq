const bannerService = require('../services/bannerService');

async function list(req, res, next) {
  try {
    const filters = { ...req.query };
    const items = await bannerService.list(filters);
    res.json({ success: true, data: items });
  } catch (err) {
    next(err);
  }
}

module.exports = { list };
