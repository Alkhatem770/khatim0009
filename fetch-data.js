const fs = require("fs");
const fetch = require("node-fetch");

// ========== إعداد Google Sheets ==========
const SHEET_URL =
  "https://docs.google.com/spreadsheets/d/e/2PACX-.../pub?output=tsv"; // <-- عدله برابطك

// ========== إعداد CoinGecko API ==========
const COINGECKO_API =
  "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum,solana&vs_currencies=usd";

// ========== دالة لجلب بيانات العملات الرقمية ==========
async function fetchCryptoPrices() {
  const res = await fetch(COINGECKO_API);
  if (!res.ok) throw new Error("فشل في جلب أسعار العملات الرقمية");
  return await res.json();
}

// ========== دالة لجلب سعر الجنيه السوداني من Google Sheets ==========
async function fetchSDGRate() {
  const res = await fetch(SHEET_URL);
  if (!res.ok) throw new Error("فشل في جلب سعر الجنيه السوداني من Google Sheets");

  const tsv = await res.text();
  const lines = tsv.trim().split("\n");
  const headers = lines[0].split("\t");
  const sdgIndex = headers.findIndex((h) => h.toLowerCase().includes("sdg"));

  if (sdgIndex === -1) throw new Error("لم يتم العثور على عمود SDG في Google Sheet");

  const row = lines[1].split("\t");
  const sdgRate = parseFloat(row[sdgIndex]);
  return isNaN(sdgRate) ? null : sdgRate;
}

// ========== حفظ البيانات ==========
async function saveDataToFile(data) {
  fs.writeFileSync("data.json", JSON.stringify(data, null, 2));
}

// ========== تشغيل العملية ==========
(async () => {
  try {
    const [cryptoData, sdgRate] = await Promise.all([
      fetchCryptoPrices(),
      fetchSDGRate(),
    ]);

    const result = {
      timestamp: new Date().toISOString(),
      crypto: cryptoData,
      sdg: sdgRate,
    };

    await saveDataToFile(result);
    console.log("✅ تم حفظ البيانات في data.json");
  } catch (err) {
    console.error("❌ حدث خطأ:", err.message);
    process.exit(1);
  }
})();
