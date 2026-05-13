/**
 * يحدد نظام التشغيل من الطلب (User-Agent أو الهيدر X-Platform).
 * @param {object} req - كائن الطلب Express
 * @returns {{ platform: 'android' | 'ios' | 'unknown' }}
 */
function detectPlatform(req) {
  const headers = req.headers || {};
  const userAgent = (headers['user-agent'] || '').toLowerCase();

  // إذا أرسل العميل الهيدر صراحة نعتمد عليه (مثلاً من تطبيق Flutter)
  const explicitPlatform = (headers['x-platform'] || headers['x-app-platform'] || '').toLowerCase().trim();
  if (explicitPlatform === 'android') return { platform: 'android' };
  if (explicitPlatform === 'ios') return { platform: 'ios' };

  // الكشف من User-Agent
  if (/android/.test(userAgent)) return { platform: 'android' };
  if (/iphone|ipad|ipod/.test(userAgent)) return { platform: 'ios' };

  return { platform: 'unknown' };
}

module.exports = { detectPlatform };
