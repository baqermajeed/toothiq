/**
 * إعدادات المكالمات الصوتية للعميل: عنوان WebSocket العام وخوادم ICE.
 * القيم من متغيرات البيئة حتى لا تُخزَّن أسرار في تطبيقات الموبايل.
 */
function getConfig(req, res) {
  const signalingWsUrl = process.env.CALL_SIGNALING_WS_URL || '';
  let iceServers = [{ urls: 'stun:stun.l.google.com:19302' }];
  if (process.env.CALL_WEBRTC_ICE_JSON) {
    try {
      const parsed = JSON.parse(process.env.CALL_WEBRTC_ICE_JSON);
      if (Array.isArray(parsed) && parsed.length > 0) {
        iceServers = parsed;
      }
    } catch (_) {
      /* keep default */
    }
  }
  res.json({
    success: true,
    data: {
      signalingWsUrl,
      iceServers,
    },
  });
}

module.exports = {
  getConfig,
};
