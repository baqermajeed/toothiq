const { User } = require('../models');
const { notFound } = require('../utils/errors');

async function getMe(userId) {
  const user = await User.findById(userId);
  if (!user) throw notFound('User not found');
  return User.toPublic(user);
}

async function updateMe(userId, body) {
  const { fcmToken, ...rest } = body;
  const updates = { ...rest };
  if (fcmToken !== undefined) {
    if (fcmToken && typeof fcmToken === 'string' && fcmToken.trim()) {
      await User.findByIdAndUpdate(userId, { $addToSet: { fcmTokens: fcmToken.trim() } });
    } else if (fcmToken === null) {
      await User.findByIdAndUpdate(userId, { $set: { fcmTokens: [] } });
    }
  }
  if (Object.keys(updates).length > 0) {
    await User.findByIdAndUpdate(userId, { $set: updates }, { runValidators: true });
  }
  const user = await User.findById(userId);
  if (!user) throw notFound('User not found');
  return User.toPublic(user);
}

module.exports = { getMe, updateMe };
