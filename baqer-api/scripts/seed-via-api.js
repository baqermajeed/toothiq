/**
 * Seed data via API using admin credentials.
 * Usage: node scripts/seed-via-api.js
 * Requires: API server running (e.g. npm run dev), admin user 07801275675 / 12345678
 * ddddd
 */

const BASE = process.env.API_BASE || 'http://localhost:3000';

const ADMIN = {
  phone: '07801275675',
  password: '12345678',
};

const CATEGORIES = [
  'مخضر',
  'غذائية',
  'لحوم',
  'مطاعم',
  'بقالة',
  'حلويات',
  'مشروبات',
  'فواكه',
  'خضروات',
  'ألبان',
];

const SHOP_NAMES = [
  'متجر الخضر الطازجة',
  'سوبر ماركت الغذاء',
  'لحوم الحسين',
  'مطعم البيت العراقي',
  'بقالة النور',
  'حلويات الشرق',
  'مشروبات البارد',
  'فواكه الموسم',
  'خضروات الحديقة',
  'ألبان الطبيعة',
];

const PRODUCT_SAMPLES = [
  { name: 'منتج مميز ١', description: 'وصف المنتج الأول', price: 5000 },
  { name: 'منتج مميز ٢', description: 'وصف المنتج الثاني', price: 7500 },
  { name: 'عرض خاص ١', description: 'منتج بعرض خاص', price: 3200 },
  { name: 'عرض خاص ٢', description: 'منتج بعرض خاص', price: 4800 },
  { name: 'باقة أسبوعية ١', description: 'باقة أسبوعية', price: 15000 },
  { name: 'باقة أسبوعية ٢', description: 'باقة أسبوعية', price: 22000 },
  { name: 'طازج يومي ١', description: 'منتج طازج', price: 2500 },
  { name: 'طازج يومي ٢', description: 'منتج طازج', price: 4000 },
  { name: 'كلاسيك ١', description: 'منتج كلاسيكي', price: 6000 },
  { name: 'كلاسيك ٢', description: 'منتج كلاسيكي', price: 8500 },
  { name: 'اقتصادي ١', description: 'منتج اقتصادي', price: 1800 },
  { name: 'اقتصادي ٢', description: 'منتج اقتصادي', price: 2100 },
  { name: 'بريميوم ١', description: 'منتج بريميوم', price: 12000 },
  { name: 'بريميوم ٢', description: 'منتج بريميوم', price: 16000 },
  { name: 'عائلي ١', description: 'حجم عائلي', price: 9500 },
  { name: 'عائلي ٢', description: 'حجم عائلي', price: 11000 },
  { name: 'سناك ١', description: 'سناك سريع', price: 1500 },
  { name: 'سناك ٢', description: 'سناك سريع', price: 2800 },
  { name: 'صحي ١', description: 'منتج صحي', price: 5500 },
  { name: 'صحي ٢', description: 'منتج صحي', price: 7200 },
];

async function request(method, path, body = null, token = null) {
  const url = `${BASE}${path}`;
  const opts = {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
  };
  if (body && (method === 'POST' || method === 'PATCH')) opts.body = JSON.stringify(body);
  const res = await fetch(url, opts);
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data.error?.message || data.message || res.statusText || `HTTP ${res.status}`);
  return data;
}

async function login() {
  const data = await request('POST', '/api/auth/login', {
    phone: ADMIN.phone,
    password: ADMIN.password,
  });
  const token = data.data?.accessToken;
  if (!token) throw new Error('No accessToken in login response');
  return token;
}

async function createShop(token, name, category, index) {
  const body = {
    name,
    description: `متجر لـ ${category}`,
    category,
    location: { type: 'Point', coordinates: [44.36 + index * 0.01, 33.31 + index * 0.01] },
    deliveryFee: 1000 + index * 500,
  };
  const data = await request('POST', '/api/shops', body, token);
  const shop = data.data;
  return shop?._id?.toString() || shop?.id;
}

async function createProduct(token, shopId, product) {
  const body = {
    name: product.name,
    description: product.description,
    price: product.price,
  };
  const data = await request('POST', `/api/shops/${shopId}/products`, body, token);
  const created = data.data;
  return created?._id?.toString() || created?.id;
}

async function main() {
  console.log('API Base:', BASE);
  console.log('Login...');
  const token = await login();
  console.log('Logged in.\n');

  const shopIds = [];
  console.log('Creating 10 shops...');
  for (let i = 0; i < 10; i++) {
    const id = await createShop(token, SHOP_NAMES[i], CATEGORIES[i], i);
    shopIds.push(id);
    console.log(`  Shop ${i + 1}: ${SHOP_NAMES[i]} (${CATEGORIES[i]}) -> ${id}`);
  }

  console.log('\nCreating 20 products (2 per shop)...');
  let productIndex = 0;
  for (let s = 0; s < 10; s++) {
    for (let p = 0; p < 2; p++) {
      const prod = PRODUCT_SAMPLES[productIndex];
      const id = await createProduct(token, shopIds[s], prod);
      console.log(`  Product ${productIndex + 1}: ${prod.name} @ shop ${s + 1} -> ${id}`);
      productIndex++;
    }
  }

  console.log('\nDone. 10 categories (in constants), 10 shops, 20 products.');
}

main().catch((err) => {
  console.error('Error:', err.message);
  process.exit(1);
});
