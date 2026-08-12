const { Notification } = require('../models');
const { notFound } = require('../utils/errors');

function mapNotification(doc) {
  return {
    id: doc._id.toString(),
    title: doc.title,
    body: doc.body,
    description: doc.body,
    type: doc.type,
    orderId: doc.orderId ? doc.orderId.toString() : null,
    data: doc.data || {},
    isRead: doc.isRead === true,
    createdAt: doc.createdAt,
  };
}

async function createForUser({
  userId,
  title,
  body,
  type,
  orderId = null,
  data = {},
}) {
  if (!userId) return null;
  const doc = await Notification.create({
    userId,
    title,
    body,
    type,
    orderId: orderId || null,
    data,
    isRead: false,
  });
  return mapNotification(doc);
}

async function listForUser(userId, { limit = 50 } = {}) {
  const safeLimit = Math.min(Math.max(Number(limit) || 50, 1), 100);
  const items = await Notification.find({ userId })
    .sort({ createdAt: -1 })
    .limit(safeLimit)
    .lean();
  return items.map(mapNotification);
}

async function unreadCount(userId) {
  return Notification.countDocuments({ userId, isRead: false });
}

async function markAsRead(userId, notificationId) {
  const doc = await Notification.findOne({ _id: notificationId, userId });
  if (!doc) throw notFound('الإشعار غير موجود');
  if (!doc.isRead) {
    doc.isRead = true;
    await doc.save();
  }
  return mapNotification(doc);
}

async function markAllAsRead(userId) {
  await Notification.updateMany(
    { userId, isRead: false },
    { $set: { isRead: true } }
  );
  return { ok: true };
}

module.exports = {
  createForUser,
  listForUser,
  unreadCount,
  markAsRead,
  markAllAsRead,
  mapNotification,
};
