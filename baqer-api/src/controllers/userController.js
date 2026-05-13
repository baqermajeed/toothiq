const userService = require('../services/userService');

async function getMe(req, res, next) {
  try {
    const user = await userService.getMe(req.userId);
    res.json({ success: true, data: user });
  } catch (err) {
    next(err);
  }
}

async function updateMe(req, res, next) {
  try {
    const user = await userService.updateMe(req.userId, req.body);
    res.json({ success: true, data: user });
  } catch (err) {
    next(err);
  }
}

module.exports = { getMe, updateMe };
