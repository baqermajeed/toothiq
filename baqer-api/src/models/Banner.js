const mongoose = require('mongoose');

const polygonSchema = new mongoose.Schema(
  {
    type: { type: String, enum: ['Polygon'], default: 'Polygon' },
    coordinates: {
      type: [[[Number]]],
      required: true,
    },
  },
  { _id: false }
);

const bannerSchema = new mongoose.Schema(
  {
    image: { type: String, required: true, trim: true },
    title: { type: String, trim: true },
    actionType: {
      type: String,
      enum: ['shop', 'product', 'external_url'],
      required: true,
    },
    shopId: { type: mongoose.Schema.Types.ObjectId, ref: 'Shop' },
    productId: { type: mongoose.Schema.Types.ObjectId, ref: 'Product' },
    externalUrl: { type: String, trim: true },
    order: { type: Number, default: 0 },
    isActive: { type: Boolean, default: true },
    /** منطقة بوليكان — يُعرض البانر فقط للمستخدمين داخل هذه المنطقة (عند ALLOW_GLOBAL_ACCESS=false). */
    polygon: { type: polygonSchema },
  },
  { timestamps: true }
);

bannerSchema.index({ isActive: 1, order: 1 });
bannerSchema.index({ polygon: '2dsphere' });

const Banner = mongoose.model('Banner', bannerSchema);
module.exports = Banner;
