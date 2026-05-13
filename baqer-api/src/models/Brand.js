const mongoose = require('mongoose');

const brandSchema = new mongoose.Schema(
  {
    categoryId: { type: mongoose.Schema.Types.ObjectId, ref: 'Category', required: true },
    nameAr: { type: String, required: true, trim: true },
    order: { type: Number, default: 0 },
    isActive: { type: Boolean, default: true },
  },
  { timestamps: true }
);

brandSchema.index({ categoryId: 1, order: 1, isActive: 1 });
brandSchema.index({ categoryId: 1, nameAr: 1 }, { unique: true });

const Brand = mongoose.model('Brand', brandSchema);
module.exports = Brand;
