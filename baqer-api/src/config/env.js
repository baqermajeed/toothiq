const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', '..', '.env') });

const nodeEnv = process.env.NODE_ENV || 'development';
const isProduction = nodeEnv === 'production';

function boolEnv(name, defaultValue = false) {
  const v = process.env[name];
  if (v == null || v === '') return defaultValue;
  return ['1', 'true', 'yes', 'on'].includes(String(v).toLowerCase());
}

function numEnv(name, defaultValue = 0) {
  const n = Number(process.env[name]);
  return Number.isFinite(n) ? n : defaultValue;
}

module.exports = {
  nodeEnv,
  isProduction,
  port: numEnv('PORT', 3000),
  mongodbUri: process.env.MONGODB_URI || 'mongodb://localhost:27017/baqer',
  jwt: {
    accessSecret: process.env.JWT_ACCESS_SECRET || 'dev-access-secret-change-me',
    refreshSecret: process.env.JWT_REFRESH_SECRET || 'dev-refresh-secret-change-me',
    accessExpiresIn: process.env.JWT_ACCESS_EXPIRES_IN || '90d',
    refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '100d',
  },
  bcryptRounds: numEnv('BCRYPT_ROUNDS', 12),
  rateLimit: {
    enabled: boolEnv('RATE_LIMIT_ENABLED', true),
    windowMs: numEnv('RATE_LIMIT_WINDOW_MS', 900000),
    max: numEnv('RATE_LIMIT_MAX', 300),
    authWindowMs: numEnv('RATE_LIMIT_AUTH_WINDOW_MS', 900000),
    authMax: numEnv('RATE_LIMIT_AUTH_MAX', 15),
  },
  telegram: {
    botToken: process.env.TELEGRAM_BOT_TOKEN || '',
    chatId: process.env.TELEGRAM_CHAT_ID || '',
  },
  platformSettingsSource: process.env.PLATFORM_SETTINGS_SOURCE || 'db',
  platformSettings: {
    deliveryEnabled: boolEnv('PLATFORM_DELIVERY_ENABLED', true),
    deliveryPauseReason: process.env.PLATFORM_DELIVERY_PAUSE_REASON || '',
    globalDeliveryFee: numEnv('PLATFORM_GLOBAL_DELIVERY_FEE', 0),
  },
  corsOrigins: process.env.CORS_ORIGINS || '',
  firebaseCredentialsPath:
    process.env.FIREBASE_CREDENTIALS_PATH || process.env.GOOGLE_APPLICATION_CREDENTIALS || '',
  ptt: {
    enabled: boolEnv('PTT_ENABLED', true),
    maxParticipants: numEnv('PTT_MAX_PARTICIPANTS', 6),
  },
  appUpdate: {
    minimumVersion: process.env.APP_MINIMUM_VERSION || '1.0.0',
    storeUrl: process.env.APP_STORE_URL || '',
    forceUpdate: boolEnv('APP_FORCE_UPDATE', false),
  },
  appUpdateV2: {
    minimumVersion: process.env.APP_V2_MINIMUM_VERSION || '1.0.0',
    androidUrl: process.env.APP_V2_STORE_URL_ANDROID || process.env.APP_STORE_URL_ANDROID || '',
    iosUrl: process.env.APP_V2_STORE_URL_IOS || process.env.APP_STORE_URL_IOS || '',
    fallbackUrl: process.env.APP_V2_STORE_URL || '',
    forceUpdate: boolEnv('APP_V2_FORCE_UPDATE', false),
  },
  driverWalletRatePerOrder: numEnv('DRIVER_WALLET_RATE_PER_ORDER', 1000),
};
