const { Order, User, DriverWallet, DriverWalletTransaction } = require('../models');
const { ORDER_STATUS } = require('../config/constants');
const env = require('../config/env');
const { notFound, badRequest } = require('../utils/errors');
const fcmService = require('./fcmService');

/** حالات الطلبات التي تُحتسب في إجمالي مستحقات المحفظة */
const WALLET_QUALIFYING_STATUSES = [
  ORDER_STATUS.ACCEPTED,
  ORDER_STATUS.PREPARING,
  ORDER_STATUS.ON_THE_WAY,
  ORDER_STATUS.DELIVERED,
];

async function assertDriverUser(driverId) {
  const user = await User.findById(driverId).select('roles name').lean();
  if (!user) throw notFound('السائق غير موجود');
  if (!Array.isArray(user.roles) || !user.roles.includes('driver')) {
    throw badRequest('المستخدم ليس سائقاً', 'NOT_A_DRIVER');
  }
  return user;
}

async function countQualifyingOrders(driverId) {
  return Order.countDocuments({
    driverId,
    status: { $in: WALLET_QUALIFYING_STATUSES },
  });
}

async function sumDeliveryFeesEarned(driverId) {
  const result = await Order.aggregate([
    {
      $match: {
        driverId,
        status: ORDER_STATUS.DELIVERED,
      },
    },
    { $group: { _id: null, total: { $sum: '$deliveryFee' } } },
  ]);
  return result[0]?.total ?? 0;
}

async function getOrCreateWallet(driverId) {
  let wallet = await DriverWallet.findOne({ driverId });
  if (!wallet) {
    wallet = await DriverWallet.create({ driverId, totalCollected: 0 });
  }
  return wallet;
}

async function getWalletSummary(driverId) {
  await assertDriverUser(driverId);
  const [wallet, qualifyingCount, deliveryFeesEarned] = await Promise.all([
    getOrCreateWallet(driverId),
    countQualifyingOrders(driverId),
    sumDeliveryFeesEarned(driverId),
  ]);

  const ratePerOrder = env.driverWalletRatePerOrder;
  const totalEarned = qualifyingCount * ratePerOrder;
  const totalCollected = Number(wallet.totalCollected ?? 0);
  const balance = Math.max(0, totalEarned - totalCollected);

  return {
    driverId: String(driverId),
    ratePerOrder,
    qualifyingOrdersCount: qualifyingCount,
    totalEarned,
    deliveryFeesEarned,
    totalCollected,
    balance,
  };
}

async function listTransactions(driverId, { page = 1, limit = 20 } = {}) {
  await assertDriverUser(driverId);
  const skip = (Number(page) - 1) * Number(limit);
  const [items, total] = await Promise.all([
    DriverWalletTransaction.find({ driverId })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(Number(limit))
      .lean(),
    DriverWalletTransaction.countDocuments({ driverId }),
  ]);
  return {
    items: items.map((t) => ({
      id: String(t._id),
      amount: t.amount,
      type: t.type,
      collectedByName: t.collectedByName || '',
      createdAt: t.createdAt,
    })),
    pagination: { page: Number(page), limit: Number(limit), total },
  };
}

async function getWallet(driverId, { page = 1, limit = 20, includeTransactions = true } = {}) {
  const summary = await getWalletSummary(driverId);
  if (!includeTransactions) return summary;
  const transactions = await listTransactions(driverId, { page, limit });
  return { ...summary, transactions };
}

function notifyDriverWalletCollection(driverId, amount, collectedByName, createdAt) {
  User.findById(driverId)
    .select('fcmTokens')
    .lean()
    .then((user) => {
      const tokens = user?.fcmTokens || [];
      if (tokens.length === 0) return;
      const dateStr = createdAt
        ? new Date(createdAt).toLocaleString('ar-IQ', { timeZone: 'Asia/Baghdad' })
        : '';
      const body = `تم استحصال مبلغ ${amount.toLocaleString('ar-IQ')} د.ع من قبل ${collectedByName}${dateStr ? ` في ${dateStr}` : ''}`;
      return fcmService.sendToTokens(tokens, {
        title: 'استحصال من المحفظة',
        body,
        data: { type: 'wallet_collection', amount: String(amount) },
      });
    })
    .catch((err) => console.error('[FCM] notifyDriverWalletCollection:', err.message));
}

async function collectFromWallet(driverId, adminUserId, adminName, amount) {
  const n = Number(amount);
  if (!Number.isFinite(n) || n <= 0) {
    throw badRequest('المبلغ يجب أن يكون أكبر من صفر', 'INVALID_AMOUNT');
  }

  await assertDriverUser(driverId);
  const summary = await getWalletSummary(driverId);
  if (n > summary.balance) {
    throw badRequest('المبلغ أكبر من الرصيد المتبقي', 'INSUFFICIENT_BALANCE');
  }

  const wallet = await getOrCreateWallet(driverId);
  const collectedByName = (adminName || '').trim() || 'الإدارة';
  const tx = await DriverWalletTransaction.create({
    driverId,
    amount: n,
    type: 'collection',
    collectedBy: adminUserId,
    collectedByName,
  });
  wallet.totalCollected = Number(wallet.totalCollected ?? 0) + n;
  await wallet.save();

  notifyDriverWalletCollection(driverId, n, collectedByName, tx.createdAt);

  const updated = await getWallet(driverId, { page: 1, limit: 10 });
  return {
    ...updated,
    lastTransaction: {
      id: String(tx._id),
      amount: tx.amount,
      collectedByName: tx.collectedByName,
      createdAt: tx.createdAt,
    },
  };
}

module.exports = {
  WALLET_QUALIFYING_STATUSES,
  getWallet,
  getWalletSummary,
  listTransactions,
  collectFromWallet,
};
