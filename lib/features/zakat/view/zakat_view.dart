import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // 1. REKLAM KÜTÜPHANESİ EKLENDİ
import '../../../data/services/economy_service.dart';

class ZakatView extends StatefulWidget {
  const ZakatView({super.key});

  @override
  State<ZakatView> createState() => _ZakatViewState();
}

class _ZakatViewState extends State<ZakatView> {
  final EconomyService _economyService = EconomyService();
  Map<String, double> _liveRates = {};
  bool _isLoadingRates = true;

  // --- REKLAM DEĞİŞKENLERİ ---
  InterstitialAd? _interstitialAd;
  // Test ID'si (Android için Google'ın verdiği standart test id).
  // Yayınlarken buraya kendi AdMob Interstitial ID'ni yazacaksın.
  final String _adUnitId = 'ca-app-pub-3940256099942544/1033173712';
  // ---------------------------

  String _selectedGoldType = 'Gram Altın (24 Ayar)';
  final TextEditingController _goldCountController = TextEditingController();
  final TextEditingController _goldPriceController = TextEditingController();

  String _selectedCurrencyType = 'ABD Doları (USD)';
  final TextEditingController _currencyAmountController =
      TextEditingController();
  final TextEditingController _currencyRateController = TextEditingController();

  final TextEditingController _cashController = TextEditingController();
  final TextEditingController _debtController = TextEditingController();

  double _totalAssets = 0;
  double _zakatAmount = 0;
  bool _isCalculated = false;

  final List<String> _goldTypes = [
    'Gram Altın (24 Ayar)',
    'Çeyrek Altın',
    'Tam Altın',
    'Diğer (Manuel)',
  ];

  final List<String> _currencyTypes = [
    'ABD Doları (USD)',
    'Euro (EUR)',
    'İngiliz Sterlini (GBP)',
    'Diğer (Manuel)',
  ];

  @override
  void initState() {
    super.initState();
    _fetchLiveRates();
    _loadInterstitialAd(); // 2. SAYFA AÇILINCA REKLAMI HAZIRLA
  }

  // --- REKLAM YÜKLEME FONKSİYONU ---
  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          // Reklam kapandığında ne olacağını ayarla
          _interstitialAd!
              .fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _performCalculation(); // Reklamı kapatınca hesaplamayı yap
              _loadInterstitialAd(); // Bir sonraki tıklama için yeni reklam yükle
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              _performCalculation(); // Hata olursa direkt hesapla
              _loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (err) {
          debugPrint('Reklam yüklenemedi: $err');
          _interstitialAd = null;
        },
      ),
    );
  }

  Future<void> _fetchLiveRates() async {
    final rates = await _economyService.getLiveRates();
    if (mounted) {
      setState(() {
        _liveRates = rates;
        _isLoadingRates = false;
        _updateGoldPriceField();
        _updateCurrencyRateField();
      });
    }
  }

  void _updateGoldPriceField() {
    if (_liveRates.containsKey(_selectedGoldType)) {
      _goldPriceController.text = _liveRates[_selectedGoldType]!
          .toStringAsFixed(2);
    } else {
      _goldPriceController.clear();
    }
  }

  void _updateCurrencyRateField() {
    if (_liveRates.containsKey(_selectedCurrencyType)) {
      _currencyRateController.text = _liveRates[_selectedCurrencyType]!
          .toStringAsFixed(2);
    } else {
      _currencyRateController.clear();
    }
  }

  // --- ASIL HESAPLAMA BUTONUNA BASINCA ÇALIŞACAK ---
  void _handleCalculateButton() {
    FocusScope.of(context).unfocus(); // Klavyeyi kapat

    if (_interstitialAd != null) {
      // Reklam hazırsa göster, hesaplamayı reklam kapanınca yapacak (callback'te)
      _interstitialAd!.show();
    } else {
      // Reklam hazır değilse (internet yoksa vs) direkt hesapla
      _performCalculation();
    }
  }

  // --- MATEMATİKSEL HESAPLAMA ---
  void _performCalculation() {
    double goldCount = double.tryParse(_goldCountController.text) ?? 0;
    double goldPrice = double.tryParse(_goldPriceController.text) ?? 0;
    double totalGoldValue = goldCount * goldPrice;

    double currencyAmount =
        double.tryParse(_currencyAmountController.text) ?? 0;
    double currencyRate = double.tryParse(_currencyRateController.text) ?? 0;
    double totalCurrencyValue = currencyAmount * currencyRate;

    double cash = double.tryParse(_cashController.text) ?? 0;
    double debt = double.tryParse(_debtController.text) ?? 0;

    setState(() {
      _totalAssets = (totalGoldValue + totalCurrencyValue + cash) - debt;
      if (_totalAssets > 0) {
        _zakatAmount = _totalAssets / 40;
      } else {
        _totalAssets = 0;
        _zakatAmount = 0;
      }
      _isCalculated = true;
    });
  }

  @override
  void dispose() {
    _interstitialAd?.dispose(); // Reklamı bellekten temizle
    _goldCountController.dispose();
    _goldPriceController.dispose();
    _currencyAmountController.dispose();
    _currencyRateController.dispose();
    _cashController.dispose();
    _debtController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Akıllı Zekat Hesapla"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: _isLoadingRates
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _fetchLiveRates,
            tooltip: "Kurları Güncelle",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isLoadingRates)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(10),
                color: Colors.orange.shade50,
                child: const Row(
                  children: [
                    Icon(Icons.downloading, color: Colors.orange),
                    SizedBox(width: 10),
                    Text(
                      "Güncel kurlar çekiliyor...",
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.teal.shade200),
              ),
              child: const Text(
                "Otomatik çekilen kurları isterseniz el ile düzeltebilirsiniz.",
                style: TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 20),

            _buildSectionHeader("Altın Varlığı", Icons.monetization_on),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: [
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: "Altın Türü",
                        border: OutlineInputBorder(),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedGoldType,
                          isDense: true,
                          isExpanded: true,
                          items: _goldTypes.map((String type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedGoldType = val!;
                              _updateGoldPriceField();
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _goldCountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "Adet / Gram",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _goldPriceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "Birim Fiyatı (TL)",
                              border: OutlineInputBorder(),
                              suffixText: "₺",
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),

            _buildSectionHeader("Döviz Varlığı", Icons.currency_exchange),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: [
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: "Döviz Türü",
                        border: OutlineInputBorder(),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCurrencyType,
                          isDense: true,
                          isExpanded: true,
                          items: _currencyTypes.map((String type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedCurrencyType = val!;
                              _updateCurrencyRateField();
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _currencyAmountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "Miktar",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _currencyRateController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "Güncel Kur (TL)",
                              border: OutlineInputBorder(),
                              suffixText: "₺",
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),

            _buildSectionHeader(
              "Nakit & Borçlar",
              Icons.account_balance_wallet,
            ),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: [
                    TextField(
                      controller: _cashController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Eldeki & Bankadaki Nakit (TL)",
                        icon: Icon(Icons.money, color: Colors.teal),
                        suffixText: "₺",
                      ),
                    ),
                    const Divider(),
                    TextField(
                      controller: _debtController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Toplam Borçlar (Düşülecek)",
                        icon: const Icon(
                          Icons.remove_circle,
                          color: Colors.red,
                        ),
                        suffixText: "₺",
                        labelStyle: TextStyle(color: Colors.red.shade300),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            ElevatedButton(
              onPressed:
                  _handleCalculateButton, // BURASI DEĞİŞTİ: Önce reklam, sonra hesap
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "HESAPLA",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 30),

            if (_isCalculated)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withValues(alpha: 0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                  border: Border.all(color: Colors.teal, width: 2),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Vermeniz Gereken Zekat",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "${_zakatAmount.toStringAsFixed(2)} ₺",
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    const Divider(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Net Varlık:"),
                        Text(
                          "${_totalAssets.toStringAsFixed(2)} ₺",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 5),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
        ],
      ),
    );
  }
}
