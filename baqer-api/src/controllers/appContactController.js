const { getPublicContactPayload } = require('../services/platformSettingsService');

async function getPublic(req, res, next) {
  try {
    const data = await getPublicContactPayload();
    res.json({ success: true, data });
  } catch (err) {
    next(err);
  }
}

module.exports = { getPublic };
