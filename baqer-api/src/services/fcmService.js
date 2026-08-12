const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');
const env = require('../config/env');

let initialized = false;

function init() {
  if (initialized) return;
  const serviceAccountPath = env.firebaseCredentialsPath?.trim() || '';
  console.log('[FCM] init() | env.firebaseCredentialsPath:', serviceAccountPath || '(empty)');
  if (!serviceAccountPath) {
    console.warn('[FCM] FIREBASE_CREDENTIALS_PATH or GOOGLE_APPLICATION_CREDENTIALS not set - push notifications disabled');
    return;
  }
  const resolvedPath = path.resolve(serviceAccountPath);
  console.log('[FCM] resolvedPath:', resolvedPath);
  const fileExists = fs.existsSync(resolvedPath);
  console.log('[FCM] file exists:', fileExists);
  if (!fileExists) {
    console.error('[FCM] File not found:', resolvedPath);
    return;
  }
  try {
    admin.initializeApp({ credential: admin.credential.cert(resolvedPath) });
    initialized = true;
    console.log('[FCM] Initialized successfully');
  } catch (err) {
    console.error('[FCM] Failed to initialize:', err.message);
    console.error('[FCM] path:', resolvedPath);
    console.error('[FCM] stack:', err.stack);
  }
}

function toDataStrings(data = {}) {
  return Object.fromEntries(
    Object.entries(data || {}).map(([k, v]) => [String(k), String(v == null ? '' : v)])
  );
}

async function sendToToken(token, { title = 'ToothIQ', body, data = {} }) {
  if (!token || typeof token !== 'string') return null;
  init();
  if (!initialized) {
    console.warn('[FCM] sendToToken skipped — Firebase not initialized');
    return null;
  }
  try {
    return await admin.messaging().send({
      token,
      notification: { title, body },
      data: toDataStrings(data),
      android: { priority: 'high' },
      apns: { payload: { aps: { sound: 'default' } } },
    });
  } catch (err) {
    console.error('[FCM] sendToToken error:', err.message);
    return null;
  }
}

async function sendToTokens(tokens, { title = 'ToothIQ', body, data = {} }) {
  const valid = (tokens || []).filter((t) => t && typeof t === 'string');
  if (valid.length === 0) return { successCount: 0, failureCount: 0 };
  init();
  if (!initialized) {
    console.warn('[FCM] sendToTokens skipped — Firebase not initialized');
    return { successCount: 0, failureCount: valid.length, skipped: true };
  }
  try {
    const res = await admin.messaging().sendEachForMulticast({
      tokens: valid,
      notification: { title, body },
      data: toDataStrings(data),
      android: { priority: 'high' },
      apns: { payload: { aps: { sound: 'default' } } },
    });
    if (res.failureCount > 0) {
      res.responses.forEach((r, i) => {
        if (!r.success) {
          console.error('[FCM] token failed', {
            index: i,
            code: r.error?.code,
            message: r.error?.message,
          });
        }
      });
    }
    return { successCount: res.successCount, failureCount: res.failureCount };
  } catch (err) {
    console.error('[FCM] sendToTokens error:', err.message);
    return { successCount: 0, failureCount: valid.length };
  }
}

async function sendToTopic(topic, { title = 'ToothIQ', body, data = {} }) {
  const name = String(topic || '').trim();
  if (!name) return null;
  init();
  if (!initialized) {
    console.warn('[FCM] sendToTopic skipped — Firebase not initialized');
    return null;
  }
  try {
    const res = await admin.messaging().send({
      topic: name,
      notification: { title, body },
      data: toDataStrings(data),
      android: { priority: 'high' },
      apns: { payload: { aps: { sound: 'default' } } },
    });
    console.log('[FCM] sendToTopic ok', { topic: name, messageId: res });
    return res;
  } catch (err) {
    console.error('[FCM] sendToTopic error:', err.message);
    return null;
  }
}

module.exports = { init, sendToToken, sendToTokens, sendToTopic };
