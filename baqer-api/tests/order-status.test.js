const { describe, it } = require('node:test');
const assert = require('node:assert');

const { ORDER_STATUS } = require('../src/config/constants');

describe('order status constants', () => {
  it('ORDER_STATUS has expected values', () => {
    assert.strictEqual(ORDER_STATUS.PENDING, 'pending');
    assert.strictEqual(ORDER_STATUS.ACCEPTED, 'accepted');
    assert.strictEqual(ORDER_STATUS.PREPARING, 'preparing');
    assert.strictEqual(ORDER_STATUS.ON_THE_WAY, 'on_the_way');
    assert.strictEqual(ORDER_STATUS.DELIVERED, 'delivered');
    assert.strictEqual(ORDER_STATUS.CANCELED, 'canceled');
  });
});
