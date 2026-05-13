const mongoose = require('mongoose');

const pointSchema = new mongoose.Schema(
  {
    type: { type: String, enum: ['Point'], default: 'Point' },
    coordinates: { type: [Number], required: true },
  },
  { _id: false }
);

const openHoursSchema = new mongoose.Schema(
  {
    from: { type: String, trim: true },
    to: { type: String, trim: true },
  },
  { _id: false }
);

const shopSchema = new mongoose.Schema(
  {
    ownerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    name: { type: String, required: true, trim: true },
    description: { type: String, trim: true },
    location: { type: pointSchema, required: true },
    deliveryFee: { type: Number, default: 0, min: 0 },
    isOpen: { type: Boolean, default: true },
    openHours: { type: openHoursSchema },
    rating: { type: Number, default: 0, min: 0, max: 5 },
    ratingCount: { type: Number, default: 0, min: 0 },
    isActive: { type: Boolean, default: true },
    isHidden: { type: Boolean, default: false },
    image: { type: String, trim: true },
    order: { type: Number, default: 0 },
  },
  { timestamps: true }
);

shopSchema.index({ location: '2dsphere' });
shopSchema.index({ ownerId: 1 });
shopSchema.index({ isActive: 1, isOpen: 1 });

const Shop = mongoose.model('Shop', shopSchema);
module.exports = Shop;
