/**
 * معالج Socket.IO للـ PTT — إشارات mediasoup (لاسلكي الطلب بين أطراف الطلب).
 */
const orderRoom = require('../ptt/orderRoom');
const { Order, Shop } = require('../models');

/** order:{orderId}:{participantKey} -> socket.id */
const orderParticipantToSocketId = new Map();
/** socket.id -> Set(order:{orderId}:{participantKey}) */
const socketOrderMemberships = new Map();

function orderKey(orderId, participantKey) {
  return `order:${orderId}:${participantKey}`;
}

function participantKeyFromSocket(socket) {
  const userId = socket.userId?.toString();
  if (!userId) return null;
  if (Array.isArray(socket.userRoles) && socket.userRoles.includes('shop')) {
    return `shop:${userId}`;
  }
  return null;
}

async function canJoinOrderPtt(socket, orderId) {
  if (!orderId) return false;
  const userId = socket.userId?.toString();
  if (!userId) return false;
  const roles = Array.isArray(socket.userRoles) ? socket.userRoles : [];
  const order = await Order.findById(orderId).select('shopId shopPortions.shopId').lean();
  if (!order) return false;

  if (roles.includes('shop')) {
    const shops = await Shop.find({ ownerId: userId }).select('_id').lean();
    const shopIds = new Set(shops.map((s) => s._id?.toString()).filter(Boolean));
    const singleShopId = order.shopId?.toString?.();
    if (singleShopId && shopIds.has(singleShopId)) return true;
    if (Array.isArray(order.shopPortions)) {
      for (const p of order.shopPortions) {
        const sid = p?.shopId?.toString?.();
        if (sid && shopIds.has(sid)) return true;
      }
    }
  }
  return false;
}

function registerPttHandlers(socket) {
  // لاسلكي الطلب بين السائق وصاحب المحل (جديد)
  const participantKey = participantKeyFromSocket(socket);

  socket.on('orderPtt:join', async (payload, ack) => {
    try {
      const orderId = payload?.orderId?.toString?.() || '';
      if (!participantKey || !orderId) {
        if (typeof ack === 'function') ack({ ok: false, error: 'UNAUTHORIZED' });
        return;
      }
      const allowed = await canJoinOrderPtt(socket, orderId);
      if (!allowed) {
        if (typeof ack === 'function') ack({ ok: false, error: 'NOT_ALLOWED' });
        return;
      }
      if (!orderRoom.canJoin(orderId)) {
        const already = orderRoom.getParticipantCount(orderId) > 0;
        if (!already) {
          if (typeof ack === 'function') ack({ ok: false, error: 'ROOM_FULL' });
          return;
        }
      }
      const result = await orderRoom.joinRoom(orderId, participantKey);
      const key = orderKey(orderId, participantKey);
      orderParticipantToSocketId.set(key, socket.id);
      if (!socketOrderMemberships.has(socket.id)) {
        socketOrderMemberships.set(socket.id, new Set());
      }
      socketOrderMemberships.get(socket.id).add(key);

      const rtpCapabilities = await orderRoom.getRouterRtpCapabilities();
      if (typeof ack === 'function') {
        ack({
          ok: true,
          alreadyJoined: !!result.alreadyJoined,
          routerRtpCapabilities: rtpCapabilities,
          sendTransport: result.sendTransport,
          recvTransport: result.recvTransport,
        });
      }
    } catch (err) {
      console.error('[ORDER_PTT] join error:', err);
      if (typeof ack === 'function') ack({ ok: false, error: err.message || 'Join failed' });
    }
  });

  socket.on('orderPtt:setRtpCapabilities', async (payload, ack) => {
    try {
      const orderId = payload?.orderId?.toString?.() || '';
      const rtpCapabilities = payload?.rtpCapabilities;
      if (!participantKey || !orderId || !rtpCapabilities) {
        if (typeof ack === 'function') ack({ ok: false, error: 'Missing params' });
        return;
      }
      await orderRoom.setRtpCapabilities(orderId, participantKey, rtpCapabilities);
      const producers = await orderRoom.getProducersFor(orderId, participantKey);
      if (typeof ack === 'function') ack({ ok: true, producers });
    } catch (err) {
      if (typeof ack === 'function') ack({ ok: false, error: err.message });
    }
  });

  socket.on('orderPtt:connectSendTransport', async (payload, ack) => {
    try {
      const orderId = payload?.orderId?.toString?.() || '';
      const transportId = payload?.transportId;
      const dtlsParameters = payload?.dtlsParameters;
      if (!participantKey || !orderId || !transportId || !dtlsParameters) {
        if (typeof ack === 'function') ack({ ok: false, error: 'Missing params' });
        return;
      }
      await orderRoom.connectSendTransport(orderId, participantKey, transportId, dtlsParameters);
      if (typeof ack === 'function') ack({ ok: true });
    } catch (err) {
      if (typeof ack === 'function') ack({ ok: false, error: err.message });
    }
  });

  socket.on('orderPtt:connectRecvTransport', async (payload, ack) => {
    try {
      const orderId = payload?.orderId?.toString?.() || '';
      const transportId = payload?.transportId;
      const dtlsParameters = payload?.dtlsParameters;
      if (!participantKey || !orderId || !transportId || !dtlsParameters) {
        if (typeof ack === 'function') ack({ ok: false, error: 'Missing params' });
        return;
      }
      await orderRoom.connectRecvTransport(orderId, participantKey, transportId, dtlsParameters);
      if (typeof ack === 'function') ack({ ok: true });
    } catch (err) {
      if (typeof ack === 'function') ack({ ok: false, error: err.message });
    }
  });

  socket.on('orderPtt:produce', async (payload, ack) => {
    try {
      const orderId = payload?.orderId?.toString?.() || '';
      const transportId = payload?.transportId;
      const kind = payload?.kind;
      const rtpParameters = payload?.rtpParameters;
      if (!participantKey || !orderId || !transportId || !kind || !rtpParameters) {
        if (typeof ack === 'function') ack({ ok: false, error: 'Missing params' });
        return;
      }
      const result = await orderRoom.produce(orderId, participantKey, transportId, kind, rtpParameters);
      const consumersToEmit = await orderRoom.createConsumersForNewProducer(orderId, result.id, participantKey);
      const io = socket.server;
      for (const { participantKey: otherKey, consumerParams } of consumersToEmit) {
        const sid = orderParticipantToSocketId.get(orderKey(orderId, otherKey));
        if (sid) {
          io.to(sid).emit('orderPtt:newConsumer', { orderId, ...consumerParams });
        }
      }
      if (typeof ack === 'function') ack({ ok: true, producerId: result.id });
    } catch (err) {
      if (typeof ack === 'function') ack({ ok: false, error: err.message });
    }
  });

  socket.on('orderPtt:consume', async (payload, ack) => {
    try {
      const orderId = payload?.orderId?.toString?.() || '';
      const producerId = payload?.producerId;
      const rtpCapabilities = payload?.rtpCapabilities;
      if (!participantKey || !orderId || !producerId || !rtpCapabilities) {
        if (typeof ack === 'function') ack({ ok: false, error: 'Missing params' });
        return;
      }
      const consumer = await orderRoom.consume(orderId, participantKey, producerId, rtpCapabilities);
      if (typeof ack === 'function') ack({ ok: true, consumer });
    } catch (err) {
      if (typeof ack === 'function') ack({ ok: false, error: err.message });
    }
  });

  socket.on('orderPtt:pauseProducer', async (payload, ack) => {
    try {
      const orderId = payload?.orderId?.toString?.() || '';
      if (!participantKey || !orderId) {
        if (typeof ack === 'function') ack({ ok: false, error: 'Missing orderId' });
        return;
      }
      await orderRoom.setProducerPaused(orderId, participantKey);
      if (typeof ack === 'function') ack({ ok: true });
    } catch (err) {
      if (typeof ack === 'function') ack({ ok: false, error: err.message });
    }
  });

  socket.on('orderPtt:resumeProducer', async (payload, ack) => {
    try {
      const orderId = payload?.orderId?.toString?.() || '';
      if (!participantKey || !orderId) {
        if (typeof ack === 'function') ack({ ok: false, error: 'Missing orderId' });
        return;
      }
      await orderRoom.setProducerResume(orderId, participantKey);
      if (typeof ack === 'function') ack({ ok: true });
    } catch (err) {
      if (typeof ack === 'function') ack({ ok: false, error: err.message });
    }
  });

  socket.on('orderPtt:leave', async (payload, ack) => {
    try {
      const orderId = payload?.orderId?.toString?.() || '';
      if (!participantKey || !orderId) {
        if (typeof ack === 'function') ack({ ok: false, error: 'Missing orderId' });
        return;
      }
      await orderRoom.leaveRoom(orderId, participantKey);
      const key = orderKey(orderId, participantKey);
      orderParticipantToSocketId.delete(key);
      socketOrderMemberships.get(socket.id)?.delete(key);
      if (typeof ack === 'function') ack({ ok: true });
    } catch (err) {
      if (typeof ack === 'function') ack({ ok: false, error: err.message });
    }
  });

  socket.on('disconnect', () => {
    const set = socketOrderMemberships.get(socket.id);
    if (set && set.size > 0) {
      for (const key of set) {
        const parts = key.split(':');
        if (parts.length >= 4) {
          const orderId = parts[1];
          const participant = `${parts[2]}:${parts[3]}`;
          orderRoom.leaveRoom(orderId, participant).catch(() => {});
        }
        orderParticipantToSocketId.delete(key);
      }
    }
    socketOrderMemberships.delete(socket.id);
  });
}

module.exports = { registerPttHandlers };
