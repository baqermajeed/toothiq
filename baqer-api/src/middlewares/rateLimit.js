const rateLimit = require('express-rate-limit');
const env = require('../config/env');
const { verifyAccess } = require('../utils/tokens');

const noOp = (req, res, next) => next();

/**
 * مفتاح الـ rate limit: للمستخدمين المصادقين نستخدم userId، وإلا نستخدم IP.
 * هذا يمنع ثغرة "شخص واحد ينفذ طلبات كثيرة فيحظر كل من يشاركه نفس الـ IP".
 */
function generalKeyGenerator(req) {
  const authHeader = req.headers.authorization;
  if (authHeader && authHeader.startsWith('Bearer ')) {
    try {
      const decoded = verifyAccess(authHeader.slice(7));
      if (decoded && decoded.userId) return `user:${decoded.userId}`;
    } catch (_) {
      // توكن منتهي أو غير صالح — نستخدم IP
    }
  }
  return req.ip || 'unknown';
}

const general = env.rateLimit.enabled
  ? rateLimit({
      windowMs: env.rateLimit.windowMs,
      max: env.rateLimit.max,
      keyGenerator: generalKeyGenerator,
      message: { success: false, error: { code: 'TOO_MANY_REQUESTS', message: 'Too many requests' } },
      standardHeaders: true,
      legacyHeaders: false,
    })
  : noOp;

const auth = env.rateLimit.enabled
  ? rateLimit({
      windowMs: env.rateLimit.authWindowMs,
      max: env.rateLimit.authMax,
      message: { success: false, error: { code: 'TOO_MANY_ATTEMPTS', message: 'Too many login attempts' } },
      standardHeaders: true,
      legacyHeaders: false,
    })
  : noOp;

module.exports = { general, auth };
