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

/**
 * Send notification to a single device.
 * @param {string} token - FCM device token
 * @param {object} payload - { title?, body, data? }
 * @returns {Promise<string|null>} - message ID or null on failure
 */
async function sendToToken(token, { title = 'Qaryp', body, data = {} }) {
  if (!token || typeof token !== 'string') return null;
  init();
  if (!initialized) return null;
  try {
    const message = {
      token,
      notification: { title, body },
      data: Object.fromEntries(
        Object.entries(data).map(([k, v]) => [String(k), String(v == null ? '' : v)])
      ),
      android: { priority: 'high' },
      apns: { payload: { aps: { sound: 'default' } } },
    };
    const res = await admin.messaging().send(message);
    return res;
  } catch (err) {
    console.error('[FCM] sendToToken error:', err.message);
    return null;
  }
}

/**
 * Send notification to multiple devices.
 * @param {string[]} tokens - FCM device tokens
 * @param {object} payload - { title?, body, data? }
 * @returns {Promise<{ successCount: number, failureCount: number }>}
 */
async function sendToTokens(tokens, { title = 'Qaryp', body, data = {} }) {
  const valid = (tokens || []).filter((t) => t && typeof t === 'string');
  if (valid.length === 0) return { successCount: 0, failureCount: 0 };
  init();
  if (!initialized) return { successCount: 0, failureCount: valid.length };
  try {
    const message = {
      tokens: valid,
      notification: { title, body },
      data: Object.fromEntries(
        Object.entries(data || {}).map(([k, v]) => [String(k), String(v == null ? '' : v)])
      ),
      android: { priority: 'high' },
      apns: { payload: { aps: { sound: 'default' } } },
    };
    const res = await admin.messaging().sendEachForMulticast(message);
    return { successCount: res.successCount, failureCount: res.failureCount };
  } catch (err) {
    console.error('[FCM] sendToTokens error:', err.message);
    return { successCount: 0, failureCount: valid.length };
  }
}

module.exports = { init, sendToToken, sendToTokens };
