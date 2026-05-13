/**
 * Update products with real names via API
 * node scripts/update-real-names.js
 */
const BASE = 'https://api.qarreb.online/api';
const TOKEN = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI2OTgwYmViMmM0N2NkNzBmNzFhNTllYTEiLCJpYXQiOjE3NzAxNTU2NTcsImV4cCI6MTc3NzkzMTY1N30.opfEMz7sw5oW6DFUjHoAcPf6Q2L6P9RGhtEYevF4g-s';

const SHOP_PRODUCTS = {
  '69826f05528533c51351f587': ['خس', 'طماطم', 'خيار', 'بصل', 'بطاطا', 'جزر', 'ملفوف', 'فلفل', 'باذنجان', 'سبانخ'],
  '69826f06528533c51351f58b': ['أرز بسمتي', 'سكر أبيض', 'زيت نباتي', 'دقيق', 'معكرونة', 'حليب طازج', 'بيض', 'زبدة', 'عسل طبيعي', 'مربى'],
  '69826f06528533c51351f58f': ['لحم غنم', 'لحم عجل', 'دجاج كامل', 'كباب', 'كفتة', 'نقانق', 'برجر لحم', 'رقائق لحم', 'لحم مفروم', 'سجق'],
  '69826f07528533c51351f593': ['كباب عراقي', 'دولمة', 'برياني', 'مندي لحم', 'فتة', 'سلطة خضراء', 'شوربة عدس', 'سمك مشوي', 'بيتزا', 'برجر'],
  '69826f07528533c51351f597': ['حليب', 'خبز عربي', 'جبنة بيضاء', 'زبادي', 'عصير برتقال', 'ماء معدني', 'بسكويت', 'شوكولاتة', 'مكرونة', 'أرز'],
  '69826f1c528533c51351f5a6': ['كنافة', 'باقلوا', 'قطائف', 'معمول', 'زلابية', 'كيك شوكولاتة', 'دونات', 'آيس كريم', 'شوكولاتة سويسرية', 'بسبوسة'],
  '69826f1c528533c51351f5aa': ['عصير برتقال', 'عصير مانجو', 'ماء معدني', 'شاي', 'قهوة عربية', 'لبن', 'عصير تفاح', 'عصير عنب', 'عصير ليمون', 'كولا'],
  '69826f1d528533c51351f5ae': ['تفاح', 'موز', 'برتقال', 'عنب', 'رمان', 'بطيخ', 'شمام', 'تمر', 'تين', 'خوخ'],
  '69826f1e528533c51351f5b2': ['طماطم', 'خيار', 'بصل', 'بطاطا', 'جزر', 'خس', 'ملفوف', 'فلفل', 'باذنجان', 'سبانخ'],
  '69826f1e528533c51351f5b6': ['حليب كامل', 'لبن رائب', 'جبن أبيض', 'جبنة صفراء', 'قشطة', 'زبدة', 'لبنة', 'روب', 'جبن فيتا', 'زبادي'],
};

async function request(method, path, body) {
  const res = await fetch(BASE + path, {
    method,
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${TOKEN}` },
    body: body ? JSON.stringify(body) : undefined,
  });
  return { status: res.status, data: await res.json().catch(() => ({})) };
}

async function main() {
  const { data } = await request('GET', '/admin/products?limit=150');
  const items = data?.data?.items || [];
  let updated = 0;
  for (const p of items) {
    const names = SHOP_PRODUCTS[p.shopId];
    if (!names) continue;
    const idx = parseInt(String(p.name).replace(/[^\d]/g, ''), 10) - 1;
    if (isNaN(idx) || idx < 0 || idx >= names.length) continue;
    const name = names[idx];
    const { status } = await request('PATCH', `/shops/${p.shopId}/products/${p._id}`, {
      name,
      description: name,
    });
    if (status >= 200 && status < 300) {
      updated++;
      console.log(`✓ ${p.name} -> ${name}`);
    }
    await new Promise((r) => setTimeout(r, 350));
  }
  console.log(`\nتم تحديث ${updated} منتج`);
}

main().catch(console.error);
