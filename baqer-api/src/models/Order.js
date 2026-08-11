const mongoose = require('mongoose');
const { ORDER_STATUS } = require('../config/constants');

const pointSchema = new mongoose.Schema(
  {
    type: { type: String, enum: ['Point'], default: 'Point' },
    coordinates: { type: [Number], required: true },
  },
  { _id: false }
);

const orderItemSchema = new mongoose.Schema(
  {
    productId: { type: mongoose.Schema.Types.ObjectId, ref: 'Product' },
    name: { type: String, trim: true },
    price: { type: Number, required: true, min: 0 },
    quantity: { type: Number, required: true, min: 1 },
    image: { type: String, trim: true },
  },
  { _id: false }
);

const shopPortionSchema = new mongoose.Schema(
  {
    shopId: { type: mongoose.Schema.Types.ObjectId, ref: 'Shop' },
    items: [orderItemSchema],
    subtotal: { type: Number, default: 0 },
  },
  { _id: false }
);

const statusHistorySchema = new mongoose.Schema(
  {
    status: { type: String, required: true },
    changedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    changedByRole: { type: String, trim: true },
    changedAt: { type: Date, default: Date.now },
  },
  { _id: false }
);

const orderSchema = new mongoose.Schema(
  {
    customerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    shopId: { type: mongoose.Schema.Types.ObjectId, ref: 'Shop', default: null },
    driverId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
    items: [orderItemSchema],
    shopPortions: [shopPortionSchema],
    totalPrice: { type: Number, required: true, min: 0 },
    deliveryFee: { type: Number, required: true, min: 0 },
    discountCode: { type: String, trim: true, default: null },
    discountAmount: { type: Number, default: 0, min: 0 },
    status: {
      type: String,
      enum: Object.values(ORDER_STATUS),
      default: ORDER_STATUS.PENDING,
    },
    deliveryLocation: { type: pointSchema, required: true },
    deliveryAddress: { type: String, trim: true, default: null },
    notes: { type: String, trim: true, default: '' },
    notesAudioUrl: { type: String, trim: true, default: null },
    cancelReason: { type: String, trim: true, default: null },
    postponedReason: { type: String, trim: true, default: null },
    statusHistory: [statusHistorySchema],
    orderNumber: { type: Number },
    originalOrderId: { type: mongoose.Schema.Types.ObjectId, ref: 'Order', default: null },
    isDuplicate: { type: Boolean, default: false },
  },
  { timestamps: true }
);

orderSchema.index({ customerId: 1, createdAt: -1 });
orderSchema.index({ shopId: 1, status: 1, createdAt: -1 });
orderSchema.index({ driverId: 1, status: 1, createdAt: -1 });
orderSchema.index({ status: 1, createdAt: -1 });

const Order = mongoose.model('Order', orderSchema);
module.exports = Order;
