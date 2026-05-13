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
    productId: { type: mongoose.Schema.Types.ObjectId, ref: 'Product', required: true },
    name: { type: String, required: true },
    price: { type: Number, required: true, min: 0 },
    quantity: { type: Number, required: true, min: 1 },
  },
  { _id: false }
);

const shopPortionSchema = new mongoose.Schema(
  {
    shopId: { type: mongoose.Schema.Types.ObjectId, ref: 'Shop', required: true },
    items: [orderItemSchema],
    subtotal: { type: Number, required: true, min: 0 },
  },
  { _id: false }
);

const statusHistorySchema = new mongoose.Schema(
  {
    status: { type: String, enum: Object.values(ORDER_STATUS), required: true },
    changedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    changedByRole: { type: String },
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
    /** كود الخصم المطبّق (إن وُجد). */
    discountCode: { type: String, trim: true, default: null },
    /** مبلغ الخصم المطبّق على مجموع المنتجات (لا يشمل التوصيل). */
    discountAmount: { type: Number, default: 0, min: 0 },
    status: {
      type: String,
      enum: Object.values(ORDER_STATUS),
      default: ORDER_STATUS.PENDING,
    },
    deliveryLocation: { type: pointSchema, required: true },
    notes: { type: String, trim: true },
    notesAudioUrl: { type: String, trim: true, default: null },
    cancelReason: { type: String, trim: true, default: null },
    postponedReason: { type: String, trim: true, default: null },
    statusHistory: [statusHistorySchema],
    // تسلسل داخلي للطلب (يُستخدم مع originalOrderId لتمييز الطلبات المكررة)
    orderNumber: { type: Number, index: true, unique: true, sparse: true },
    // إذا كان الطلب مكرراً، يشير إلى الطلب الأصلي داخل نفس النافذة الزمنية
    originalOrderId: { type: mongoose.Schema.Types.ObjectId, ref: 'Order', default: null },
    // حقل مريح للقراءة السريعة؛ يمكن اشتقاقه من originalOrderId
    isDuplicate: { type: Boolean, default: false },
  },
  { timestamps: true }
);

orderSchema.index({ customerId: 1, createdAt: -1 });
orderSchema.index({ shopId: 1, status: 1 });
orderSchema.index({ 'shopPortions.shopId': 1, status: 1 });
orderSchema.index({ driverId: 1, status: 1 });
orderSchema.index({ deliveryLocation: '2dsphere' });
orderSchema.index({ status: 1 });

const Order = mongoose.model('Order', orderSchema);
module.exports = Order;
