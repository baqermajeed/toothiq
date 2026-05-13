const jwt = require('jsonwebtoken');
const env = require('../config/env');

function signAccess(payload) {
  return jwt.sign(payload, env.jwt.accessSecret, { expiresIn: env.jwt.accessExpiresIn });
}

function verifyAccess(token) {
  return jwt.verify(token, env.jwt.accessSecret);
}

module.exports = {
  signAccess,
  verifyAccess,
};
