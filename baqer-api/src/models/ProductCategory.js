const mongoose = require('mongoose');

const productCategorySchema = new mongoose.Schema(
  {
    shopId: { type: mongoose.Schema.Types.ObjectId, ref: 'Shop', required: true },
    parentCategoryId: { type: mongoose.Schema.Types.ObjectId, ref: 'Category' },
    subcategoryId: { type: mongoose.Schema.Types.ObjectId, ref: 'ProductSubcategory' },
    nameAr: { type: String, required: true, trim: true },
    order: { type: Number, default: 0 },
    isActive: { type: Boolean, default: true },
    image: { type: String, trim: true },
  },
  { timestamps: true }
);

productCategorySchema.index({ shopId: 1 });
productCategorySchema.index({ shopId: 1, parentCategoryId: 1 });
productCategorySchema.index({ shopId: 1, subcategoryId: 1 });
productCategorySchema.index({ shopId: 1, order: 1, isActive: 1 });

const ProductCategory = mongoose.model('ProductCategory', productCategorySchema);
module.exports = ProductCategory;
