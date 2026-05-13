const mongoose = require('mongoose');

const shopReviewSchema = new mongoose.Schema(
  {
    shopId: { type: mongoose.Schema.Types.ObjectId, ref: 'Shop', required: true },
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    rating: { type: Number, required: true, min: 1, max: 5 },
    comment: { type: String, required: true, trim: true, maxlength: 1000 },
  },
  { timestamps: true }
);

shopReviewSchema.index({ shopId: 1, userId: 1 }, { unique: true });
shopReviewSchema.index({ shopId: 1, createdAt: -1 });

const ShopReview = mongoose.model('ShopReview', shopReviewSchema);
module.exports = ShopReview;
