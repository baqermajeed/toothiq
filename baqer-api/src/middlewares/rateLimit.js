const rateLimit = require('express-rate-limit');
const jwt = require('jsonwebtoken');
const env = require('../config/env');
const { verifyAccess } = require('../utils/tokens');

const noOp = (req, res, next) => next();

function clientIp(req) {
  return req.ip || req.socket?.remoteAddress || 'unknown';
}

function digitsPhone(value) {
  return String(value || '').replace(/\D/g, '');
}

/**
 * للمستخدمين المصادقين (أو بتوكن منتهٍ) نستخدم userId حتى لا يتشارك الجميع نفس الـ IP
 * خلف Nginx / NAT. بدون توكن نستخدم IP.
 */
function generalKeyGenerator(req) {
  const authHeader = req.headers.authorization;
  if (authHeader && authHeader.startsWith('Bearer ')) {
    const token = authHeader.slice(7);
    try {
      const decoded = verifyAccess(token);
      if (decoded && decoded.userId) return `user:${decoded.userId}`;
    } catch (_) {
      const decoded = jwt.decode(token);
      if (decoded && decoded.userId) return `user:${decoded.userId}`;
    }
  }
  return `ip:${clientIp(req)}`;
}

function skipGeneral(req) {
  const url = (req.originalUrl || req.url || '').split('?')[0];
  return (
    url === '/health' ||
    url.startsWith('/uploads') ||
    url.startsWith('/api-docs') ||
    url.startsWith('/api/auth')
  );
}

/**
 * تسجيل الدخول يُحسب حسب رقم الهاتف حتى لا حظر مكتب/شبكة كاملة بسبب IP مشترك.
 */
function authKeyGenerator(req) {
  const phone = digitsPhone(req.body && req.body.phone);
  if (phone.length >= 10) return `auth:phone:${phone}`;
  return `auth:ip:${clientIp(req)}`;
}

function skipAuth(req) {
  return req.path === '/logout' || req.method === 'OPTIONS';
}

const general = env.rateLimit.enabled
  ? rateLimit({
      windowMs: env.rateLimit.windowMs,
      max: env.rateLimit.max,
      keyGenerator: generalKeyGenerator,
      skip: skipGeneral,
      message: {
        success: false,
        error: {
          code: 'TOO_MANY_REQUESTS',
          message: 'طلبات كثيرة، حاول بعد قليل',
        },
      },
      standardHeaders: true,
      legacyHeaders: false,
      validate: { xForwardedForHeader: false, keyGeneratorIpFallback: false },
    })
  : noOp;

const auth = env.rateLimit.enabled
  ? rateLimit({
      windowMs: env.rateLimit.authWindowMs,
      max: env.rateLimit.authMax,
      keyGenerator: authKeyGenerator,
      skip: skipAuth,
      skipSuccessfulRequests: true,
      message: {
        success: false,
        error: {
          code: 'TOO_MANY_ATTEMPTS',
          message: 'محاولات دخول كثيرة، انتظر قليلاً ثم حاول مجدداً',
        },
      },
      standardHeaders: true,
      legacyHeaders: false,
      validate: { xForwardedForHeader: false, keyGeneratorIpFallback: false },
    })
  : noOp;

module.exports = { general, auth };
