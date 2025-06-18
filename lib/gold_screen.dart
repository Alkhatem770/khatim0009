import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GoldScreen extends StatefulWidget {
  const GoldScreen({super.key});

  @override
  _GoldScreenState createState() => _GoldScreenState();
}

class _GoldScreenState extends State<GoldScreen> {
  final String goldApiUrl =
      'https://raw.githubusercontent.com/Alkhatem770/khatim0009/refs/heads/main/gold.json';

  final String currencyApiUrl =
      'https://script.google.com/macros/s/AKfycbzJshgLxR0SOhZwNGWX9Fal8OLCsB_VvbP7sr5NS-zjAij31qK4uvXqNCOnmbyyNuAOZQ/exec';
  final String sdgApiUrl =
      'https://script.google.com/macros/s/AKfycbyeI-mfyoGqNyX8Gsxkh-dh3A-fq6_2GwMfDP54bkx4LJaxojPUIH0TSrLZNwctF9fN/exec';

  final Map<String, double> karatFactors = {
    '24': 1.0,
    '22': 22 / 24,
    '21': 21 / 24,
    '20': 20 / 24,
    '18': 18 / 24,
    '16': 16 / 24,
    '14': 14 / 24,
    '12': 12 / 24,
    '10': 10 / 24,
    '9': 9 / 24,
    '8': 8 / 24,
  };

  final List<Map<String, String>> currencies = [
    {'code': 'USD', 'name': 'USD - US Dollar', 'flag': '🇺🇸'},
    {'code': 'SDG', 'name': 'SDG - Sudanese Pound', 'flag': '🇸🇩'},
    {'code': 'EGP', 'name': 'EGP - Egyptian Pound', 'flag': '🇪🇬'},
    {'code': 'SAR', 'name': 'SAR - Saudi Riyal', 'flag': '🇸🇦'},
  ];

  String selectedCurrency = 'USD';
  Map<String, double> prices = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadPrices();
  }

  Future<void> loadPrices() async {
    final prefs = await SharedPreferences.getInstance();
    final lastUpdated = prefs.getInt('last_updated_gold') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    double? goldPriceUSD;

    if (now - lastUpdated >= 8 * 60 * 60 * 1000) {
      goldPriceUSD = await fetchGoldPrice();
      if (goldPriceUSD != null) {
        await prefs.setDouble('gold_price_usd', goldPriceUSD);
        await prefs.setInt('last_updated_gold', now);
      }
    } else {
      goldPriceUSD = prefs.getDouble('gold_price_usd');
      if (goldPriceUSD == null) {
        goldPriceUSD = await fetchGoldPrice();
        if (goldPriceUSD != null) {
          await prefs.setDouble('gold_price_usd', goldPriceUSD);
          await prefs.setInt('last_updated_gold', now);
        }
      }
    }

    if (goldPriceUSD != null) {
      await calculatePrices(goldPriceUSD);
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<double?> fetchGoldPrice() async {
    try {
      final goldRes = await http.get(Uri.parse(goldApiUrl));
      if (goldRes.statusCode == 200) {
        final data = json.decode(goldRes.body);
        final price = (data['price'] as num?)?.toDouble();
        print('Fetched gold price from GitHub: $price');
        return price;
      }
    } catch (e) {
      print('Error fetching gold price: $e');
    }
    return null;
  }

  Future<void> calculatePrices(double goldPriceUSD) async {
    double exchangeRate = 1.0;

    if (selectedCurrency == 'SDG') {
      try {
        final res = await http.get(Uri.parse(sdgApiUrl));
        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          exchangeRate = (data['rate'] as num?)?.toDouble() ?? 1.0;
        }
      } catch (e) {
        print('Error fetching SDG exchange rate: $e');
      }
    } else if (selectedCurrency != 'USD') {
      try {
        final res = await http.get(Uri.parse(currencyApiUrl));
        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          exchangeRate = (data[selectedCurrency] as num?)?.toDouble() ?? 1.0;
        }
      } catch (e) {
        print('Error fetching currency rate: $e');
      }
    }

    final gramPrice = goldPriceUSD / 31.1035;
    final newPrices = <String, double>{};

    karatFactors.forEach((karat, factor) {
      newPrices[karat] =
          double.parse((gramPrice * factor * exchangeRate).toStringAsFixed(2));
    });
    setState(() {
      prices = newPrices;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('أسعار الذهب'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: DropdownButton<String>(
              value: selectedCurrency,
              underline: const SizedBox(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    selectedCurrency = val;
                    isLoading = true;
                  });
                  loadPrices();
                }
              },
              items: currencies.map((currency) {
                return DropdownMenuItem<String>(
                  value: currency['code'],
                  child: Row(
                    children: [
                      Text(currency['flag'] ?? ''),
                      const SizedBox(width: 8),
                      Text(currency['code'] ?? ''),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          isLoading
              ? const Expanded(
                  child: Center(child: CircularProgressIndicator()))
              : Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(8),
                    children: prices.entries.map((entry) {
                      final karat = entry.key;
                      final price = entry.value;

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: Image.asset(
                            'assets/images/gold/gold_bar.png',
                            width: 60,
                            height: 60,
                          ),
                          title: Text('عيار $karat'),
                          subtitle: Text('السعر: $price $selectedCurrency'),
                        ),
                      );
                    }).toList(),
                  ),
                ),
        ],
      ),
    );
  }
}
