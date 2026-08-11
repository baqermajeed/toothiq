const mongoose = require('mongoose');

const driverWalletTransactionSchema = new mongoose.Schema(
  {
    driverId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    amount: { type: Number, required: true, min: 0 },
    type: { type: String, enum: ['collection'], default: 'collection' },
    collectedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    collectedByName: { type: String, trim: true, default: '' },
  },
  { timestamps: true }
);

driverWalletTransactionSchema.index({ driverId: 1, createdAt: -1 });

const DriverWalletTransaction = mongoose.model('DriverWalletTransaction', driverWalletTransactionSchema);
module.exports = DriverWalletTransaction;
