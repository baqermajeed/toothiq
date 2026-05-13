const { PlatformSettings, PLATFORM_DOC_ID } = require('../models/PlatformSettings');
const env = require('../config/env');

const DEFAULT_FACEBOOK_URL = 'https://www.facebook.com/share/18E28nTLi4/';
const DEFAULT_INSTAGRAM_URL = 'https://www.instagram.com/qaraep?igsh=MWpsMmlraXZ5enFkNg==';

const DEFAULTS = {
  deliveryEnabled: true,
  deliveryPauseReason: '',
  globalDeliveryFee: 0,
  facebookUrl: '',
  instagramUrl: '',
  supportPhone: '',
  aboutUs: '',
};

let legacyAppContactMigrated = false;

async function migrateLegacyAppContactOnce() {
  if (legacyAppContactMigrated) return;
  legacyAppContactMigrated = true;
  try {
    const AppContact = require('../models/AppContact');
    const doc = await PlatformSettings.findById(PLATFORM_DOC_ID).lean();
    const ac = await AppContact.findOne().lean();
    if (!ac) return;
    const hasContent =
      doc &&
      (String(doc.supportPhone || '').trim() !== '' || String(doc.facebookUrl || '').trim() !== '');
    if (hasContent) return;
    const pickFirstPhone =
      [ac.supportPhone, ac.supportPhoneKarbala, ac.supportPhoneHilla, ac.supportPhoneDiwaniya]
        .map((p) => String(p || '').trim())
        .find(Boolean) || '';
    await PlatformSettings.findByIdAndUpdate(
      PLATFORM_DOC_ID,
      {
        $set: {
          facebookUrl: String(ac.facebookUrl || '').trim() || DEFAULT_FACEBOOK_URL,
          instagramUrl: String(ac.instagramUrl || '').trim() || DEFAULT_INSTAGRAM_URL,
          supportPhone: pickFirstPhone,
          aboutUs: String(doc?.aboutUs || '').trim(),
        },
      },
      { upsert: true, setDefaultsOnInsert: true }
    );
  } catch (_) {
    /* ignore */
  }
}

function contactSliceFromDoc(doc) {
  if (!doc) {
    return {
      facebookUrl: DEFAULTS.facebookUrl,
      instagramUrl: DEFAULTS.instagramUrl,
      supportPhone: DEFAULTS.supportPhone,
      aboutUs: DEFAULTS.aboutUs,
    };
  }
  return {
    facebookUrl: doc.facebookUrl ?? '',
    instagramUrl: doc.instagramUrl ?? '',
    supportPhone: doc.supportPhone ?? '',
    aboutUs: doc.aboutUs ?? '',
  };
}

function feeFromDoc(doc) {
  if (!doc || doc.globalDeliveryFee === undefined || doc.globalDeliveryFee === null) return null;
  const n = Number(doc.globalDeliveryFee);
  if (!Number.isFinite(n) || n < 0) return null;
  return n;
}

function resolveGlobalDeliveryFee(doc) {
  const feeFromEnv = Number(env.platformSettings?.globalDeliveryFee) || 0;
  if (env.platformSettingsSource === 'env') {
    if (doc?.useDashboardDeliveryFee) {
      const fromDb = feeFromDoc(doc);
      return fromDb !== null ? fromDb : feeFromEnv;
    }
    return feeFromEnv;
  }
  if (!doc) return DEFAULTS.globalDeliveryFee;
  const fromDb = feeFromDoc(doc);
  return fromDb !== null ? fromDb : 0;
}

/**
 * @returns {Promise<{
 *   deliveryEnabled: boolean,
 *   deliveryPauseReason: string,
 *   globalDeliveryFee: number,
 *   useDashboardDeliveryFee: boolean,
 *   facebookUrl: string,
 *   instagramUrl: string,
 *   supportPhone: string,
 *   aboutUs: string,
 * }>}
 */
async function getPlatformSettings() {
  await migrateLegacyAppContactOnce();
  const doc = await PlatformSettings.findById(PLATFORM_DOC_ID).lean();
  const contact = contactSliceFromDoc(doc);
  const globalDeliveryFee = resolveGlobalDeliveryFee(doc);
  const useDashboardDeliveryFee = !!doc?.useDashboardDeliveryFee;

  if (env.platformSettingsSource === 'env') {
    return {
      ...env.platformSettings,
      globalDeliveryFee,
      useDashboardDeliveryFee,
      ...contact,
    };
  }

  if (!doc) {
    return { ...DEFAULTS, globalDeliveryFee, useDashboardDeliveryFee, ...contact };
  }

  return {
    deliveryEnabled: doc.deliveryEnabled !== false,
    deliveryPauseReason: doc.deliveryPauseReason ?? '',
    globalDeliveryFee,
    useDashboardDeliveryFee,
    ...contactSliceFromDoc(doc),
  };
}

/**
 * رسوم التوصيل الموحّدة للمنصة (تُستخدم عند إنشاء الطلبات بدل حقل المحل).
 */
async function getGlobalDeliveryFee() {
  await migrateLegacyAppContactOnce();
  const doc = await PlatformSettings.findById(PLATFORM_DOC_ID).select('globalDeliveryFee useDashboardDeliveryFee').lean();
  return resolveGlobalDeliveryFee(doc);
}

/**
 * @param {Partial<{
 *   deliveryEnabled: boolean,
 *   deliveryPauseReason: string,
 *   globalDeliveryFee: number,
 *   facebookUrl: string,
 *   instagramUrl: string,
 *   supportPhone: string,
 *   aboutUs: string,
 * }>} patch
 */
async function updatePlatformSettings(patch) {
  const set = {};
  if (patch.deliveryEnabled !== undefined) {
    set.deliveryEnabled = patch.deliveryEnabled !== false;
  }
  if (patch.deliveryPauseReason !== undefined) {
    set.deliveryPauseReason = String(patch.deliveryPauseReason ?? '').trim();
  }
  if (patch.globalDeliveryFee !== undefined) {
    const n = Number(patch.globalDeliveryFee);
    set.globalDeliveryFee = Number.isFinite(n) && n >= 0 ? n : 0;
    set.useDashboardDeliveryFee = true;
  }
  if (patch.facebookUrl !== undefined) {
    set.facebookUrl = String(patch.facebookUrl ?? '').trim();
  }
  if (patch.instagramUrl !== undefined) {
    set.instagramUrl = String(patch.instagramUrl ?? '').trim();
  }
  if (patch.supportPhone !== undefined) {
    set.supportPhone = String(patch.supportPhone ?? '').trim();
  }
  if (patch.aboutUs !== undefined) {
    set.aboutUs = String(patch.aboutUs ?? '').trim();
  }

  const doc = await PlatformSettings.findByIdAndUpdate(
    PLATFORM_DOC_ID,
    { $set: set },
    { upsert: true, new: true, setDefaultsOnInsert: true }
  ).lean();

  const globalDeliveryFee = resolveGlobalDeliveryFee(doc);

  return {
    deliveryEnabled: doc.deliveryEnabled !== false,
    deliveryPauseReason: doc.deliveryPauseReason ?? '',
    globalDeliveryFee,
    useDashboardDeliveryFee: !!doc.useDashboardDeliveryFee,
    ...contactSliceFromDoc(doc),
  };
}

/**
 * شكل استجابة GET /api/app-contact للتوافق مع التطبيقات القديمة (أرقام المحافظات تُرجع فارغة).
 */
async function getPublicContactPayload() {
  const s = await getPlatformSettings();
  return {
    facebookUrl: String(s.facebookUrl || '').trim() || DEFAULT_FACEBOOK_URL,
    instagramUrl: String(s.instagramUrl || '').trim() || DEFAULT_INSTAGRAM_URL,
    supportPhone: s.supportPhone || '',
    supportPhonesByRegion: [],
    supportPhoneKarbala: '',
    supportPhoneHilla: '',
    supportPhoneDiwaniya: '',
    aboutUs: s.aboutUs || '',
  };
}

module.exports = {
  getPlatformSettings,
  updatePlatformSettings,
  getGlobalDeliveryFee,
  getPublicContactPayload,
  DEFAULTS,
  DEFAULT_FACEBOOK_URL,
  DEFAULT_INSTAGRAM_URL,
};
