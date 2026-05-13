/**
 * Seed initial shop categories from constants into Category collection.
 * Run: node scripts/seed-categories.js
 * Requires: MONGODB_URI in .env or environment.
 */
require('dotenv').config();
const mongoose = require('mongoose');
const { connectDb } = require('../src/config/db');
const categoryService = require('../src/services/categoryService');
const { SHOP_CATEGORIES } = require('../src/config/constants');

const NAMES_WITH_ICONS = [
  { nameAr: 'مخضر', icon: '🥬' },
  { nameAr: 'غذائية', icon: '🛒' },
  { nameAr: 'لحوم', icon: '🥩' },
  { nameAr: 'مطاعم', icon: '🍽️' },
  { nameAr: 'بقالة', icon: '🛒' },
  { nameAr: 'حلويات', icon: '🍰' },
  { nameAr: 'مشروبات', icon: '🥤' },
  { nameAr: 'فواكه', icon: '🍎' },
  { nameAr: 'خضروات', icon: '🥕' },
  { nameAr: 'ألبان', icon: '🥛' },
];

async function run() {
  const names = SHOP_CATEGORIES && SHOP_CATEGORIES.length ? SHOP_CATEGORIES : NAMES_WITH_ICONS.map((x) => x.nameAr);
  const withIcons = names.map((nameAr, i) => {
    const found = NAMES_WITH_ICONS.find((n) => n.nameAr === nameAr);
    return { nameAr, icon: found ? found.icon : '' };
  });
  await connectDb();
  const result = await categoryService.seedFromConstants(withIcons);
  console.log('Categories seed done. Added:', result.added);
  await mongoose.connection.close();
  process.exit(0);
}

run().catch((err) => {
  console.error(err);
  process.exit(1);
});
