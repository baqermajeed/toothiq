const { User } = require('../models');
const { verifyAccess } = require('../utils/tokens');

/**
 * Authenticate socket connection using JWT from handshake.
 * Expects auth: { token: 'Bearer <accessToken>' } or auth: { token: '<accessToken>' }.
 * Attaches socket.userId and socket.userRoles on success.
 * @param {import('socket.io').Socket} socket
 * @returns {Promise<{ ok: boolean, error?: string }>}
 */
async function authenticateSocket(socket) {
  const auth = socket.handshake.auth;
  const raw = auth?.token;
  if (!raw || typeof raw !== 'string') {
    return { ok: false, error: 'Missing or invalid token' };
  }
  const token = raw.startsWith('Bearer ') ? raw.slice(7) : raw;
  try {
    const decoded = verifyAccess(token);
    const userId = decoded.userId;
    if (!userId) return { ok: false, error: 'Invalid token payload' };
    const user = await User.findById(userId);
    if (!user) return { ok: false, error: 'User not found' };
    if (!user.isActive) return { ok: false, error: 'Account disabled' };
    socket.userId = user._id;
    socket.userRoles = user.roles || [];
    return { ok: true };
  } catch (err) {
    return { ok: false, error: 'Invalid or expired token' };
  }
}

module.exports = { authenticateSocket };
