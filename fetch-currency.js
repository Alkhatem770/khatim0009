const fs = require("fs");
const fetch = require("node-fetch");

const API_URL = "https://open.er-api.com/v6/latest/USD";

async function fetchCurrencyRates() {
  try {
    const response = await fetch(API_URL);
    const data = await response.json();

    if (!data || !data.rates) {
      throw new Error("No rates data found");
    }

    const output = {
      base: data.base_code,
      time: data.time_last_update_utc,
      rates: data.rates,
    };

    fs.writeFileSync("currency.json", JSON.stringify(output, null, 2));
    console.log("✅ Currency rates saved to currency.json");
  } catch (error) {
    console.error("❌ Failed to fetch currency rates:", error);
    process.exit(1);
  }
}

fetchCurrencyRates();