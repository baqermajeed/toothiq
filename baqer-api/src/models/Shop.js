const mongoose = require('mongoose');

const pointSchema = new mongoose.Schema(
  {
    type: { type: String, enum: ['Point'], default: 'Point' },
    coordinates: { type: [Number], required: true },
  },
  { _id: false }
);

const shopSchema = new mongoose.Schema(
  {
    ownerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    name: { type: String, required: true, trim: true },
    description: { type: String, trim: true, default: '' },
    location: { type: pointSchema, required: true },
    address: { type: String, trim: true, default: null },
    phone: { type: String, trim: true, default: null },
    phone2: { type: String, trim: true, default: null },
    deliveryFee: { type: Number, default: 0, min: 0 },
    isOpen: { type: Boolean, default: true },
    openHours: {
      from: { type: String, trim: true, default: '' },
      to: { type: String, trim: true, default: '' },
    },
    rating: { type: Number, default: 0 },
    ratingCount: { type: Number, default: 0 },
    isActive: { type: Boolean, default: true },
    isHidden: { type: Boolean, default: false },
    image: { type: String, trim: true },
    order: { type: Number, default: 0 },
  },
  { timestamps: true }
);

shopSchema.index({ location: '2dsphere' });
shopSchema.index({ ownerId: 1 });
shopSchema.index({ isActive: 1, isHidden: 1, order: 1 });

const Shop = mongoose.model('Shop', shopSchema);
module.exports = Shop;
