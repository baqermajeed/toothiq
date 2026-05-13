const { describe, it } = require('node:test');
const assert = require('node:assert');

const {
  AppError,
  unauthorized,
  forbidden,
  notFound,
  badRequest,
  conflict,
  unprocessable,
} = require('../src/utils/errors');

describe('errors', () => {
  it('AppError sets message and statusCode', () => {
    const err = AppError('test', 400, 'BAD');
    assert.strictEqual(err.message, 'test');
    assert.strictEqual(err.statusCode, 400);
    assert.strictEqual(err.code, 'BAD');
  });

  it('unauthorized returns 401', () => {
    const err = unauthorized();
    assert.strictEqual(err.statusCode, 401);
    assert.strictEqual(err.code, 'UNAUTHORIZED');
  });

  it('forbidden returns 403', () => {
    const err = forbidden('No access');
    assert.strictEqual(err.statusCode, 403);
    assert.strictEqual(err.message, 'No access');
  });

  it('notFound returns 404', () => {
    const err = notFound('Order not found');
    assert.strictEqual(err.statusCode, 404);
  });

  it('badRequest returns 400', () => {
    const err = badRequest('Invalid input');
    assert.strictEqual(err.statusCode, 400);
  });

  it('conflict returns 409', () => {
    const err = conflict('Already exists');
    assert.strictEqual(err.statusCode, 409);
  });

  it('unprocessable returns 422', () => {
    const err = unprocessable('Validation failed');
    assert.strictEqual(err.statusCode, 422);
  });
});
