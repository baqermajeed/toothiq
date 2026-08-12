const notificationService = require('../services/notificationService');

async function list(req, res, next) {
  try {
    const [items, unread] = await Promise.all([
      notificationService.listForUser(req.userId, { limit: req.query.limit }),
      notificationService.unreadCount(req.userId),
    ]);
    res.json({
      success: true,
      data: {
        items,
        unreadCount: unread,
      },
    });
  } catch (err) {
    next(err);
  }
}

async function unreadCount(req, res, next) {
  try {
    const count = await notificationService.unreadCount(req.userId);
    res.json({ success: true, data: { unreadCount: count } });
  } catch (err) {
    next(err);
  }
}

async function markAsRead(req, res, next) {
  try {
    const item = await notificationService.markAsRead(req.userId, req.params.id);
    res.json({ success: true, data: item });
  } catch (err) {
    next(err);
  }
}

async function markAllAsRead(req, res, next) {
  try {
    const data = await notificationService.markAllAsRead(req.userId);
    res.json({ success: true, data });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  list,
  unreadCount,
  markAsRead,
  markAllAsRead,
};
