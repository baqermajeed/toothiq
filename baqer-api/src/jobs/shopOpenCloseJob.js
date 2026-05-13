/**
 * تطبيق تلقائي لحالة فتح/إغلاق المحلات حسب openHours (توقيت العراق - Asia/Baghdad).
 * يُشغّل كل دقيقة ويحدّث isOpen للمحلات التي لديها openHours.from و openHours.to معبّآن.
 */

const { Shop } = require('../models');

const IRAQ_TZ = 'Asia/Baghdad';

/**
 * الوقت الحالي بتوقيت العراق: دقائق من منتصف الليل (0–1439).
 */
function getCurrentIraqMinutes() {
  const d = new Date();
  const formatter = new Intl.DateTimeFormat('en-GB', {
    timeZone: IRAQ_TZ,
    hour: 'numeric',
    minute: 'numeric',
    hour12: false,
  });
  const parts = formatter.formatToParts(d);
  const hour = parseInt(parts.find((p) => p.type === 'hour').value, 10);
  const minute = parseInt(parts.find((p) => p.type === 'minute').value, 10);
  return hour * 60 + minute;
}

/**
 * تحويل نص "HH:mm" أو "H:mm" إلى دقائق من منتصف الليل.
 * @returns {number|null} دقائق (0–1439) أو null إذا النص غير صالح
 */
function parseTimeToMinutes(str) {
  if (!str || typeof str !== 'string') return null;
  const trimmed = str.trim();
  const match = trimmed.match(/^(\d{1,2}):(\d{2})$/);
  if (!match) return null;
  const h = parseInt(match[1], 10);
  const m = parseInt(match[2], 10);
  if (h < 0 || h > 23 || m < 0 || m > 59) return null;
  return h * 60 + m;
}

/**
 * هل الوقت الحالي (بالدقائق) داخل نطاق الفتح from–to؟
 * يدعم الفترات الليلية (مثلاً from=22:00, to=02:00).
 */
function isWithinOpenRange(fromStr, toStr, currentMinutes) {
  const fromM = parseTimeToMinutes(fromStr);
  const toM = parseTimeToMinutes(toStr);
  if (fromM == null || toM == null) return null;

  if (fromM <= toM) {
    return currentMinutes >= fromM && currentMinutes < toM;
  }
  return currentMinutes >= fromM || currentMinutes < toM;
}

/**
 * تشغيل فحص واحد: تحديث isOpen لجميع المحلات التي لديها openHours.
 */
async function runShopOpenCloseSync() {
  try {
    const shops = await Shop.find({
      'openHours.from': { $exists: true, $ne: '', $type: 'string' },
      'openHours.to': { $exists: true, $ne: '', $type: 'string' },
    })
      .select('_id isOpen openHours')
      .lean();

    const nowMinutes = getCurrentIraqMinutes();

    for (const shop of shops) {
      const from = shop.openHours?.from;
      const to = shop.openHours?.to;
      if (!from || !to) continue;

      const shouldBeOpen = isWithinOpenRange(from, to, nowMinutes);
      if (shouldBeOpen === null) continue;
      if (shop.isOpen === shouldBeOpen) continue;

      await Shop.updateOne(
        { _id: shop._id },
        { $set: { isOpen: shouldBeOpen } }
      );
    }
  } catch (err) {
    console.error('[shopOpenCloseJob] runShopOpenCloseSync error:', err.message);
  }
}

const INTERVAL_MS = 60 * 1000;
let intervalId = null;

/**
 * بدء المهمة: تشغيل فوري ثم كل دقيقة.
 */
function startShopOpenCloseJob() {
  runShopOpenCloseSync();
  intervalId = setInterval(runShopOpenCloseSync, INTERVAL_MS);
  console.log('[shopOpenCloseJob] Started (Iraq time, every 1 min)');
}

/**
 * إيقاف المهمة (للاستخدام عند الإغلاق إن لزم).
 */
function stopShopOpenCloseJob() {
  if (intervalId) {
    clearInterval(intervalId);
    intervalId = null;
    console.log('[shopOpenCloseJob] Stopped');
  }
}

module.exports = {
  getCurrentIraqMinutes,
  parseTimeToMinutes,
  isWithinOpenRange,
  runShopOpenCloseSync,
  startShopOpenCloseJob,
  stopShopOpenCloseJob,
};
