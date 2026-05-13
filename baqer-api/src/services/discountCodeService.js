const crypto = require('crypto');
const DiscountCode = require('../models/DiscountCode');
const { badRequest, notFound } = require('../utils/errors');

const CODE_CHARS = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

function normalizeCode(raw) {
  return String(raw || '')
    .trim()
    .toUpperCase()
    .replace(/\s+/g, '');
}

function generateCode(length = 8) {
  const bytes = crypto.randomBytes(length);
  let out = '';
  for (let i = 0; i < length; i += 1) {
    out += CODE_CHARS[bytes[i] % CODE_CHARS.length];
  }
  return out;
}

function _couponQueryAtDate(now) {
  return {
    isActive: true,
    $or: [{ expiresAt: null }, { expiresAt: { $gt: now } }],
  };
}

function _appliedAmount(coupon, merchandiseSubtotal) {
  const sub = Number(merchandiseSubtotal);
  if (!Number.isFinite(sub) || sub <= 0) {
    throw badRequest('لا يمكن تطبيق الخصم على سلة فارغة');
  }
  const cap = Number(coupon.discountAmount);
  const applied = Math.min(cap, sub);
  if (!Number.isFinite(applied) || applied <= 0) {
    throw badRequest('لا يمكن تطبيق هذا الكود على هذا الطلب');
  }
  return applied;
}

/**
 * تحقق من صلاحية الكود وحساب مبلغ الخصم دون زيادة العداد.
 */
async function previewCode(normalizedCode, merchandiseSubtotal) {
  const code = normalizeCode(normalizedCode);
  if (!code) throw badRequest('كود الخصم مطلوب');
  const now = new Date();
  const coupon = await DiscountCode.findOne({ code, ..._couponQueryAtDate(now) }).lean();
  if (!coupon) throw badRequest('كود الخصم غير صالح أو منتهي');
  if (coupon.usedCount >= coupon.maxUses) {
    throw badRequest('انتهت الاستخدامات المسموحة لهذا الكود');
  }
  const appliedAmount = _appliedAmount(coupon, merchandiseSubtotal);
  return { appliedAmount, code: coupon.code };
}

/**
 * يحجز استخداماً واحداً (يزيد usedCount) ويُرجع مبلغ الخصم المطبّق.
 * يجب استدعاء [releaseConsumption] إن فشل إنشاء الطلب بعد النجاح هنا.
 */
async function consumeCode(normalizedCode, merchandiseSubtotal) {
  const code = normalizeCode(normalizedCode);
  if (!code) throw badRequest('كود الخصم مطلوب');
  const now = new Date();
  const coupon = await DiscountCode.findOne({ code, ..._couponQueryAtDate(now) });
  if (!coupon) throw badRequest('كود الخصم غير صالح أو منتهي');
  if (coupon.usedCount >= coupon.maxUses) {
    throw badRequest('انتهت الاستخدامات المسموحة لهذا الكود');
  }
  const appliedAmount = _appliedAmount(coupon, merchandiseSubtotal);
  const updated = await DiscountCode.findOneAndUpdate(
    {
      _id: coupon._id,
      usedCount: coupon.usedCount,
      isActive: true,
      $or: [{ expiresAt: null }, { expiresAt: { $gt: now } }],
      $expr: { $lt: ['$usedCount', '$maxUses'] },
    },
    { $inc: { usedCount: 1 } },
    { new: true }
  );
  if (!updated) {
    throw badRequest('تعذر استخدام الكود، حاول مرة أخرى');
  }
  return { appliedAmount, code: coupon.code, couponId: coupon._id };
}

async function releaseConsumption(couponId) {
  if (!couponId) return;
  await DiscountCode.updateOne({ _id: couponId, usedCount: { $gt: 0 } }, { $inc: { usedCount: -1 } });
}

async function listForAdmin() {
  const items = await DiscountCode.find({}).sort({ createdAt: -1 }).lean();
  return items;
}

async function createForAdmin(payload) {
  const discountAmount = Number(payload.discountAmount);
  const maxUses = Number(payload.maxUses);
  if (!Number.isFinite(discountAmount) || discountAmount <= 0) {
    throw badRequest('مبلغ الخصم يجب أن يكون أكبر من صفر');
  }
  if (!Number.isFinite(maxUses) || maxUses < 1) {
    throw badRequest('عدد الاستخدامات يجب أن يكون 1 على الأقل');
  }
  let code = payload.code ? normalizeCode(payload.code) : generateCode(8);
  if (code.length < 4 || code.length > 32) {
    throw badRequest('الكود يجب أن يكون بين 4 و 32 حرفاً');
  }
  if (!/^[A-Z0-9]+$/.test(code)) {
    throw badRequest('الكود يقبل أحرف إنجليزية وأرقام فقط');
  }
  const exists = await DiscountCode.findOne({ code }).select('_id').lean();
  if (exists) throw badRequest('هذا الكود مستخدم مسبقاً');

  let expiresAt = null;
  if (payload.expiresAt != null && String(payload.expiresAt).trim() !== '') {
    const d = new Date(payload.expiresAt);
    if (Number.isNaN(d.getTime())) throw badRequest('تاريخ انتهاء غير صالح');
    expiresAt = d;
  }

  const doc = await DiscountCode.create({
    code,
    discountAmount,
    maxUses,
    usedCount: 0,
    isActive: payload.isActive !== false,
    expiresAt,
  });
  return doc;
}

async function updateForAdmin(id, payload) {
  const doc = await DiscountCode.findById(id);
  if (!doc) throw notFound('كود الخصم غير موجود');
  if (payload.isActive != null) doc.isActive = Boolean(payload.isActive);
  if (payload.discountAmount != null) {
    const n = Number(payload.discountAmount);
    if (!Number.isFinite(n) || n <= 0) throw badRequest('مبلغ الخصم غير صالح');
    doc.discountAmount = n;
  }
  if (payload.maxUses != null) {
    const n = Number(payload.maxUses);
    if (!Number.isFinite(n) || n < 1) throw badRequest('عدد الاستخدامات غير صالح');
    if (n < doc.usedCount) {
      throw badRequest('maxUses لا يمكن أن يكون أقل من عدد الاستخدامات الحالي');
    }
    doc.maxUses = n;
  }
  await doc.save();
  return doc;
}

async function removeForAdmin(id) {
  const r = await DiscountCode.deleteOne({ _id: id });
  if (r.deletedCount === 0) throw notFound('كود الخصم غير موجود');
}

module.exports = {
  normalizeCode,
  generateCode,
  previewCode,
  consumeCode,
  releaseConsumption,
  listForAdmin,
  createForAdmin,
  updateForAdmin,
  removeForAdmin,
};
