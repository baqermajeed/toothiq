const path = require('path');

// تحميل .env من جذر المشروع (يعمل مع PM2 و node مباشرة)
const envPath = path.join(__dirname, '..', '..', '.env');
require('dotenv').config({ path: envPath });

const nodeEnv = process.env.NODE_ENV || 'development';
const isProduction = nodeEnv === 'production';
const platformSettingsSource = process.env.PLATFORM_SETTINGS_SOURCE === 'env' ? 'env' : 'db';
const platformDeliveryEnabled = process.env.PLATFORM_DELIVERY_ENABLED !== 'false';
const platformDeliveryPauseReason = String(process.env.PLATFORM_DELIVERY_PAUSE_REASON || '').trim();
const platformGlobalDeliveryFee = Math.max(0, parseFloat(process.env.PLATFORM_GLOBAL_DELIVERY_FEE || '0') || 0);

if (isProduction) {
  const minLen = 16;
  if (!process.env.JWT_ACCESS_SECRET || process.env.JWT_ACCESS_SECRET.length < minLen) {
    throw new Error(
      `JWT_ACCESS_SECRET is required in production (min ${minLen} chars). ` +
        `Check .env exists at ${path.dirname(envPath)}`
    );
  }
}

const env = {
  nodeEnv,
  isProduction,
  port: parseInt(process.env.PORT || '3000', 10),
  mongodbUri: process.env.MONGODB_URI || 'mongodb://localhost:27017/qarep',
  jwt: {
    accessSecret: process.env.JWT_ACCESS_SECRET || 'dev-access-secret-do-not-use-in-prod',
    accessExpiresIn: process.env.JWT_ACCESS_EXPIRES_IN || '365d',
  },
  bcryptRounds: parseInt(process.env.BCRYPT_ROUNDS || '12', 10),
  rateLimit: {
    enabled: process.env.RATE_LIMIT_ENABLED !== 'false',
    windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS || '900000', 10),
    max: parseInt(process.env.RATE_LIMIT_MAX || '1000', 10),
    authWindowMs: parseInt(process.env.RATE_LIMIT_AUTH_WINDOW_MS || '900000', 10),
    authMax: parseInt(process.env.RATE_LIMIT_AUTH_MAX || '30', 10),
  },
  telegram: {
    botToken: process.env.TELEGRAM_BOT_TOKEN || '',
    chatId: process.env.TELEGRAM_CHAT_ID || '',
  },
  /** مصدر إعدادات المنصة: db (افتراضي) أو env */
  platformSettingsSource,
  /** إعدادات المنصة من البيئة (تُستخدم عند PLATFORM_SETTINGS_SOURCE=env). */
  platformSettings: {
    deliveryEnabled: platformDeliveryEnabled,
    deliveryPauseReason: platformDeliveryPauseReason,
    globalDeliveryFee: platformGlobalDeliveryFee,
  },

  /** نطاقات CORS المسموحة في الإنتاج (مفصولة بفاصلة). فارغ = السماح للجميع */
  corsOrigins: process.env.CORS_ORIGINS || '',

  /** مسار ملف اعتماد Firebase للإشعارات (FCM) */
  firebaseCredentialsPath: process.env.FIREBASE_CREDENTIALS_PATH || process.env.GOOGLE_APPLICATION_CREDENTIALS || '',

  /** mediasoup PTT — تواصل صوتي self-hosted بين السائقين */
  ptt: {
    enabled: process.env.PTT_ENABLED !== 'false',
    maxParticipants: parseInt(process.env.PTT_MAX_PARTICIPANTS || '6', 10),
  },

  /** إعدادات تحديث التطبيق — يُستخدم من endpoint التحقق من الإصدار */
  appUpdate: {
    /** الإصدار الأدنى المطلوب (مثل 1.1.0) — إذا كان إصدار التطبيق أقل يُعرض تحذير التحديث */
    minimumVersion: process.env.APP_MINIMUM_VERSION || '1.0.0',
    /** رابط التحديث legacy (للتطبيقات الحالية) */
    storeUrl: process.env.APP_STORE_URL || 'https://play.google.com/store/apps/details?id=com.example.qaryp',
    /** عند true: التحديث إجباري — المستخدم لا يستطيع إغلاق الدايلوغ والاستمرار */
    forceUpdate: process.env.APP_FORCE_UPDATE === 'true',
  },
  /** إعدادات تحديث التطبيق v2 — مستقلة للتطبيقات الجديدة فقط */
  appUpdateV2: {
    /** الإصدار الأدنى المطلوب لنسخة v2 */
    minimumVersion: process.env.APP_V2_MINIMUM_VERSION || '1.0.0',
    /** رابط تحديث خاص بأندرويد */
    androidUrl:
      process.env.APP_V2_STORE_URL_ANDROID || 'https://play.google.com/store/apps/details?id=com.example.qaryp',
    /** رابط تحديث خاص بـ iOS */
    iosUrl: process.env.APP_V2_STORE_URL_IOS || 'https://apps.apple.com/app/id0000000000',
    /** رابط fallback اختياري لنسخة v2 */
    fallbackUrl: process.env.APP_V2_STORE_URL || '',
    /** عند true: التحديث إجباري — المستخدم لا يستطيع إغلاق الدايلوغ والاستمرار */
    forceUpdate: process.env.APP_V2_FORCE_UPDATE === 'true',
  },
};

module.exports = env;
