const { User } = require('../models');
const { verifyAccess } = require('../utils/tokens');
const { unauthorized, forbidden } = require('../utils/errors');

async function authenticate(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return next(unauthorized('Missing or invalid Authorization header'));
  }
  const token = authHeader.slice(7);
  try {
    const decoded = verifyAccess(token);
    const user = await User.findById(decoded.userId).select('+passwordHash');
    if (!user) return next(unauthorized('User not found'));
    if (!user.isActive) return next(forbidden('Account is disabled'));
    req.user = user;
    req.userId = user._id;
    req.userRoles = user.roles || [];
    next();
  } catch (err) {
    return next(unauthorized('Invalid or expired token'));
  }
}

/**
 * Same as authenticate but does not fail when no token or invalid token.
 * Sets req.user, req.userId, req.userRoles when token is valid (user loaded without passwordHash).
 */
async function optionalAuthenticate(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return next();
  }
  const token = authHeader.slice(7);
  try {
    const decoded = verifyAccess(token);
    const user = await User.findById(decoded.userId);
    if (!user || !user.isActive) return next();
    req.user = user;
    req.userId = user._id;
    req.userRoles = user.roles || [];
  } catch (_) {
    // ignore invalid/expired token
  }
  next();
}

function requireRoles(...allowedRoles) {
  return (req, res, next) => {
    const raw = req.userRoles;
    const roles = Array.isArray(raw)
      ? raw
      : raw != null && typeof raw === 'string'
        ? [raw]
        : [];
    const hasRole = roles.some((r) => r && allowedRoles.includes(String(r)));
    if (!hasRole) return next(forbidden('Insufficient permissions'));
    next();
  };
}

module.exports = { authenticate, optionalAuthenticate, requireRoles };
