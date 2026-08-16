/**
 * المتاجر تعمل 24 ساعة: لا يُغلق المتجر تلقائياً حسب openHours.
 * عند الإقلاع تُمسح أوقات الدوام ويُفتح أي محل كان مغلقاً بسبب الجدول.
 */

const { Shop } = require('../models');

async function disableScheduledShopHours() {
  try {
    const result = await Shop.updateMany(
      {
        $or: [
          { 'openHours.from': { $exists: true, $nin: ['', null] } },
          { 'openHours.to': { $exists: true, $nin: ['', null] } },
        ],
      },
      { $set: { isOpen: true, openHours: { from: '', to: '' } } }
    );
    console.log(
      `[shopOpenCloseJob] 24h mode: cleared hours on ${result.modifiedCount} shops`
    );
  } catch (err) {
    console.error('[shopOpenCloseJob] disableScheduledShopHours error:', err.message);
  }
}

module.exports = {
  disableScheduledShopHours,
};
