const mongoose = require('mongoose');

const driverWalletSchema = new mongoose.Schema(
  {
    driverId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
    totalCollected: { type: Number, default: 0, min: 0 },
  },
  { timestamps: true }
);

const DriverWallet = mongoose.model('DriverWallet', driverWalletSchema);
module.exports = DriverWallet;
