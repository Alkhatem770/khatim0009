const fs = require("fs");
const fetch = require("node-fetch");

const API_URL = "https://www.goldapi.io/api/XAU/USD";
const API_KEY = "goldapi-40cz8smbyf28en-io";

async function fetchGoldPrice() {
  try {
    const response = await fetch(API_URL, {
      headers: {
        "x-access-token": API_KEY,
        "Content-Type": "application/json",
      },
    });

    const data = await response.json();

    if (!data || !data.price) {
      throw new Error("No gold price data found");
    }

    const output = {
      metal: data.metal,
      currency: data.currency,
      price: data.price,
      timestamp: data.timestamp,
    };

    fs.writeFileSync("gold.json", JSON.stringify(output, null, 2));
    console.log("✅ Gold price saved to gold.json");
  } catch (error) {
    console.error("❌ Failed to fetch gold price:", error);
    process.exit(1);
  }
}

fetchGoldPrice();