const { getPlatformSettings } = require('../services/platformSettingsService');

async function getAppSettings(req, res, next) {
  try {
    const s = await getPlatformSettings();
    res.json({
      success: true,
      data: {
        deliveryEnabled: s.deliveryEnabled,
        deliveryPauseReason: s.deliveryPauseReason,
        globalDeliveryFee: Number(s.globalDeliveryFee) || 0,
        deliveryFee: Number(s.globalDeliveryFee) || 0,
        supportPhone: s.supportPhone,
        facebookUrl: s.facebookUrl,
        instagramUrl: s.instagramUrl,
        aboutUs: s.aboutUs,
      },
    });
  } catch (err) {
    next(err);
  }
}

module.exports = { getAppSettings };
