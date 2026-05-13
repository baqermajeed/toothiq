const mongoose = require('mongoose');
const { ROLES } = require('../config/constants');

const pointSchema = new mongoose.Schema(
  {
    type: { type: String, enum: ['Point'], default: 'Point' },
    coordinates: { type: [Number], required: true },
  },
  { _id: false }
);

const userSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    /** معرف المحافظة من قائمة النظام (مثل baghdad) — يُفرَض عند التسجيل عبر الـ API */
    governorateId: { type: String, trim: true, default: null },
    /** اسم العيادة — اختياري */
    clinicName: { type: String, trim: true, default: null },
    phone: {
      type: String,
      required: true,
      trim: true,
      minlength: 11,
      maxlength: 11,
      match: /^[0-9\u0660-\u0669]{11}$/,
    },
    email: { type: String, trim: true, sparse: true },
    passwordHash: { type: String, required: true, select: false },
    roles: {
      type: [String],
      enum: Object.values(ROLES),
      default: [ROLES.CUSTOMER],
    },
    location: { type: pointSchema, default: null },
    avatar: { type: String, default: null, trim: true },
    isActive: { type: Boolean, default: true },
    refreshTokenHash: { type: String, select: false },
    lastLoginAt: { type: Date },
    fcmTokens: { type: [String], default: [], select: false },
  },
  { timestamps: true }
);

userSchema.index({ location: '2dsphere' });
userSchema.index({ roles: 1, isActive: 1 });

function toPublic(doc) {
  const obj = doc.toObject ? doc.toObject() : doc;
  delete obj.passwordHash;
  delete obj.refreshTokenHash;
  delete obj.fcmTokens;
  return obj;
}

userSchema.statics.toPublic = toPublic;

const User = mongoose.model('User', userSchema);
module.exports = User;
