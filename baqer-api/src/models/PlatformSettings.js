const mongoose = require('mongoose');

const PLATFORM_DOC_ID = 'platform';

const platformSettingsSchema = new mongoose.Schema(
  {
    _id: { type: String, default: PLATFORM_DOC_ID },
    deliveryEnabled: { type: Boolean, default: true },
    deliveryPauseReason: { type: String, default: '', trim: true },
    /** رسوم التوصيل الموحّدة للتطبيق (تُستخدم بدل رسوم المحل عند إنشاء الطلبات). */
    globalDeliveryFee: { type: Number, default: 0, min: 0 },
    /**
     * عند true: تُستخدم `globalDeliveryFee` من قاعدة البيانات حتى لو كان مصدر إعدادات المنصة env
     * (بعد حفظ المدير للرسوم من لوحة الإدارة).
     */
    useDashboardDeliveryFee: { type: Boolean, default: false },
    facebookUrl: { type: String, default: '', trim: true },
    instagramUrl: { type: String, default: '', trim: true },
    /** رقم دعم واحد للتطبيق (ليس حسب المحافظة). */
    supportPhone: { type: String, default: '', trim: true },
    /** نص «من نحن» يعرضه التطبيق (يمكن أن يحتوي على أسطر جديدة). */
    aboutUs: { type: String, default: '', trim: true },
  },
  { collection: 'platformsettings' }
);

const PlatformSettings = mongoose.model('PlatformSettings', platformSettingsSchema);

module.exports = { PlatformSettings, PLATFORM_DOC_ID };
