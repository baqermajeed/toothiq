function parseIraqiPrice(raw) {
  if (raw == null || raw === '') return null;
  if (typeof raw === 'number' && Number.isFinite(raw)) {
    return raw >= 0 ? Math.round(raw) : null;
  }
  let s = String(raw)
    .replace(/د\.ع\.?|د\.ك\.?|دينار|د\.ا|IQD|KWD/gi, '')
    .trim()
    .replace(/\s/g, '');
  if (!s) return null;
  if (/^\d{1,3}(?:\.\d{3})+$/.test(s)) {
    return Number(s.replace(/\./g, ''));
  }
  if (/^\d{1,3}(?:,\d{3})+$/.test(s)) {
    return Number(s.replace(/,/g, ''));
  }
  const n = Number(s.replace(/,/g, ''));
  return Number.isFinite(n) && n >= 0 ? Math.round(n) : null;
}

module.exports = { parseIraqiPrice };
