const fs = require('fs');
const path = require('path');
const fetch = require('node-fetch');
const { parse } = require('csv-parse/sync');

// ... باقي الكود كما هو

async function main() {
  const [crypto, sdg] = await Promise.all([
    fetchCryptoData(),
    fetchSDGfromGoogleSheet()
  ]);

  const data = {
    timestamp: new Date().toISOString(),
    crypto,
    sdg
  };

  // ✨ تأكد أن المجلد موجود
  const dir = path.join(__dirname, 'data');
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir);
  }

  fs.writeFileSync(path.join(dir, 'crypto_sdg.json'), JSON.stringify(data, null, 2));
  console.log('✅ Data updated successfully');
}