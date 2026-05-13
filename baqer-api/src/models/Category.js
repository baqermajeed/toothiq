const mongoose = require('mongoose');

const categorySchema = new mongoose.Schema(
  {
    nameAr: { type: String, required: true, trim: true },
    icon: { type: String, trim: true, default: '' },
    order: { type: Number, default: 0 },
    isActive: { type: Boolean, default: true },
  },
  { timestamps: true }
);

categorySchema.index({ order: 1, isActive: 1 });

const Category = mongoose.model('Category', categorySchema);
module.exports = Category;
