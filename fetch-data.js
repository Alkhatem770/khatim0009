// fetch-data.js
const fs = require('fs');
const fetch = require('node-fetch');
const { parse } = require('csv-parse/sync');

async function fetchCryptoData() {
  const url = 'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum,solana&vs_currencies=usd';
  const res = await fetch(url);
  return await res.json();
}

async function fetchSDGfromGoogleSheet() {
  const sheetURL = 'https://docs.google.com/spreadsheets/d/17gLQV0dE_rDv_WU83-FZuZCttlDUkj9nkz6LaXhduJ0/export?format=csv';
  const res = await fetch(sheetURL);
  const csv = await res.text();

  const records = parse(csv, { columns: true, skip_empty_lines: true });
  const sdgRecord = records.find(r => r.currency === 'SDG');
  if (!sdgRecord) throw new Error('SDG not found in Google Sheet');
  
  return { rate: parseFloat(sdgRecord.rate) };
}

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

  fs.writeFileSync('./data/crypto_sdg.json', JSON.stringify(data, null, 2));
  console.log('✅ Data updated successfully');
}

main().catch(err => {
  console.error('❌ Error fetching data:', err);
  process.exit(1);
});