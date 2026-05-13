const { describe, it } = require('node:test');
const assert = require('node:assert');

const { signAccess, verifyAccess } = require('../src/utils/tokens');

describe('tokens', () => {
  it('signAccess returns a string', () => {
    const token = signAccess({ userId: '507f1f77bcf86cd799439011' });
    assert.strictEqual(typeof token, 'string');
    assert.ok(token.length > 0);
  });

  it('verifyAccess decodes payload', () => {
    const payload = { userId: '507f1f77bcf86cd799439011' };
    const token = signAccess(payload);
    const decoded = verifyAccess(token);
    assert.strictEqual(decoded.userId, payload.userId);
    assert.ok(decoded.iat);
    assert.ok(decoded.exp);
  });
});
