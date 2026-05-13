/**
 * إرسال تقرير طلبات جميع السائقين يومياً إلى التليغرام عند الساعة 11:56 ص بتوقيت بغداد.
 */

const { Order } = require('../models');
const { ORDER_STATUS } = require('../config/constants');
const { sendPlainMessage } = require('../utils/telegram');

const IRAQ_TZ = 'Asia/Baghdad';
const REPORT_HOUR = 11;
const REPORT_MINUTE = 56;
const REPORT_LIMIT = 5000;
const SEPARATOR_LINE = 'ـــــــــــــــــــــــــــــــــــــــــ';

let lastRunDate = null;
let intervalId = null;

/**
 * الوقت الحالي بتوقيت بغداد: { hour, minute, dateString: 'YYYY-MM-DD' }.
 */
function getBaghdadNow() {
  const d = new Date();
  const formatter = new Intl.DateTimeFormat('en-CA', {
    timeZone: IRAQ_TZ,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: 'numeric',
    minute: 'numeric',
    hour12: false,
  });
  const parts = formatter.formatToParts(d);
  const get = (type) => parts.find((p) => p.type === type)?.value || '0';
  const hour = parseInt(get('hour'), 10);
  const minute = parseInt(get('minute'), 10);
  const dateString = `${get('year')}-${get('month')}-${get('day')}`;
  return { hour, minute, dateString };
}

/**
 * بداية ونهاية يوم معيّن بتوقيت بغداد، مُرجَعان كـ Date (UTC).
 * @param {string} dateStr - 'YYYY-MM-DD' بتوقيت بغداد
 */
function getDayRangeInUTC(dateStr) {
  const start = new Date(`${dateStr}T00:00:00+03:00`);
  const end = new Date(`${dateStr}T23:59:59.999+03:00`);
  return { start, end };
}

/**
 * جلب كل الطلبات ليوم واحد (بداية ونهاية بالـ UTC).
 */
async function fetchOrdersForDay(start, end) {
  const orders = await Order.find({
    createdAt: { $gte: start, $lte: end },
  })
    .populate('driverId', 'name phone')
    .populate('customerId', 'name phone')
    .sort({ createdAt: 1 })
    .limit(REPORT_LIMIT)
    .lean();
  return orders;
}

/**
 * تاريخ الطلب بتوقيت بغداد 'YYYY-MM-DD'.
 */
function getBaghdadDateString(date) {
  if (!date) return '';
  const d = date instanceof Date ? date : new Date(date);
  const formatter = new Intl.DateTimeFormat('en-CA', {
    timeZone: IRAQ_TZ,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  });
  const parts = formatter.formatToParts(d);
  const get = (type) => parts.find((p) => p.type === type)?.value || '0';
  return `${get('year')}-${get('month')}-${get('day')}`;
}

/**
 * معرفات الطلبات المكررة (نفس اليوم + نفس العميل + نفس الهاتف).
 */
function getDuplicateOrderIds(orders) {
  const group = {};
  for (const o of orders) {
    const day = getBaghdadDateString(o.createdAt);
    const customerName = (o.customerId && o.customerId.name) ? o.customerId.name : '';
    const customerPhone = (o.customerId && o.customerId.phone) ? o.customerId.phone : '';
    const key = `${day}|${customerName}|${customerPhone}`;
    if (!group[key]) group[key] = [];
    group[key].push(o._id.toString());
  }
  const dupIds = new Set();
  for (const ids of Object.values(group)) {
    if (ids.length > 1) ids.forEach((id) => dupIds.add(id));
  }
  return dupIds;
}

/**
 * إحصائيات لمجموعة طلبات سائق واحد.
 */
function getStatsForOrders(orders) {
  const total = orders.length;
  const cancelled = orders.filter((o) => o.status === ORDER_STATUS.CANCELED).length;
  const nonCancelled = total - cancelled;
  const dupIds = getDuplicateOrderIds(orders);
  const duplicateCount = dupIds.size;
  const uniqueNonCancelledKeys = new Set();
  for (const o of orders) {
    if (o.status === ORDER_STATUS.CANCELED) continue;
    const name = (o.customerId && o.customerId.name) ? o.customerId.name : '';
    const phone = (o.customerId && o.customerId.phone) ? o.customerId.phone : '';
    uniqueNonCancelledKeys.add(`${name}|${phone}`);
  }
  const netCount = uniqueNonCancelledKeys.size;
  return { total, cancelled, nonCancelled, duplicateCount, netCount };
}

/**
 * بناء نص قسم سائق واحد.
 */
function appendDriverSection(buffer, orders, driverLabel) {
  const stats = getStatsForOrders(orders);
  buffer.push(SEPARATOR_LINE);
  buffer.push(driverLabel);
  buffer.push(`إجمالي طلبات هذا اليوم: ${stats.total}`);
  buffer.push(`اجمالي الطلبات المكررة: ${stats.duplicateCount}`);
  buffer.push(`اجمالي الطلبات غير الملغية: ${stats.nonCancelled}`);
  buffer.push(`الطلبات الملغية: ${stats.cancelled}`);
  buffer.push(`صافي الطلبات (غير الملغية وبدون مكررة): ${stats.netCount}`);
  buffer.push(SEPARATOR_LINE);
}

/**
 * بناء نص التقرير الكامل لليوم (جميع السائقين).
 */
function buildReportText(orders, dateStr) {
  const lines = [];
  lines.push('═══════════════════════════════════════');
  lines.push('         تقرير طلبات السائقين');
  lines.push('═══════════════════════════════════════');
  lines.push(`التاريخ: ${dateStr}`);
  lines.push('النطاق: جميع السائقين');
  lines.push('───────────────────────────────────────');

  if (!orders || orders.length === 0) {
    lines.push('');
    lines.push('لا توجد طلبات.');
    lines.push('═══════════════════════════════════════');
    return lines.join('\n');
  }

  const byDriver = {};
  for (const o of orders) {
    const id = o.driverId && o.driverId._id ? o.driverId._id.toString() : '__no_driver__';
    if (!byDriver[id]) byDriver[id] = [];
    byDriver[id].push(o);
  }

  const driverIds = Object.keys(byDriver);
  for (const id of driverIds) {
    const driverOrders = byDriver[id];
    const label =
      id === '__no_driver__'
        ? 'بدون سائق'
        : (driverOrders[0].driverId && driverOrders[0].driverId.name)
          ? driverOrders[0].driverId.name.trim()
          : `السائق (${id})`;
    appendDriverSection(lines, driverOrders, label);
  }

  lines.push('═══════════════════════════════════════');
  return lines.join('\n');
}

/**
 * تشغيل التقرير اليومي وإرساله إلى التليغرام.
 */
async function runDailyReport() {
  const { dateString } = getBaghdadNow();
  const { start, end } = getDayRangeInUTC(dateString);
  let orders;
  try {
    orders = await fetchOrdersForDay(start, end);
  } catch (err) {
    console.error('[dailyReportJob] fetchOrdersForDay error:', err.message);
    return;
  }
  const text = buildReportText(orders, dateString);
  const sent = await sendPlainMessage(text);
  if (sent) {
    console.log('[dailyReportJob] Report sent for date', dateString);
  } else {
    console.error('[dailyReportJob] Failed to send report to Telegram');
  }
}

/**
 * فحص كل دقيقة: إذا كانت الساعة 11:56 بغداد ولم يُشغّل التقرير اليوم، تشغيله.
 */
function tick() {
  const { hour, minute, dateString } = getBaghdadNow();
  if (hour !== REPORT_HOUR || minute !== REPORT_MINUTE) return;
  if (lastRunDate === dateString) return;
  lastRunDate = dateString;
  runDailyReport().catch((err) => {
    console.error('[dailyReportJob] runDailyReport error:', err.message);
  });
}

/**
 * بدء المهمة: فحص كل دقيقة.
 */
function startDailyReportJob() {
  intervalId = setInterval(tick, 60 * 1000);
  console.log('[dailyReportJob] Started (11:56 Baghdad, every 1 min check)');
}

/**
 * إيقاف المهمة.
 */
function stopDailyReportJob() {
  if (intervalId) {
    clearInterval(intervalId);
    intervalId = null;
    console.log('[dailyReportJob] Stopped');
  }
}

module.exports = {
  getBaghdadNow,
  getDayRangeInUTC,
  buildReportText,
  runDailyReport,
  startDailyReportJob,
  stopDailyReportJob,
};
