function parseIraqiPrice(raw) {
  if (raw == null || raw === '') return null;
  if (typeof raw === 'number' && Number.isFinite(raw)) {
    return raw >= 0 ? Math.round(raw) : null;
  }

  const indic = '٠١٢٣٤٥٦٧٨٩';
  let s = String(raw)
    .replace(/[\u200e\u200f\u202a-\u202e\u00a0\u202f\ufeff]/g, '')
    .replace(/[٠-٩]/g, (digit) => String(indic.indexOf(digit)));

  s = s.replace(/[٫]/g, '.').replace(/[٬،]/g, ',');
  s = s.replace(/د\s*[.٫]?\s*ع\s*[.٫]?/gi, '');
  s = s.replace(/د\s*[.٫]?\s*ك\s*[.٫]?/gi, '');
  s = s.replace(/دينار(?:\s*عراقي)?|IQD|KWD/gi, '');
  s = s.replace(/[^\d.,]/g, '');
  if (!s) return null;

  const thousandsDot = s.match(/^(\d{1,3}(?:\.\d{3})+)\.*$/);
  if (thousandsDot) {
    return Number(thousandsDot[1].replace(/\./g, ''));
  }

  const thousandsComma = s.match(/^(\d{1,3}(?:,\d{3})+)\.*$/);
  if (thousandsComma) {
    return Number(thousandsComma[1].replace(/,/g, ''));
  }

  const n = Number(s.replace(/,/g, ''));
  return Number.isFinite(n) && n >= 0 ? Math.round(n) : null;
}

module.exports = { parseIraqiPrice };
