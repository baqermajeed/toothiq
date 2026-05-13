/**
 * إنشاء مستخدم بدور admin أو إضافة الدور لحساب موجود.
 * التشغيل من جذر المشروع (baqer-api):
 *   node scripts/create-admin.js 07881234567 'كلمة_قوية_8+'
 *
 * يقرأ MONGODB_URI من ملف .env
 */
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

const bcrypt = require('bcrypt');
const { connectDb } = require('../src/config/db');
const { User } = require('../src/models');
const env = require('../src/config/env');

async function main() {
  const [, , phone, password, nameArg] = process.argv;
  if (!phone || !password) {
    console.error('الاستخدام: node scripts/create-admin.js <هاتف_١١_رقماً> <كلمة_المرور> [الاسم]');
    process.exit(1);
  }
  if (!/^[0-9]{11}$/.test(phone.trim())) {
    console.error('رقم الهاتف يجب أن يكون ١١ رقماً إنجليزياً (مثل 07881234567).');
    process.exit(1);
  }
  if (password.length < 8) {
    console.error('كلمة المرور ٨ أحرف على الأقل.');
    process.exit(1);
  }

  const name = (nameArg && String(nameArg).trim()) || 'مدير النظام';
  await connectDb();

  const p = phone.trim();
  let user = await User.findOne({ phone: p }).select('+passwordHash');

  if (user) {
    const roles = Array.isArray(user.roles) ? [...user.roles] : [];
    if (roles.includes('admin')) {
      console.log('المستخدم موجود مسبقاً ولديه دور admin:', p);
      process.exit(0);
    }
    roles.push('admin');
    user.roles = roles;
    await user.save();
    console.log('تمت إضافة دور admin. سجّل الدخول بنفس كلمة المرور الحالية للحساب:', p);
    process.exit(0);
  }

  const passwordHash = await bcrypt.hash(password, env.bcryptRounds);
  await User.create({
    name,
    phone: p,
    passwordHash,
    roles: ['admin'],
    governorateId: 'baghdad',
    isActive: true,
  });
  console.log('تم إنشاء حساب admin جديد:', p);
  process.exit(0);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
