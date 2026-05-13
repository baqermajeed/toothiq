const mediasoup = require('mediasoup');
const { MEDIA_CODECS, getListenInfos } = require('./mediasoupConfig');

const MAX_PARTICIPANTS_PER_ROOM = 4;

let worker = null;
let webRtcServer = null;
let router = null;

// roomId -> Map(participantKey -> participantState)
const rooms = new Map();

async function ensureWorker() {
  if (worker && !worker.closed) return worker;
  worker = await mediasoup.createWorker({
    logLevel: 'warn',
    logTags: ['error'],
  });
  worker.on('died', (err) => {
    console.error('[ORDER_PTT] Worker died:', err);
    worker = null;
    webRtcServer = null;
    router = null;
    rooms.clear();
  });
  return worker;
}

async function ensureWebRtcServer() {
  if (webRtcServer && !webRtcServer.closed) return webRtcServer;
  const w = await ensureWorker();
  webRtcServer = await w.createWebRtcServer({
    listenInfos: getListenInfos(),
  });
  return webRtcServer;
}

async function ensureRouter() {
  if (router && !router.closed) return router;
  const w = await ensureWorker();
  router = await w.createRouter({ mediaCodecs: MEDIA_CODECS });
  return router;
}

function getRoom(roomId) {
  if (!rooms.has(roomId)) {
    rooms.set(roomId, new Map());
  }
  return rooms.get(roomId);
}

function getParticipantCount(roomId) {
  return getRoom(roomId).size;
}

function canJoin(roomId) {
  return getParticipantCount(roomId) < MAX_PARTICIPANTS_PER_ROOM;
}

async function getRouterRtpCapabilities() {
  const r = await ensureRouter();
  return r.rtpCapabilities;
}

async function createWebRtcTransport() {
  const r = await ensureRouter();
  const srv = await ensureWebRtcServer();
  const transport = await r.createWebRtcTransport({
    webRtcServer: srv,
    enableUdp: true,
    enableTcp: true,
    preferUdp: true,
  });
  return {
    id: transport.id,
    iceParameters: transport.iceParameters,
    iceCandidates: transport.iceCandidates,
    dtlsParameters: transport.dtlsParameters,
    transport,
  };
}

async function joinRoom(roomId, participantKey) {
  const participants = getRoom(roomId);
  if (!participants.has(participantKey) && !canJoin(roomId)) {
    throw new Error('ROOM_FULL');
  }
  if (participants.has(participantKey)) {
    return { alreadyJoined: true };
  }

  const sendTransportData = await createWebRtcTransport();
  const recvTransportData = await createWebRtcTransport();

  participants.set(participantKey, {
    participantKey,
    sendTransport: sendTransportData.transport,
    recvTransport: recvTransportData.transport,
    producer: null,
    consumers: new Map(),
    rtpCapabilities: null,
  });

  return {
    sendTransport: {
      id: sendTransportData.id,
      iceParameters: sendTransportData.iceParameters,
      iceCandidates: sendTransportData.iceCandidates,
      dtlsParameters: sendTransportData.dtlsParameters,
    },
    recvTransport: {
      id: recvTransportData.id,
      iceParameters: recvTransportData.iceParameters,
      iceCandidates: recvTransportData.iceCandidates,
      dtlsParameters: recvTransportData.dtlsParameters,
    },
  };
}

function getParticipant(roomId, participantKey) {
  return getRoom(roomId).get(participantKey);
}

async function connectSendTransport(roomId, participantKey, transportId, dtlsParameters) {
  const p = getParticipant(roomId, participantKey);
  if (!p || p.sendTransport.id !== transportId) throw new Error('Invalid transport');
  await p.sendTransport.connect({ dtlsParameters });
}

async function connectRecvTransport(roomId, participantKey, transportId, dtlsParameters) {
  const p = getParticipant(roomId, participantKey);
  if (!p || p.recvTransport.id !== transportId) throw new Error('Invalid transport');
  await p.recvTransport.connect({ dtlsParameters });
}

async function produce(roomId, participantKey, transportId, kind, rtpParameters) {
  const p = getParticipant(roomId, participantKey);
  if (!p || p.sendTransport.id !== transportId) throw new Error('Invalid transport');
  const producer = await p.sendTransport.produce({ kind, rtpParameters });
  p.producer = producer;
  return { id: producer.id };
}

async function createConsumersForNewProducer(roomId, producerId, producerKey) {
  const result = [];
  const participants = getRoom(roomId);
  const r = await ensureRouter();
  const producer = participants.get(producerKey)?.producer;
  if (!producer || producer.id !== producerId) return result;

  for (const [otherKey, other] of participants) {
    if (otherKey === producerKey || !other.rtpCapabilities) continue;
    try {
      const canConsumeProducer = r.canConsume({
        producerId,
        rtpCapabilities: other.rtpCapabilities,
      });
      if (!canConsumeProducer) continue;
      const consumer = await other.recvTransport.consume({
        producerId,
        rtpCapabilities: other.rtpCapabilities,
      });
      other.consumers.set(producerId, consumer);
      result.push({
        participantKey: otherKey,
        consumerParams: {
          id: consumer.id,
          producerId: consumer.producerId,
          kind: consumer.kind,
          rtpParameters: consumer.rtpParameters,
        },
      });
    } catch (err) {
      console.error('[ORDER_PTT] consume error:', err);
    }
  }
  return result;
}

async function setRtpCapabilities(roomId, participantKey, rtpCapabilities) {
  const p = getParticipant(roomId, participantKey);
  if (!p) throw new Error('Participant not found');
  p.rtpCapabilities = rtpCapabilities;
}

async function consume(roomId, participantKey, producerId, rtpCapabilities) {
  const p = getParticipant(roomId, participantKey);
  if (!p) throw new Error('Participant not found');
  const r = await ensureRouter();
  const canConsumeProducer = r.canConsume({ producerId, rtpCapabilities });
  if (!canConsumeProducer) throw new Error('Cannot consume');
  const consumer = await p.recvTransport.consume({
    producerId,
    rtpCapabilities,
  });
  p.consumers.set(producerId, consumer);
  return {
    id: consumer.id,
    producerId: consumer.producerId,
    kind: consumer.kind,
    rtpParameters: consumer.rtpParameters,
  };
}

async function getProducersFor(roomId, participantKey) {
  const result = [];
  const participants = getRoom(roomId);
  for (const [otherKey, other] of participants) {
    if (otherKey !== participantKey && other.producer) {
      result.push({
        producerId: other.producer.id,
        participantKey: otherKey,
      });
    }
  }
  return result;
}

async function setProducerPaused(roomId, participantKey) {
  const p = getParticipant(roomId, participantKey);
  if (!p || !p.producer) return;
  await p.producer.pause();
}

async function setProducerResume(roomId, participantKey) {
  const p = getParticipant(roomId, participantKey);
  if (!p || !p.producer) return;
  await p.producer.resume();
}

async function leaveRoom(roomId, participantKey) {
  const participants = getRoom(roomId);
  const p = participants.get(participantKey);
  if (!p) return;
  try {
    if (p.sendTransport && !p.sendTransport.closed) p.sendTransport.close();
    if (p.recvTransport && !p.recvTransport.closed) p.recvTransport.close();
  } catch (err) {
    console.error('[ORDER_PTT] Error closing transports:', err);
  }
  participants.delete(participantKey);
  if (participants.size === 0) {
    rooms.delete(roomId);
  }
}

module.exports = {
  MAX_PARTICIPANTS_PER_ROOM,
  getParticipantCount,
  canJoin,
  getRouterRtpCapabilities,
  joinRoom,
  leaveRoom,
  connectSendTransport,
  connectRecvTransport,
  produce,
  consume,
  setRtpCapabilities,
  getProducersFor,
  setProducerPaused,
  setProducerResume,
  createConsumersForNewProducer,
};
