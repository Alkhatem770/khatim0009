const fs = require('fs');
const path = require('path');

// ضع هنا دوال جلب البيانات الخاصة بك
async function fetchCryptoData() {
  // مثال: إرجاع بيانات وهمية
  return [{ name: "Bitcoin", price: 70000 }];
}
async function fetchSDGfromGoogleSheet() {
  // مثال: إرجاع بيانات وهمية
  return [{ goal: "No Poverty", status: "On Track" }];
}

async function main() {
  try {
    const [crypto, sdg] = await Promise.all([
      fetchCryptoData(),
      fetchSDGfromGoogleSheet()
    ]);

    const data = {
      timestamp: new Date().toISOString(),
      crypto,
      sdg
    };

    const dir = path.join(__dirname, 'data');
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir);
    }

    fs.writeFileSync(path.join(dir, 'crypto_sdg.json'), JSON.stringify(data, null, 2));
    console.log('✅ تم تحديث البيانات بنجاح');
  } catch (error) {
    console.error('❌ فشل في جلب أو حفظ البيانات:', error);
    process.exit(1);
  }
}

main();