const mongoose = require('mongoose');

const productSchema = new mongoose.Schema(
  {
    shopId: { type: mongoose.Schema.Types.ObjectId, ref: 'Shop', required: true },
    name: { type: String, required: true, trim: true },
    description: { type: String, trim: true },
    price: { type: Number, required: true, min: 0 },
    image: { type: String, trim: true },
    images: [{ type: String, trim: true }],
    isAvailable: { type: Boolean, default: true },
    categoryId: { type: mongoose.Schema.Types.ObjectId, ref: 'Category' },
    subcategoryId: { type: mongoose.Schema.Types.ObjectId, ref: 'ProductSubcategory' },
    brandId: { type: mongoose.Schema.Types.ObjectId, ref: 'ProductBrand' },
    productCategoryId: { type: mongoose.Schema.Types.ObjectId, ref: 'ProductCategory' },
    offerPrice: { type: Number, min: 0 },
    offerEndsAt: { type: Date },
    stock: { type: Number, default: 0, min: 0 },
    productionDate: { type: Date },
    expiryDate: { type: Date },
  },
  { timestamps: true }
);

productSchema.index({ shopId: 1 });
productSchema.index({ isAvailable: 1, shopId: 1, createdAt: -1 });
productSchema.index({ shopId: 1, name: 1 });
productSchema.index({ categoryId: 1, subcategoryId: 1 });
productSchema.index({ categoryId: 1, brandId: 1 });
productSchema.index({ shopId: 1, categoryId: 1, subcategoryId: 1 });
productSchema.index({ shopId: 1, categoryId: 1, brandId: 1 });

const Product = mongoose.model('Product', productSchema);
module.exports = Product;
