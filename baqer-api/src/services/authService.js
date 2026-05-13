const bcrypt = require('bcrypt');
const { User } = require('../models');
const env = require('../config/env');
const { signAccess } = require('../utils/tokens');
const { unauthorized, conflict } = require('../utils/errors');

/** Create user without tokens (e.g. for admin creating shop account). */
async function createUser(body) {
  const passwordHash = await bcrypt.hash(body.password, env.bcryptRounds);
  const roles = Array.isArray(body.roles) && body.roles.length > 0 ? body.roles : [body.role || 'customer'];
  const user = await User.create({
    name: body.name,
    phone: body.phone,
    email: body.email || undefined,
    passwordHash,
    roles,
    governorateId:
      body.governorateId != null && String(body.governorateId).trim() !== ''
        ? String(body.governorateId).trim()
        : null,
    clinicName:
      body.clinicName != null && String(body.clinicName).trim() !== ''
        ? String(body.clinicName).trim()
        : null,
    avatar: body.avatar || null,
  });
  const publicUser = User.toPublic(await User.findById(user._id));
  return publicUser;
}

async function register(body) {
  const existing = await User.findOne({ phone: body.phone?.trim() });
  if (existing) {
    throw conflict('رقم الهاتف مسجّل مسبقاً. جرّب تسجيل الدخول أو استعادة كلمة المرور.');
  }
  const publicUser = await createUser({
    ...body,
    roles: [body.role || 'customer'],
  });
  const accessToken = signAccess({ userId: publicUser._id.toString() });
  await User.findByIdAndUpdate(publicUser._id, { lastLoginAt: new Date() });
  return {
    user: publicUser,
    accessToken,
    expiresIn: env.jwt.accessExpiresIn,
  };
}

async function login(phone, password) {
  const users = await User.find({ phone }).select('+passwordHash');
  if (!users || users.length === 0) {
    throw unauthorized('رقم الهاتف أو كلمة المرور غير صحيحة.');
  }
  for (const user of users) {
    const valid = await bcrypt.compare(password, user.passwordHash);
    if (!valid) continue;
    if (!user.isActive) {
      throw unauthorized('الحساب معطّل. تواصل مع الدعم إذا كنت تعتقد أن هذا خطأ.');
    }
    const accessToken = signAccess({ userId: user._id.toString() });
    await User.findByIdAndUpdate(user._id, { lastLoginAt: new Date() });
    const publicUser = User.toPublic(await User.findById(user._id));
    return {
      user: publicUser,
      accessToken,
      expiresIn: env.jwt.accessExpiresIn,
    };
  }
  throw unauthorized('رقم الهاتف أو كلمة المرور غير صحيحة.');
}

async function logout(userId) {
  return { success: true };
}

function generateGuestCode() {
  const n = Math.floor(100000 + Math.random() * 900000);
  return String(n);
}

async function guestRegister(body) {
  const generatedCode = generateGuestCode();
  const passwordHash = await bcrypt.hash(generatedCode, env.bcryptRounds);
  const user = await User.create({
    name: body.name,
    phone: body.phone,
    passwordHash,
    roles: ['customer'],
  });
  const accessToken = signAccess({ userId: user._id.toString() });
  await User.findByIdAndUpdate(user._id, { lastLoginAt: new Date() });
  const publicUser = User.toPublic(await User.findById(user._id));
  return {
    user: publicUser,
    accessToken,
    expiresIn: env.jwt.accessExpiresIn,
    generatedCode,
  };
}

module.exports = { createUser, register, login, logout, guestRegister };
