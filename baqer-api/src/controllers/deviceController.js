const deviceService = require('../services/deviceService');

const STORE_URLS = {
  android: 'http://play.google.com/store/apps/details?id=com.infinty.qareep',
  ios: 'https://apps.apple.com/app/id6758707253',
};

/**
 * يحدد نظام التشغيل من الطلب ويحوّل المستخدم لرابط التطبيق في المتجر المناسب.
 * Android → Google Play | iOS → App Store | غير معروف → Google Play افتراضياً
 */
function getPlatform(req, res, next) {
  try {
    const { platform } = deviceService.detectPlatform(req);
    const url = platform === 'ios' ? STORE_URLS.ios : STORE_URLS.android;
    res.redirect(302, url);
  } catch (err) {
    next(err);
  }
}

module.exports = { getPlatform };
