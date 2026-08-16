const mongoose = require('mongoose');

const SECTIONS = ['all', 'offers', 'best_sellers', 'for_you', 'new', 'top_rated'];
const ITEM_TYPES = ['product', 'shop'];

const homeSectionPinSchema = new mongoose.Schema(
  {
    section: { type: String, required: true, enum: SECTIONS, index: true },
    itemType: { type: String, required: true, enum: ITEM_TYPES },
    productId: { type: mongoose.Schema.Types.ObjectId, ref: 'Product' },
    shopId: { type: mongoose.Schema.Types.ObjectId, ref: 'Shop' },
    order: { type: Number, default: 0 },
    isActive: { type: Boolean, default: true },
  },
  { timestamps: true }
);

homeSectionPinSchema.index({ section: 1, order: 1 });
homeSectionPinSchema.index(
  { section: 1, productId: 1 },
  { unique: true, sparse: true }
);
homeSectionPinSchema.index(
  { section: 1, shopId: 1 },
  { unique: true, sparse: true }
);

const HomeSectionPin = mongoose.model('HomeSectionPin', homeSectionPinSchema);
HomeSectionPin.SECTIONS = SECTIONS;
HomeSectionPin.ITEM_TYPES = ITEM_TYPES;
module.exports = HomeSectionPin;
