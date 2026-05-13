/**
 * غرفة PTT واحدة للسائقين — حد أقصى 6 مشاركين.
 */
const mediasoup = require('mediasoup');
const { MEDIA_CODECS, getListenInfos } = require('./mediasoupConfig');

const MAX_PARTICIPANTS = 6;
const ROOM_ID = 'drivers_ptt';

let worker = null;
let webRtcServer = null;
let router = null;
const participants = new Map(); // driverId -> { sendTransport, recvTransport, producer, consumers }

async function ensureWorker() {
  if (worker && !worker.closed) return worker;
  worker = await mediasoup.createWorker({
    logLevel: 'warn',
    logTags: ['error'],
  });
  worker.on('died', (err) => {
    console.error('[PTT] Worker died:', err);
    worker = null;
    webRtcServer = null;
    router = null;
    participants.clear();
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

function getParticipantCount() {
  return participants.size;
}

function canJoin() {
  return participants.size < MAX_PARTICIPANTS;
}

async function getRouterRtpCapabilities() {
  const r = await ensureRouter();
  return r.rtpCapabilities;
}

async function createWebRtcTransport(isProducer) {
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

async function joinRoom(driverId) {
  if (!canJoin()) {
    throw new Error('ROOM_FULL');
  }
  if (participants.has(driverId)) {
    return { alreadyJoined: true };
  }

  const sendTransportData = await createWebRtcTransport(true);
  const recvTransportData = await createWebRtcTransport(false);

  participants.set(driverId, {
    driverId,
    sendTransport: sendTransportData.transport,
    recvTransport: recvTransportData.transport,
    producer: null,
    consumers: new Map(),
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

async function connectSendTransport(driverId, transportId, dtlsParameters) {
  const p = participants.get(driverId);
  if (!p || p.sendTransport.id !== transportId) throw new Error('Invalid transport');
  await p.sendTransport.connect({ dtlsParameters });
}

async function connectRecvTransport(driverId, transportId, dtlsParameters) {
  const p = participants.get(driverId);
  if (!p || p.recvTransport.id !== transportId) throw new Error('Invalid transport');
  await p.recvTransport.connect({ dtlsParameters });
}

async function produce(driverId, transportId, kind, rtpParameters) {
  const p = participants.get(driverId);
  if (!p || p.sendTransport.id !== transportId) throw new Error('Invalid transport');
  const producer = await p.sendTransport.produce({
    kind,
    rtpParameters,
  });
  p.producer = producer;
  return { id: producer.id };
}

/** إنشاء consumers للباقين عند إنتاج جديد — يُرجع قائمة { driverId, consumerParams } للإرسال للعميل */
async function createConsumersForNewProducer(producerId, producerDriverId) {
  const result = [];
  const r = await ensureRouter();
  const producer = participants.get(producerDriverId)?.producer;
  if (!producer || producer.id !== producerId) return result;
  for (const [otherId, other] of participants) {
    if (otherId !== producerDriverId && other.rtpCapabilities) {
      try {
        const canConsume = r.canConsume({
          producerId,
          rtpCapabilities: other.rtpCapabilities,
        });
        if (canConsume) {
          const consumer = await other.recvTransport.consume({
            producerId,
            rtpCapabilities: other.rtpCapabilities,
          });
          other.consumers.set(producerId, consumer);
          result.push({
            driverId: otherId,
            consumerParams: {
              id: consumer.id,
              producerId: consumer.producerId,
              kind: consumer.kind,
              rtpParameters: consumer.rtpParameters,
            },
          });
        }
      } catch (err) {
        console.error('[PTT] consume error:', err);
      }
    }
  }
  return result;
}

async function setRtpCapabilities(driverId, rtpCapabilities) {
  const p = participants.get(driverId);
  if (!p) throw new Error('Participant not found');
  p.rtpCapabilities = rtpCapabilities;
}

async function consume(driverId, producerId, rtpCapabilities) {
  const p = participants.get(driverId);
  if (!p) throw new Error('Participant not found');
  const r = await ensureRouter();
  const canConsume = r.canConsume({ producerId, rtpCapabilities });
  if (!canConsume) throw new Error('Cannot consume');
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

async function getProducersFor(driverId) {
  const result = [];
  for (const [otherId, other] of participants) {
    if (otherId !== driverId && other.producer) {
      result.push({
        producerId: other.producer.id,
        driverId: otherId,
      });
    }
  }
  return result;
}

async function setProducerPaused(driverId) {
  const p = participants.get(driverId);
  if (!p || !p.producer) return;
  await p.producer.pause();
}

async function setProducerResume(driverId) {
  const p = participants.get(driverId);
  if (!p || !p.producer) return;
  await p.producer.resume();
}

async function leaveRoom(driverId) {
  const p = participants.get(driverId);
  if (!p) return;
  try {
    if (p.sendTransport && !p.sendTransport.closed) p.sendTransport.close();
    if (p.recvTransport && !p.recvTransport.closed) p.recvTransport.close();
  } catch (err) {
    console.error('[PTT] Error closing transports:', err);
  }
  participants.delete(driverId);
}

module.exports = {
  ROOM_ID,
  MAX_PARTICIPANTS,
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
