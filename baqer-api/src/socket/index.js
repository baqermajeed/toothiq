const { Server } = require('socket.io');
const mongoose = require('mongoose');
const { authenticateSocket } = require('./auth');
const { canCustomerSubscribe } = require('./trackingAuth');
const { registerPttHandlers } = require('./pttHandler');
const { Order, Shop } = require('../models');
const { formatOrderForClient } = require('../services/orderService');

let io = null;

function shopRoomName(shopId) {
  return `shop:${shopId}`;
}

function roomName(orderId) {
  return `order:${orderId}`;
}

/** Deprecated: driver pool removed; kept as no-op for API compatibility. */
function notifyDriversNewOrder() {}

function notifyDriversOrderUpdated() {}

function notifyDriversOrderRemoved() {}

/**
 * Notify room that tracking has ended (order status changed from on_the_way).
 * Call from order controller after updateStatus when new status !== on_the_way.
 * @param {string} orderId - Order ID
 * @param {string} newStatus - New order status
 */
function notifyTrackingEnded(orderId, newStatus) {
  if (!io) return;
  const room = roomName(orderId);
  io.to(room).emit('tracking:ended', { orderId, status: newStatus });
}

/**
 * Convert order to plain object for socket broadcast.
 * يمرّ عبر نفس معالجة الـ HTTP: تسطيح المنتجات + حقل image + معرّفات المكالمات.
 * @param {object} order - Order document (Mongoose or plain)
 * @returns {object|null}
 */
function orderToPlain(order) {
  if (!order) return null;
  const formatted = formatOrderForClient(order);
  if (!formatted) return null;
  if (formatted._id) {
    formatted._id = typeof formatted._id === 'object' && formatted._id.toString
      ? formatted._id.toString()
      : String(formatted._id);
  }
  return formatted;
}

/**
 * Notify shop room of a new order (for shop owner app to print receipt).
 * Call from order controller after create/createVoiceOrder.
 * For multi-shop orders (shopPortions), notifies each shop with filtered payload.
 * @param {object} order - Order document (populated shopId/shopPortions.shopId, customerId), or plain object
 */
function notifyShopNewOrder(order) {
  if (!io || !order) return;
  const raw = order.toObject ? order.toObject() : order;

  if (raw.shopPortions && Array.isArray(raw.shopPortions) && raw.shopPortions.length > 0) {
    for (const portion of raw.shopPortions) {
      const shopId = portion.shopId?._id?.toString() || portion.shopId?.toString();
      if (!shopId) continue;
      const payload = {
        ...raw,
        _id: raw._id,
        shopId: portion.shopId,
        items: portion.items || [],
        totalPrice: portion.subtotal ?? 0,
        deliveryFee: 0,
        isMultiShop: raw.shopPortions.length > 1,
        shopPortions: undefined,
      };
      io.to(shopRoomName(shopId)).emit('new_order', { order: payload });
      console.log('[Socket] new_order بُث إلى غرفة المحل:', shopRoomName(shopId));
    }
    return;
  }

  const shopId = raw.shopId?._id?.toString() || raw.shopId?.toString();
  if (!shopId) return;
  io.to(shopRoomName(shopId)).emit('new_order', { order: raw });
  console.log('[Socket] new_order بُث إلى غرفة المحل:', shopRoomName(shopId));
}

/**
 * Setup Socket.IO on the HTTP server: auth, event handlers.
 * @param {import('http').Server} server - HTTP server from app.listen
 * @returns {import('socket.io').Server}
 */
function setupSocketIO(server) {
  io = new Server(server, {
    cors: { origin: '*' },
    path: '/socket.io',
    // شبكات الجوال قد تتأخر عن ردّ pong؛ القيم الافتراضية (20s) تسبب قطعاً خاطئاً للجلسة.
    pingInterval: 25000,
    pingTimeout: 60000,
  });

  io.use(async (socket, next) => {
    const result = await authenticateSocket(socket);
    if (!result.ok) {
      return next(new Error(result.error || 'Unauthorized'));
    }
    next();
  });

  io.on('connection', async (socket) => {
    console.log('[Socket] عميل متصل:', socket.id, 'userId:', socket.userId?.toString());
    // تسجيل معالجات اللاسلكي (PTT) العامة:
    // - لاسلكي السائقين القديم
    // - لاسلكي الطلب الجديد بين السائق وصاحب المحل
    registerPttHandlers(socket);

    // انضمام صاحب المحل إلى غرفة محله لاستقبال طلبات جديدة
    if (socket.userRoles && Array.isArray(socket.userRoles) && socket.userRoles.includes('shop')) {
      try {
        const shop = await Shop.findOne({ ownerId: socket.userId }).lean();
        if (shop && shop._id) {
          const room = shopRoomName(shop._id.toString());
          socket.join(room);
          console.log('[Socket] انضمام صاحب محل إلى الغرفة:', room);
        }
      } catch (err) {
        console.error('[Socket] خطأ في انضمام صاحب المحل للغرفة:', err);
      }
    }

    socket.on('tracking:subscribe', async (payload, ack) => {
      const orderId = payload?.orderId;
      if (!orderId || typeof orderId !== 'string') {
        if (typeof ack === 'function') ack({ ok: false, error: 'Invalid order id' });
        return;
      }
      const result = await canCustomerSubscribe(orderId, socket.userId);
      if (!result.ok) {
        console.log('[Socket] tracking:subscribe رُفض للطلب', orderId, ':', result.error);
        socket.emit('tracking:error', { message: result.error || 'Not allowed' });
        if (typeof ack === 'function') ack({ ok: false, error: result.error });
        return;
      }
      const room = roomName(orderId);
      const wasAlreadyInRoom = socket.rooms.has(room);
      socket.join(room);
      console.log('[Socket] اشتراك تتبع للطلب:', orderId, 'من عميل', socket.id);
      if (typeof ack === 'function') ack({ ok: true });
      socket.emit('tracking:subscribed', { orderId });

      // إرسال آخر موقع معروف للسائق فقط عند أول اشتراك (تجنّب التكرار عند إعادة الاشتراك).
      if (!wasAlreadyInRoom) {
        try {
          const order = await Order.findById(orderId).populate('driverId', 'location').lean();
          const driver = order?.driverId;
          const loc = driver?.location;
          if (loc?.coordinates && Array.isArray(loc.coordinates) && loc.coordinates.length >= 2) {
            const lng = Number(loc.coordinates[0]);
            const lat = Number(loc.coordinates[1]);
            if (Number.isFinite(lat) && Number.isFinite(lng)) {
              socket.emit('driver:location', { orderId, lat, lng });
              console.log('[Socket] إرسال آخر موقع سائق للطلب', orderId, '→ عميل', socket.id);
            }
          }
        } catch (err) {
          // غير حرج
        }
      }
    });

    socket.on('tracking:unsubscribe', (payload) => {
      const orderId = payload?.orderId;
      if (orderId && typeof orderId === 'string' && mongoose.Types.ObjectId.isValid(orderId)) {
        socket.leave(roomName(orderId));
      }
    });
  });

  return io;
}

async function broadcastDriverLocationFromHttp() {
  return { ok: false, error: 'Not supported' };
}

module.exports = {
  setupSocketIO,
  notifyTrackingEnded,
  notifyShopNewOrder,
  notifyDriversNewOrder,
  notifyDriversOrderUpdated,
  notifyDriversOrderRemoved,
  broadcastDriverLocationFromHttp,
};
