const mongoose = require('mongoose');

const discountCodeSchema = new mongoose.Schema(
  {
    code: {
      type: String,
      required: true,
      unique: true,
      uppercase: true,
      trim: true,
      minlength: 4,
      maxlength: 32,
    },
    /** مبلغ الخصم الثابت (نفس عملة الطلب). */
    discountAmount: { type: Number, required: true, min: 0 },
    /** أقصى عدد مرات استخدام الكود على مستوى المنصة. */
    maxUses: { type: Number, required: true, min: 1 },
    usedCount: { type: Number, default: 0, min: 0 },
    isActive: { type: Boolean, default: true },
    expiresAt: { type: Date, default: null },
  },
  { timestamps: true }
);

discountCodeSchema.index({ isActive: 1, expiresAt: 1 });

const DiscountCode = mongoose.model('DiscountCode', discountCodeSchema);
module.exports = DiscountCode;
