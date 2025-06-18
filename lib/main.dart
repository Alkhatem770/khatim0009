import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';
import 'package:csv/csv.dart'; // Ensure this import is present and correct
import 'package:smart_currency/splash_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:smart_currency/gold_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); // Initialize Firebase
  MobileAds.instance.initialize(); // Initialize AdMob

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@drawable/app_icon');

  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  runApp(const CurrencyApp());
}

class CurrencyApp extends StatefulWidget {
  const CurrencyApp({super.key});
  @override
  State<CurrencyApp> createState() => _CurrencyAppState();
}

class _CurrencyAppState extends State<CurrencyApp> {
  ThemeMode themeMode = ThemeMode.dark;
  InterstitialAd? _interstitialAd;

  @override
  void initState() {
    super.initState();
    _loadInterstitialAd(); // Load the ad when the app starts
  }

  void toggleTheme() {
    setState(() {
      themeMode =
          themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId:
          'ca-app-pub-6359760519702309/8010559750', // Your real Ad Unit ID
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          print('Interstitial Ad Loaded');

          // إعداد حدث عند إغلاق الإعلان
          _interstitialAd!.setImmersiveMode(true);
          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdDismissedFullScreenContent: (InterstitialAd ad) {
              print('Interstitial Ad Dismissed');
              ad.dispose(); // تنظيف الذاكرة بعد إغلاق الإعلان
              _loadInterstitialAd(); // تحميل إعلان جديد
            },
            onAdFailedToShowFullScreenContent:
                (InterstitialAd ad, AdError error) {
              print('Failed to show interstitial ad: $error');
              ad.dispose(); // تنظيف الذاكرة
              _loadInterstitialAd(); // تحميل إعلان جديد
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('Failed to load interstitial ad: $error');
          _interstitialAd = null; // إعادة تعيين الإعلان
        },
      ),
    );
  }

  void _showInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.show(); // عرض الإعلان
      _interstitialAd = null; // إعادة تعيين الإعلان بعد عرضه
    } else {
      print('Interstitial Ad is not ready yet');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Currency Portfolio',
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: Colors.white,
      ),
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      themeMode: themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(
              showAd: _showInterstitialAd,
            ),
        '/home': (context) => MainScreen(
              toggleTheme: toggleTheme,
              themeMode: themeMode,
            ),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final ThemeMode themeMode;

  const MainScreen(
      {super.key, required this.toggleTheme, required this.themeMode});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class GoldPage extends StatelessWidget {
  const GoldPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const Center(
        child: Text('Gold Page Content'),
      ),
    );
  }
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;

  final List<Widget> pages = [
    const HomePage(),
    const CalculatorPage(),
    const CryptoPage(),
    GoldScreen(),
    const MorePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.themeMode == ThemeMode.dark;

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            if (index < pages.length) {
              currentIndex = index;
            }
          });
        },
        selectedItemColor: isDarkMode ? Colors.white : Colors.black,
        unselectedItemColor: isDarkMode ? Colors.grey : Colors.black54,
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate),
            label: 'الحاسبة',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.currency_bitcoin),
            label: 'العملات الرقمية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money_rounded),
            label: 'الذهب',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: 'الأخبار',
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic> originalRates = {};
  Map<String, dynamic> rates = {};
  Map<String, dynamic> previousRates = {};
  bool isLoading = true;
  String baseCurrency = 'USD';
  double baseAmount = 1.0;
  final amountController = TextEditingController(text: '1.0');
  final searchController = TextEditingController();
  final List<String> favoriteCurrencies = [];
  String searchQuery = '';

  final List<String> currenciesToShow = [
    'USD',
    'EUR',
    'SAR',
    'GBP',
    'JPY',
    'CNY',
    'AUD',
    'CAD',
    'CHF',
    'NZD',
    'SEK',
    'NOK',
    'DKK',
    'SDG',
    'INR',
    'BRL',
    'ZAR',
    'MXN',
    'EGP',
    'KRW',
    'HKD',
    'SGD',
    'THB',
    'MYR',
    'IDR',
    'PHP',
    'PLN',
    'TRY',
    'RUB',
    'CZK',
    'HUF',
    'AED',
    'QAR',
    'KWD',
    'OMR',
    'BHD',
    'VND',
    'PKR',
    'NGN'
  ];

  InterstitialAd? _interstitialAd;

  @override
  void initState() {
    super.initState();
    _loadDataAndFetchIfNeeded();
    _loadInterstitialAd();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showInterstitialAd();
    });
  }

  @override
  void dispose() {
    amountController.dispose();
    searchController.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }

  Future<void> _loadDataAndFetchIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final lastUpdateMillis = prefs.getInt('lastUpdateMillis') ?? 0;
    final nowMillis = DateTime.now().millisecondsSinceEpoch;
    final eightHoursMillis = 8 * 60 * 60 * 1000;

    if (nowMillis - lastUpdateMillis < eightHoursMillis) {
      final storedRates = prefs.getString('originalRates');
      final storedPreviousRates = prefs.getString('previousRates');

      if (storedRates != null && storedPreviousRates != null) {
        setState(() {
          originalRates = Map<String, dynamic>.from(json.decode(storedRates));
          previousRates =
              Map<String, dynamic>.from(json.decode(storedPreviousRates));
          final baseRate = originalRates[baseCurrency] ?? 1.0;
          rates = originalRates
              .map((key, value) => MapEntry(key, value / baseRate));
          isLoading = false;
        });
        return;
      }
    }

    await fetchRates();
  }

  Future<double?> fetchSDGRateFromGoogleSheet() async {
    try {
      final response = await http.get(Uri.parse(
        'https://docs.google.com/spreadsheets/d/17gLQV0dE_rDv_WU83-FZuZCttlDUkj9nkz6LaXhduJ0/export?format=csv',
      ));

      if (response.statusCode == 200) {
        final csvTable = const CsvToListConverter().convert(response.body);

        for (int i = 1; i < csvTable.length; i++) {
          final row = csvTable[i];
          if (row[0].toString().trim().toUpperCase() == 'SDG') {
            return double.tryParse(row[1].toString().replaceAll(',', ''));
          }
        }
      }
    } catch (e) {
      print('خطأ أثناء جلب سعر SDG من Google Sheet: $e');
    }
    return null;
  }

  String getYesterdayDate() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
  }

  Future<void> fetchRates() async {
    setState(() {
      isLoading = true;
    });

    try {
      final todayResponse =
          await http.get(Uri.parse('https://open.er-api.com/v6/latest/USD'));
      final yesterdayResponse = await http.get(Uri.parse(
          'https://open.er-api.com/v6/latest/USD?date=${getYesterdayDate()}'));
      if (todayResponse.statusCode == 200 &&
          yesterdayResponse.statusCode == 200) {
        final todayData = json.decode(todayResponse.body);
        final yesterdayData = json.decode(yesterdayResponse.body);

        double? sdgRate = await fetchSDGRateFromGoogleSheet();

        if (sdgRate != null) {
          todayData['rates']['SDG'] = sdgRate;
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('originalRates', json.encode(todayData['rates']));
        await prefs.setString(
            'previousRates', json.encode(yesterdayData['rates']));
        await prefs.setInt(
            'lastUpdateMillis', DateTime.now().millisecondsSinceEpoch);

        setState(() {
          originalRates = Map<String, dynamic>.from(todayData['rates']);
          previousRates = Map<String, dynamic>.from(yesterdayData['rates']);
          final baseRate = originalRates[baseCurrency] ?? 1.0;
          rates = originalRates
              .map((key, value) => MapEntry(key, value / baseRate));
          isLoading = false;
        });
      } else {
        throw Exception('فشل في تحميل الأسعار من API الرئيسي');
      }
    } catch (e) {
      print('خطأ في تحميل الأسعار: $e');
      setState(() => isLoading = false);
    }
  }

  void updateBaseCurrency(String newCurrency) {
    setState(() {
      baseCurrency = newCurrency;
      if (originalRates.isNotEmpty) {
        final baseRate = originalRates[baseCurrency] ?? 1.0;
        rates =
            originalRates.map((key, value) => MapEntry(key, value / baseRate));
      }
    });
  }

  void updateAmount(String value) {
    setState(() {
      baseAmount = double.tryParse(value) ?? 1.0;
    });
  }

  void updateSearchQuery(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
    });
  }

  void toggleFavorite(String currency) {
    setState(() {
      if (favoriteCurrencies.contains(currency)) {
        favoriteCurrencies.remove(currency);
      } else {
        favoriteCurrencies.add(currency);
      }
    });
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-6359760519702309/8010559750',
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialAd!.setImmersiveMode(true);
          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          print('فشل تحميل إعلان بيني: $error');
        },
      ),
    );
  }

  void _showInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.show();
      _interstitialAd = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final filteredCurrencies = currenciesToShow
        .where((currency) =>
            rates.containsKey(currency) &&
            currency.toLowerCase().contains(searchQuery))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('الصفحة الرئيسية'),
        actions: [
          Row(
            children: [
              Text(
                isDarkMode ? 'الوضع الليلي' : 'الوضع النهاري',
                style: const TextStyle(fontSize: 16),
              ),
              IconButton(
                icon: const Icon(Icons.brightness_6),
                onPressed: () => (context
                    .findAncestorStateOfType<_CurrencyAppState>()
                    ?.toggleTheme()),
              ),
            ],
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('العملة الأساسية',
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          style: const TextStyle(
                              fontSize: 28, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white10,
                          ),
                          onChanged: updateAmount,
                        ),
                      ),
                      const SizedBox(width: 10),
                      DropdownButton<String>(
                        value: baseCurrency,
                        items: currenciesToShow
                            .map<DropdownMenuItem<String>>((String currency) {
                          return DropdownMenuItem<String>(
                            value: currency,
                            child: Text(currency),
                          );
                        }).toList(),
                        onChanged: (String? value) {
                          if (value != null) updateBaseCurrency(value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      labelText: 'البحث عن عملة',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: updateSearchQuery,
                  ),
                  const SizedBox(height: 20),
                  const Text('الأسعار المحولة',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredCurrencies.length,
                      itemBuilder: (context, index) {
                        final currency = filteredCurrencies[index];
                        final rate = rates[currency] ?? 0.0;
                        final previousRate = previousRates[currency] ?? 1.0;
                        final difference = previousRate != 0
                            ? ((rate - previousRate) / previousRate) * 100
                            : 0.0;
                        final isUp = difference >= 0;

                        return Card(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(
                                currency == 'EUR'
                                    ? 'https://i.imgur.com/dXWmVb1.png'
                                    : 'https://flagcdn.com/48x36/${currency.substring(0, 2).toLowerCase()}.png',
                              ),
                            ),
                            title: Text(currency,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    '1 $baseCurrency = ${(rate * baseAmount).toStringAsFixed(2)} $currency',
                                    style:
                                        const TextStyle(color: Colors.black)),
                                const SizedBox(height: 5),
                                Text(
                                  previousRate != 0
                                      ? '${difference.toStringAsFixed(2)}%'
                                      : 'N/A',
                                  style: TextStyle(
                                    color: previousRate != 0
                                        ? (isUp ? Colors.green : Colors.red)
                                        : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                favoriteCurrencies.contains(currency)
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: favoriteCurrencies.contains(currency)
                                    ? Colors.red
                                    : Colors.black,
                              ),
                              onPressed: () => toggleFavorite(currency),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class CryptoPage extends StatefulWidget {
  const CryptoPage({super.key});

  @override
  State<CryptoPage> createState() => _CryptoPageState();
}

class _CryptoPageState extends State<CryptoPage> {
  List<dynamic> cryptoRates = [];
  bool isLoading = true;
  final searchController = TextEditingController();
  final List<String> favoriteCryptos = [];
  String searchQuery = '';
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    fetchCryptoRates();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _timer = Timer.periodic(const Duration(seconds: 20), (timer) {
      fetchCryptoRates();
    });
  }

  Future<void> fetchCryptoRates() async {
    final response = await http.get(Uri.parse(
        'https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=50&page=1&sparkline=false'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        cryptoRates = data;
        isLoading = false;
      });
    }
  }

  void updateSearchQuery(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
    });
  }

  void toggleFavorite(String cryptoId) {
    setState(() {
      if (favoriteCryptos.contains(cryptoId)) {
        favoriteCryptos.remove(cryptoId);
      } else {
        favoriteCryptos.add(cryptoId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final filteredCryptos = cryptoRates
        .where((crypto) =>
            crypto['name'].toLowerCase().contains(searchQuery) ||
            crypto['symbol'].toLowerCase().contains(searchQuery))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('العملات الرقمية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchCryptoRates,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      labelText: 'البحث عن عملة رقمية',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: updateSearchQuery,
                  ),
                  const SizedBox(height: 20),
                  const Text('العملات الرقمية',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredCryptos.length,
                      itemBuilder: (context, index) {
                        final crypto = filteredCryptos[index];
                        final cryptoId = crypto['id'];
                        final cryptoName = crypto['name'];
                        final cryptoSymbol = crypto['symbol'].toUpperCase();
                        final cryptoPrice = crypto['current_price'];
                        final cryptoImage = crypto['image'];
                        final priceChangePercentage =
                            crypto['price_change_percentage_24h'] ?? 0.0;
                        return Card(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(cryptoImage),
                            ),
                            title: Text(
                              '$cryptoName ($cryptoSymbol)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.black : Colors.black,
                              ),
                            ),
                            subtitle: Row(
                              children: [
                                Text(
                                  '\$${cryptoPrice.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.black
                                        : Colors.black,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '${priceChangePercentage.toStringAsFixed(2)}%',
                                  style: TextStyle(
                                    color: priceChangePercentage >= 0
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                favoriteCryptos.contains(cryptoId)
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: favoriteCryptos.contains(cryptoId)
                                    ? Colors.red
                                    : const Color.fromARGB(255, 3, 0, 0),
                              ),
                              onPressed: () => toggleFavorite(cryptoId),
                            ),
                          ),
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
    );
  }
}

class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  final List<Map<String, String>> links = [
    {
      'title': 'صفحتنا على فيسبوك',
      'url': 'https://www.facebook.com/share/1Q8WigQNH1/',
    },
  ];

  final List<Map<String, String>> faqs = [
    {
      'question': 'ما هو هدف تطبيق العملة الذكية؟',
      'answer': 'التطبيق يساعد المستخدمين على تحويل العملات و تتبعها بكفاءة.',
    },
    {
      'question': 'متى يتم تحديث العملات عادة؟',
      'answer': 'يتم تحديث العملات عادة كل ساعة.',
    },
    {
      'question': 'هل يمكنني تتبع أسعار العملات الرقمية؟',
      'answer': 'نعم، التطبيق يوفر تحديث لأسعار العملات الرقمية كل 30 ثانية.',
    },
    {
      'question': 'هل التطبيق مجاني تماما للإستخدام؟',
      'answer': 'نعم، التطبيق مجاني تماما.',
    },
  ];

  Timer? backgroundTimer;
  List<Map<String, String>> newsList = [];

  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;
  bool _canShowAd = false;

  @override
  void initState() {
    super.initState();
    fetchNewsFromFirestore();
    startBackgroundRefresh();
    _loadInterstitialAd();

    // ندي فرصة بسيطة للإعلان إنه يجهز (2 ثواني)
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _canShowAd = true;
      });
    });
  }

  @override
  void dispose() {
    backgroundTimer?.cancel();
    _interstitialAd?.dispose();
    super.dispose();
  }

  void startBackgroundRefresh() {
    backgroundTimer = Timer.periodic(const Duration(hours: 7), (_) async {
      await fetchNewsFromFirestore();
    });
  }

  Future<void> fetchNewsFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('news')
          .orderBy('title')
          .limit(10)
          .get();

      setState(() {
        newsList = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'title': data['title']?.toString() ?? '',
            'image': data['image']?.toString() ?? '',
            'url': data['url']?.toString() ?? '',
          };
        }).toList();
      });
    } catch (e) {
      print('❌ Error fetching news: $e');
    }
  }

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      print('❌ Could not launch $url');
    }
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-6359760519702309/8010559750',
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          print('✅ إعلان جاهز');
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('❌ فشل تحميل الإعلان: $error');
          _isInterstitialAdReady = false;
        },
      ),
    );
  }

  void _showAdThenOpenLink(String url) {
    if (_isInterstitialAdReady && _interstitialAd != null && _canShowAd) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          print('✅ الإعلان اتقفل، جاري فتح الرابط');
          _launchURL(url);
          ad.dispose();
          _loadInterstitialAd(); // تحميل إعلان جديد
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          print('❌ فشل عرض الإعلان: $error');
          _launchURL(url);
          ad.dispose();
          _loadInterstitialAd();
        },
      );
      _interstitialAd!.show();
      _isInterstitialAdReady = false;
    } else {
      print('⚠️ الإعلان غير جاهز، فتح الرابط مباشرة');
      _launchURL(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('المزيد'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              ...links.map((link) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.link),
                      label: Text(link['title']!),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isDarkMode ? Colors.black87 : Colors.blue[100],
                        foregroundColor:
                            isDarkMode ? Colors.white : Colors.black,
                      ),
                      onPressed: () => _launchURL(link['url']!),
                    ),
                  )),
              const SizedBox(height: 20),
              ...newsList.map((news) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: GestureDetector(
                      onTap: () {
                        _showAdThenOpenLink(news['url']!);
                      },
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                        color: isDarkMode ? Colors.grey[900] : Colors.white,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (news['image'] != null &&
                                news['image']!.isNotEmpty)
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(15)),
                                child: Image.network(
                                  news['image']!,
                                  height: 180,
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return SizedBox(
                                      height: 180,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    height: 180,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.broken_image,
                                        size: 60, color: Colors.grey),
                                  ),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                news['title'] ?? '',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )),
              const SizedBox(height: 30),
              const Text(
                'الأسئلة الشائعة',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ...faqs.map((faq) => ExpansionTile(
                    title: Text(
                      faq['question']!,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: Text(
                          faq['answer']!,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  String topCurrency = 'USD';
  String bottomCurrency = 'SDG';
  String baseCurrency = 'USD';
  String input = '';
  String result = '';
  Map<String, dynamic> rates = {};
  bool isLoading = true;

  static const updateIntervalHours = 8;

  @override
  void initState() {
    super.initState();
    loadRatesWithCache();
  }

  Future<double?> fetchSDGRateFromGoogleSheet() async {
    try {
      final response = await http.get(Uri.parse(
          'https://docs.google.com/spreadsheets/d/17gLQV0dE_rDv_WU83-FZuZCttlDUkj9nkz6LaXhduJ0/export?format=csv'));

      if (response.statusCode == 200) {
        final csvTable = const CsvToListConverter().convert(response.body);

        for (int i = 1; i < csvTable.length; i++) {
          final row = csvTable[i];
          if (row[0].toString().trim().toUpperCase() == 'SDG') {
            return double.tryParse(row[1].toString().replaceAll(',', ''));
          }
        }
      }
    } catch (e) {
      print('Error fetching SDG rate: $e');
    }
    return null;
  }

  Future<void> loadRatesWithCache() async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    // قراءة آخر تحديث من التخزين المحلي
    final lastUpdatedMillis = prefs.getInt('rates_last_updated') ?? 0;
    final lastUpdated = DateTime.fromMillisecondsSinceEpoch(lastUpdatedMillis);

    // حساب الفرق بالساعات
    final diffHours = now.difference(lastUpdated).inHours;

    if (diffHours < updateIntervalHours && prefs.containsKey('rates_data')) {
      // لو التحديث ما وصل لـ 8 ساعات استخدم التخزين المحلي
      final cachedData = prefs.getString('rates_data');
      if (cachedData != null) {
        final Map<String, dynamic> cachedRates = json.decode(cachedData);
        setState(() {
          rates = cachedRates;
          result = calculateResult();
          isLoading = false;
        });
        return;
      }
    }

    // وإلا نحدث من API
    await fetchAndCacheRates(prefs);
  }

  Future<void> fetchAndCacheRates(SharedPreferences prefs) async {
    try {
      final response = await http
          .get(Uri.parse('https://open.er-api.com/v6/latest/$baseCurrency'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        double? sdgRate = await fetchSDGRateFromGoogleSheet();

        Map<String, dynamic> fetchedRates =
            Map<String, dynamic>.from(data['rates']);

        if (sdgRate != null) {
          fetchedRates['SDG'] = sdgRate;
        }

        // خزّن البيانات والتاريخ في SharedPreferences
        await prefs.setString('rates_data', json.encode(fetchedRates));
        await prefs.setInt(
            'rates_last_updated', DateTime.now().millisecondsSinceEpoch);

        setState(() {
          rates = fetchedRates;
          result = calculateResult();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load rates from API');
      }
    } catch (e) {
      print('Error fetching rates: $e');
      // حتى لو فشل التحديث، حاول تستخدم البيانات القديمة إن وجدت
      final cachedData = prefs.getString('rates_data');
      if (cachedData != null) {
        final cachedRates = json.decode(cachedData);
        setState(() {
          rates = cachedRates;
          result = calculateResult();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void swapCurrencies() {
    setState(() {
      final temp = topCurrency;
      topCurrency = bottomCurrency;
      bottomCurrency = temp;

      input = '';
      result = '';
    });
  }

  void onKeyPress(String value) {
    setState(() {
      if (value == 'C') {
        input = '';
        result = '';
      } else if (value == '<') {
        if (input.isNotEmpty) {
          input = input.substring(0, input.length - 1);
        }
      } else {
        input += value;
      }
      result = calculateResult();
    });
  }

  String calculateResult() {
    if (rates.containsKey(topCurrency) && rates.containsKey(bottomCurrency)) {
      final topRate = (rates[topCurrency] ?? 1.0) as num;
      final bottomRate = (rates[bottomCurrency] ?? 1.0) as num;
      final inputValue = double.tryParse(input) ?? 0.0;

      return ((inputValue / topRate) * bottomRate).toStringAsFixed(2);
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('حاسبة العملات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'تبديل العملات',
            onPressed: swapCurrencies,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  color: isDarkMode ? Colors.black87 : Colors.grey[200],
                  padding:
                      const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                  child: Column(
                    children: [
                      DropdownButton<String>(
                        value: topCurrency,
                        dropdownColor: isDarkMode ? Colors.black : Colors.white,
                        items: rates.keys.map((currency) {
                          return DropdownMenuItem(
                            value: currency,
                            child: Text(
                              currency,
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              topCurrency = value;
                              result = calculateResult();
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      Text(
                        input.isEmpty ? '0' : input,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 20),
                      DropdownButton<String>(
                        value: bottomCurrency,
                        dropdownColor: isDarkMode ? Colors.black : Colors.white,
                        items: rates.keys.map((currency) {
                          return DropdownMenuItem(
                            value: currency,
                            child: Text(
                              currency,
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              bottomCurrency = value;
                              result = calculateResult();
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      Text(
                        result.isEmpty ? '0' : result,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    color: isDarkMode ? Colors.black54 : Colors.white,
                    child: GridView.builder(
                      padding: const EdgeInsets.all(20),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.7,
                      ),
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        final keys = [
                          '1',
                          '2',
                          '3',
                          '4',
                          '5',
                          '6',
                          '7',
                          '8',
                          '9',
                          'C',
                          '0',
                          '<'
                        ];
                        final key = keys[index];
                        return ElevatedButton(
                          onPressed: () => onKeyPress(key),
                          child: Text(
                            key,
                            style: const TextStyle(fontSize: 20),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
