const env = require('../config/env');

/**
 * التحقق من إصدار التطبيق (legacy) — لا تغييرات على السلوك القديم.
 * GET /api/app-version/check?version=1.1.0
 */
async function checkVersion(req, res, next) {
  try {
    const clientVersion = (req.query.version || '').toString().trim();
    const { minimumVersion, storeUrl, forceUpdate } = env.appUpdate;

    const updateRequired = _isUpdateRequired(clientVersion, minimumVersion);

    res.json({
      success: true,
      data: {
        updateRequired,
        forceUpdate: updateRequired ? forceUpdate : true,
        storeUrl,
        currentVersion: clientVersion || 'unknown',
        minimumVersion,
      },
    });
  } catch (err) {
    next(err);
  }
}

/**
 * التحقق من إصدار التطبيق (v2) — مستقل للتطبيقات الجديدة.
 * GET /api/app-version/check-v2?version=1.1.0&platform=android
 */
async function checkVersionV2(req, res, next) {
  try {
    const clientVersion = (req.query.version || '').toString().trim();
    const { minimumVersion, androidUrl, iosUrl, fallbackUrl, forceUpdate } = env.appUpdateV2;
    const platform = _normalizePlatform(req.query.platform || req.headers['x-device-os']);
    const updateUrl = _resolveUpdateUrl({ platform, androidUrl, iosUrl, fallbackUrl });

    const updateRequired = _isUpdateRequired(clientVersion, minimumVersion);

    res.json({
      success: true,
      data: {
        updateRequired,
        forceUpdate: updateRequired ? forceUpdate : true,
        updateUrl,
        platform,
        currentVersion: clientVersion || 'unknown',
        minimumVersion,
      },
    });
  } catch (err) {
    next(err);
  }
}

/**
 * مقارنة إصدارين (دعم الصيغة 1.2.3 أو 1.2.3+4).
 * يُرجع true إذا كان clientVersion أقل من minimumVersion.
 */
function _isUpdateRequired(clientVersion, minimumVersion) {
  if (!clientVersion || clientVersion === 'unknown') return false;
  const client = _parseVersion(clientVersion);
  const minimum = _parseVersion(minimumVersion);
  if (!client || !minimum) return false;
  for (let i = 0; i < 3; i++) {
    const c = client[i] ?? 0;
    const m = minimum[i] ?? 0;
    if (c < m) return true;
    if (c > m) return false;
  }
  return false;
}

function _parseVersion(v) {
  const s = String(v).split('+')[0].trim();
  const parts = s.split('.').map((x) => parseInt(x, 10));
  if (parts.some((p) => isNaN(p))) return null;
  return parts;
}

function _normalizePlatform(raw) {
  const value = String(raw || '').trim().toLowerCase();
  if (value.includes('ios') || value.includes('iphone') || value.includes('ipad')) return 'ios';
  if (value.includes('android')) return 'android';
  return 'unknown';
}

function _resolveUpdateUrl({ platform, androidUrl, iosUrl, fallbackUrl }) {
  if (platform === 'ios' && iosUrl) return iosUrl;
  if (platform === 'android' && androidUrl) return androidUrl;
  return fallbackUrl || androidUrl || iosUrl || '';
}

module.exports = { checkVersion, checkVersionV2 };
