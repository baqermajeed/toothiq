const mongoose = require('mongoose');

/**
 * إعدادات تواصل التطبيق (حساب واحد فقط).
 * facebookUrl, instagramUrl, supportPhone* تُعرض في صفحة الملف الشخصي.
 */
const appContactSchema = new mongoose.Schema(
  {
    facebookUrl: { type: String, trim: true, default: '' },
    instagramUrl: { type: String, trim: true, default: '' },
    supportPhone: { type: String, trim: true, default: '' },
    supportPhonesByRegion: {
      type: [
        new mongoose.Schema(
          {
            region: { type: String, trim: true, default: '' },
            phone: { type: String, trim: true, default: '' },
          },
          { _id: false }
        ),
      ],
      default: [],
    },
    supportPhoneKarbala: { type: String, trim: true, default: '' },
    supportPhoneHilla: { type: String, trim: true, default: '' },
    supportPhoneDiwaniya: { type: String, trim: true, default: '' },
  },
  { timestamps: true }
);

const AppContact = mongoose.model('AppContact', appContactSchema);
module.exports = AppContact;
