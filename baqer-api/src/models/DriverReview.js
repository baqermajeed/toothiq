const mongoose = require('mongoose');

const driverReviewSchema = new mongoose.Schema(
  {
    orderId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Order',
      required: true,
    },
    driverId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    customerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    rating: { type: Number, required: true, min: 1, max: 5 },
    comment: { type: String, trim: true, maxlength: 500, default: '' },
  },
  { timestamps: true }
);

driverReviewSchema.index({ orderId: 1 }, { unique: true });
driverReviewSchema.index({ driverId: 1, createdAt: -1 });
driverReviewSchema.index({ customerId: 1, createdAt: -1 });

const DriverReview = mongoose.model('DriverReview', driverReviewSchema);
module.exports = DriverReview;
