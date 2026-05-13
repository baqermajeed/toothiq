const env = require('../config/env');
const { ORDER_STATUS } = require('../config/constants');

const TELEGRAM_API = 'https://api.telegram.org';

const STATUS_LABELS = {
  [ORDER_STATUS.PENDING]: 'قيد الانتظار',
  [ORDER_STATUS.ACCEPTED]: 'مقبول',
  [ORDER_STATUS.PREPARING]: 'قيد التحضير',
  [ORDER_STATUS.ON_THE_WAY]: 'في الطريق',
  [ORDER_STATUS.DELIVERED]: 'تم التوصيل',
  [ORDER_STATUS.CANCELED]: 'ملغى',
  [ORDER_STATUS.POSTPONED]: 'مؤجل',
};

function escapeHtml(str) {
  if (str == null || typeof str !== 'string') return '';
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');
}

function formatItem(it) {
  const name = escapeHtml(it.name || 'صنف');
  const qty = it.quantity;
  const unitPrice = (it.price ?? 0).toFixed(2);
  const lineTotal = ((it.price ?? 0) * qty).toFixed(2);
  return `  • ${name}\n    الكمية: ${qty} | السعر: ${unitPrice} | الإجمالي: ${lineTotal}`;
}

function formatOrderDetails(order) {
  const shop = order.shopId && typeof order.shopId === 'object' ? order.shopId : null;
  const customer = order.customerId && typeof order.customerId === 'object' ? order.customerId : null;
  const driver = order.driverId && typeof order.driverId === 'object' ? order.driverId : null;
  let shopName;
  if (order.shopPortions && order.shopPortions.length > 0) {
    shopName =
      order.shopPortions
        .map((p) => {
          const s = p.shopId && typeof p.shopId === 'object' ? p.shopId : null;
          return s ? escapeHtml(s.name) : null;
        })
        .filter(Boolean)
        .join('، ') || 'متاجر متعددة';
  } else {
    shopName = shop ? escapeHtml(shop.name) : '—';
  }
  const customerName = customer ? escapeHtml(customer.name) : '—';
  const customerPhone = customer ? escapeHtml(customer.phone || '—') : '—';
  const driverName = driver ? escapeHtml(driver.name) : '—';
  const driverPhone = driver ? escapeHtml(driver.phone || '—') : '—';
  const coords = order.deliveryLocation?.coordinates;
  const location = coords && coords.length >= 2 ? `${coords[1]}, ${coords[0]}` : '—';
  const subtotal = order.totalPrice ?? 0;
  const deliveryFee = order.deliveryFee ?? 0;
  const total = subtotal + deliveryFee;
  const notes = order.notes ? escapeHtml(order.notes) : '—';

  let itemsSection;
  if (order.shopPortions && order.shopPortions.length > 0) {
    const parts = order.shopPortions.map((portion, idx) => {
      const pShop = portion.shopId && typeof portion.shopId === 'object' ? portion.shopId : null;
      const pShopName = pShop ? escapeHtml(pShop.name) : `متجر ${idx + 1}`;
      const itemLines = (portion.items || [])
        .map(formatItem)
        .join('\n');
      const subtotal = (portion.subtotal ?? 0).toFixed(2);
      return [
        `<b>🛒 ${pShopName}</b>`,
        itemLines || '  (بدون تفاصيل)',
        `  <i>المجموع الفرعي: ${subtotal}</i>`,
      ].join('\n');
    });
    itemsSection = parts.join('\n\n');
  } else if (order.items && order.items.length > 0) {
    const itemLines = order.items.map(formatItem).join('\n');
    const subtotal = (order.totalPrice ?? 0).toFixed(2);
    itemsSection = [
      `<b>🛒 ${shopName}</b>`,
      itemLines,
      `  <i>المجموع الفرعي: ${subtotal}</i>`,
    ].join('\n');
  } else {
    itemsSection = '  (طلب صوتي)';
  }

  return {
    shopName,
    customerName,
    customerPhone,
    driverName,
    driverPhone,
    location,
    itemsSection,
    subtotal: subtotal.toFixed(2),
    deliveryFee: deliveryFee.toFixed(2),
    total: total.toFixed(2),
    notes,
    statusLabel: STATUS_LABELS[order.status] || order.status,
  };
}

const TELEGRAM_MAX_MESSAGE_LENGTH = 4096;

/**
 * Send a text message to the configured Telegram chat.
 * Does nothing if TELEGRAM_BOT_TOKEN or TELEGRAM_CHAT_ID are not set.
 * @param {string} text - Message text (HTML)
 * @param {object} [options] - Optional: { parse_mode: 'HTML' } (default), or omit parse_mode for plain text
 * @returns {Promise<boolean>} - true if sent, false if skipped or failed
 */
async function sendMessage(text, options = {}) {
  const { botToken, chatId } = env.telegram;
  if (!botToken || !chatId) return false;
  const body = {
    chat_id: chatId,
    text,
    disable_web_page_preview: true,
  };
  const parseMode = options.parse_mode !== undefined ? options.parse_mode : 'HTML';
  if (parseMode) {
    body.parse_mode = parseMode;
  }
  try {
    const url = `${TELEGRAM_API}/bot${botToken}/sendMessage`;
    const res = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });
    if (!res.ok) {
      const err = await res.text();
      console.error('[Telegram] sendMessage failed:', res.status, err);
      return false;
    }
    return true;
  } catch (err) {
    console.error('[Telegram] sendMessage error:', err.message);
    return false;
  }
}

/**
 * Send plain text (no HTML parsing). If text exceeds Telegram limit (4096), sends multiple messages.
 * @param {string} text - Plain text message
 * @returns {Promise<boolean>} - true if all chunks sent, false if skipped or any failed
 */
async function sendPlainMessage(text) {
  if (!text || typeof text !== 'string') return false;
  const chunkSize = TELEGRAM_MAX_MESSAGE_LENGTH - 50;
  if (text.length <= TELEGRAM_MAX_MESSAGE_LENGTH) {
    return sendMessage(text, { parse_mode: null });
  }
  let ok = true;
  for (let i = 0; i < text.length; i += chunkSize) {
    const chunk = text.slice(i, i + chunkSize);
    const sent = await sendMessage(chunk, { parse_mode: null });
    if (!sent) ok = false;
    if (i + chunkSize < text.length) {
      await new Promise((r) => setTimeout(r, 300));
    }
  }
  return ok;
}

/**
 * Notify Telegram when a new order is created (customer sent order).
 * @param {object} order - Order document (populated shopId, customerId)
 */
async function notifyNewOrder(order) {
  const d = formatOrderDetails(order);
  const text = [
    '🆕 <b>طلب جديد</b>',
    '',
    `<b>رقم الطلب:</b> ${escapeHtml(order._id?.toString() || '—')}`,
    `<b>المتجر:</b> ${d.shopName}`,
    `<b>العميل:</b> ${d.customerName}`,
    `<b>هاتف العميل:</b> ${d.customerPhone}`,
    `<b>عنوان التوصيل:</b> ${d.location}`,
    '',
    '<b>المنتجات والمحلات:</b>',
    d.itemsSection,
    '',
    `<b>المجموع الفرعي:</b> ${d.subtotal}`,
    ...(parseFloat(d.deliveryFee) > 0 ? [`<b>رسوم التوصيل:</b> ${d.deliveryFee}`] : []),
    `<b>المجموع الكلي:</b> ${d.total}`,
    `<b>ملاحظات:</b> ${d.notes}`,
  ].join('\n');
  return sendMessage(text);
}

/**
 * Notify Telegram when order status changes (driver accepted, shop/driver updated status, etc.).
 * @param {object} order - Order document (populated shopId, customerId, driverId)
 * @param {string} previousStatus - Status before change
 * @param {string} changedByRole - 'customer' | 'shop' | 'driver' | 'admin'
 */
async function notifyOrderStatusChange(order, previousStatus, changedByRole) {
  const d = formatOrderDetails(order);
  const roleLabel = { customer: 'العميل', shop: 'المتجر', driver: 'السائق', admin: 'الإدارة' }[changedByRole] || changedByRole;
  const prevLabel = STATUS_LABELS[previousStatus] || previousStatus;
  const lines = [
    '📋 <b>تحديث حالة الطلب</b>',
    '',
    `<b>رقم الطلب:</b> ${escapeHtml(order._id?.toString() || '—')}`,
    `<b>الحالة السابقة:</b> ${prevLabel}`,
    `<b>الحالة الحالية:</b> ${d.statusLabel}`,
    `<b>تم التحديث بواسطة:</b> ${roleLabel}`,
    '',
    `<b>المتجر:</b> ${d.shopName}`,
    `<b>العميل:</b> ${d.customerName} — ${d.customerPhone}`,
    `<b>السائق:</b> ${d.driverName}${d.driverPhone !== '—' ? ` — ${d.driverPhone}` : ''}`,
    `<b>عنوان التوصيل:</b> ${d.location}`,
    '',
    '<b>المنتجات والمحلات:</b>',
    d.itemsSection,
    '',
    `<b>المجموع الفرعي:</b> ${d.subtotal}`,
    ...(parseFloat(d.deliveryFee) > 0 ? [`<b>رسوم التوصيل:</b> ${d.deliveryFee}`] : []),
    `<b>المجموع الكلي:</b> ${d.total}`,
    `<b>ملاحظات:</b> ${d.notes}`,
  ];
  if (order.cancelReason) {
    lines.push('', `<b>سبب الإلغاء:</b> ${escapeHtml(order.cancelReason)}`);
  }
  if (order.postponedReason) {
    lines.push('', `<b>سبب التأجيل:</b> ${escapeHtml(order.postponedReason)}`);
  }
  return sendMessage(lines.join('\n'));
}

/**
 * Notify Telegram when a user's location is outside supported zones.
 * @param {{lng: number|string, lat: number|string, type: 'entry'|'order'|'voice_order'|string}} payload
 */
async function notifyUnsupportedLocation({ lng, lat, type }) {
  const typeLabels = { entry: 'دخول', order: 'طلب توصيل', voice_order: 'طلب صوتي' };
  const lngNum = typeof lng === 'number' ? lng : Number(lng);
  const latNum = typeof lat === 'number' ? lat : Number(lat);
  const hasCoords = Number.isFinite(lngNum) && Number.isFinite(latNum);

  const coordsText = hasCoords ? `${latNum.toFixed(6)}, ${lngNum.toFixed(6)}` : '—';
  const typeText = typeLabels[type] || (type != null ? String(type) : '—');

  const text = [
    '📍 <b>موقع غير مدعوم</b>',
    '',
    `<b>الحدث:</b> ${escapeHtml(typeText)}`,
    `<b>الإحداثيات (lat,lng):</b> ${escapeHtml(coordsText)}`,
  ].join('\n');

  return sendMessage(text);
}

module.exports = {
  sendMessage,
  sendPlainMessage,
  notifyNewOrder,
  notifyOrderStatusChange,
  notifyUnsupportedLocation,
};
