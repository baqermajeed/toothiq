/**
 * إعداد mediasoup للـ PTT — صوت فقط، خفيف للموارد.
 */
const mediasoup = require('mediasoup');

const MEDIA_CODECS = [
  {
    kind: 'audio',
    mimeType: 'audio/opus',
    clockRate: 48000,
    channels: 2,
  },
];

/** نطاق منافذ RTP — تأكد من فتحها على الـ firewall */
const RTP_PORT_MIN = parseInt(process.env.MEDIASOUP_RTP_PORT_MIN || '40000', 10);
const RTP_PORT_MAX = parseInt(process.env.MEDIASOUP_RTP_PORT_MAX || '40100', 10);

/** عنوان الإعلان — للـ NAT (استخدم IP العام للـ VPS في الإنتاج) */
const ANNOUNCED_IP = process.env.MEDIASOUP_ANNOUNCED_IP || undefined;

function getListenInfos() {
  const infos = [
    {
      protocol: 'udp',
      ip: '0.0.0.0',
      portRange: { min: RTP_PORT_MIN, max: RTP_PORT_MAX },
      ...(ANNOUNCED_IP && { announcedAddress: ANNOUNCED_IP }),
    },
    {
      protocol: 'tcp',
      ip: '0.0.0.0',
      portRange: { min: RTP_PORT_MIN, max: RTP_PORT_MAX },
      ...(ANNOUNCED_IP && { announcedAddress: ANNOUNCED_IP }),
    },
  ];
  return infos;
}

module.exports = {
  MEDIA_CODECS,
  getListenInfos,
};
