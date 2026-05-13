/**
 * المحافظات العراقية المعترف بها في النظام (معرّف ثابت + الاسم بالعربية).
 * يمكن لاحقاً إضافة بلدان أخرى أو جلب القائمة من قاعدة البيانات بنفس شكل المعرفات.
 */
const IRAQ_GOVERNORATES = [
  { id: 'baghdad', nameAr: 'بغداد' },
  { id: 'basra', nameAr: 'البصرة' },
  { id: 'nineveh', nameAr: 'نينوى' },
  { id: 'erbil', nameAr: 'أربيل' },
  { id: 'sulaymaniyah', nameAr: 'السليمانية' },
  { id: 'duhok', nameAr: 'دهوك' },
  { id: 'kirkuk', nameAr: 'كركوك' },
  { id: 'salahuddin', nameAr: 'صلاح الدين' },
  { id: 'diyala', nameAr: 'ديالى' },
  { id: 'anbar', nameAr: 'الأنبار' },
  { id: 'najaf', nameAr: 'النجف' },
  { id: 'karbala', nameAr: 'كربلاء' },
  { id: 'babylon', nameAr: 'بابل' },
  { id: 'wasit', nameAr: 'واسط' },
  { id: 'qadisiyyah', nameAr: 'القادسية' },
  { id: 'muthanna', nameAr: 'المثنى' },
  { id: 'dhi_qar', nameAr: 'ذي قار' },
  { id: 'maysan', nameAr: 'ميسان' },
];

const GOVERNORATE_IDS = IRAQ_GOVERNORATES.map((g) => g.id);

function isValidIraqGovernorateId(id) {
  return typeof id === 'string' && GOVERNORATE_IDS.includes(id.trim());
}

module.exports = {
  IRAQ_GOVERNORATES,
  GOVERNORATE_IDS,
  isValidIraqGovernorateId,
};
