const authService = require('../services/authService');

async function register(req, res, next) {
  const { password: _omitPassword, ...registerPayloadSafe } = req.body || {};
  console.log('[Auth register] request', registerPayloadSafe);
  try {
    const result = await authService.register(req.body);
    console.log('[Auth register] success', {
      userId: result.user?._id?.toString(),
      phone: result.user?.phone,
      name: result.user?.name,
      roles: result.user?.roles,
    });
    res.status(201).json({ success: true, data: result });
  } catch (err) {
    console.log('[Auth register] error', {
      error: err.message,
      statusCode: err.statusCode,
      phone: req.body?.phone,
    });
    next(err);
  }
}

async function login(req, res, next) {
  try {
    const { phone, password } = req.body;
    const result = await authService.login(phone, password);
    res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
}

async function guestRegister(req, res, next) {
  console.log('[Auth guest-register] request', {
    name: req.body?.name,
    phone: req.body?.phone,
  });
  try {
    const result = await authService.guestRegister(req.body);
    console.log('[Auth guest-register] success', {
      userId: result.user?._id?.toString(),
      phone: result.user?.phone,
      name: result.user?.name,
    });
    res.status(201).json({ success: true, data: result });
  } catch (err) {
    console.log('[Auth guest-register] error', {
      error: err.message,
      statusCode: err.statusCode,
      phone: req.body?.phone,
    });
    next(err);
  }
}

async function logout(req, res, next) {
  try {
    await authService.logout(req.userId);
    res.json({ success: true, data: { message: 'Logged out' } });
  } catch (err) {
    next(err);
  }
}

module.exports = { register, login, guestRegister, logout };
