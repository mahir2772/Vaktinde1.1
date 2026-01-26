import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
// --- DİL İMPORTU ---
import 'package:ezan_saati/l10n/app_localizations.dart';
// -------------------
import '../../../data/services/economy_service.dart';
// --- REKLAM İMPORTU ---
import '../../common/widgets/ad_banner_widget.dart';

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
  final String _adUnitId = 'ca-app-pub-4975388193054410/2151461471';

  String _selectedGoldType = 'Gram Altın (24 Ayar)';
  String _selectedCurrencyType = 'ABD Doları (USD)';

  final TextEditingController _goldCountController = TextEditingController();
  final TextEditingController _goldPriceController = TextEditingController();
  final TextEditingController _currencyAmountController =
      TextEditingController();
  final TextEditingController _currencyRateController = TextEditingController();
  final TextEditingController _cashController = TextEditingController();
  final TextEditingController _debtController = TextEditingController();

  double _totalAssets = 0;
  double _zakatAmount = 0;
  double _nisabThreshold = 0;
  bool _isEligible = false;
  bool _isCalculated = false;

  @override
  void initState() {
    super.initState();
    _fetchLiveRates();
    _loadInterstitialAd();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
                onAdDismissedFullScreenContent: (ad) {
                  ad.dispose();
                  _performCalculation();
                  _loadInterstitialAd();
                },
                onAdFailedToShowFullScreenContent: (ad, err) {
                  ad.dispose();
                  _performCalculation();
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

  void _handleCalculateButton() {
    FocusScope.of(context).unfocus();
    if (_interstitialAd != null) {
      _interstitialAd!.show();
    } else {
      _performCalculation();
    }
  }

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

    double currentGoldUnitPrice = goldPrice > 0
        ? goldPrice
        : (_liveRates['Gram Altın (24 Ayar)'] ?? 0);

    double calculatedNisab = currentGoldUnitPrice * 80.18;

    setState(() {
      _totalAssets = (totalGoldValue + totalCurrencyValue + cash) - debt;
      _nisabThreshold = calculatedNisab;

      if (_totalAssets < 0) _totalAssets = 0;

      if (_totalAssets >= _nisabThreshold && _totalAssets > 0) {
        _zakatAmount = _totalAssets / 40;
        _isEligible = true;
      } else {
        _zakatAmount = 0;
        _isEligible = false;
      }
      _isCalculated = true;
    });
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();
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
    final loc = AppLocalizations.of(context)!;

    final Map<String, String> goldTypeMap = {
      'Gram Altın (24 Ayar)': loc.goldGram,
      'Çeyrek Altın': loc.goldQuarter,
      'Tam Altın': loc.goldFull,
      'Diğer (Manuel)': loc.typeOther,
    };

    final Map<String, String> currencyTypeMap = {
      'ABD Doları (USD)': loc.usd,
      'Euro (EUR)': loc.eur,
      'İngiliz Sterlini (GBP)': loc.gbp,
      'Diğer (Manuel)': loc.typeOther,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.zakatCalculatorTitle),
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
      // --- REKLAM ALANI EKLENDİ ---
      bottomNavigationBar: const SafeArea(child: AdBannerWidget()),
      // ---------------------------
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
                child: Row(
                  children: [
                    const Icon(Icons.downloading, color: Colors.orange),
                    const SizedBox(width: 10),
                    Text(
                      loc.liveRatesLoading,
                      style: const TextStyle(fontSize: 12),
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
              child: Text(
                loc.liveRatesInfo,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionHeader(loc.sectionGold, Icons.monetization_on),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: [
                    InputDecorator(
                      decoration: InputDecoration(
                        labelText: loc.goldType,
                        border: const OutlineInputBorder(),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedGoldType,
                          isDense: true,
                          isExpanded: true,
                          items: goldTypeMap.entries.map((entry) {
                            return DropdownMenuItem<String>(
                              value: entry.key,
                              child: Text(entry.value),
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
                            decoration: InputDecoration(
                              labelText: loc.goldAmount,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _goldPriceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: loc.goldUnitPrice,
                              border: const OutlineInputBorder(),
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
            _buildSectionHeader(loc.sectionCurrency, Icons.currency_exchange),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: [
                    InputDecorator(
                      decoration: InputDecoration(
                        labelText: loc.currencyType,
                        border: const OutlineInputBorder(),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCurrencyType,
                          isDense: true,
                          isExpanded: true,
                          items: currencyTypeMap.entries.map((entry) {
                            return DropdownMenuItem<String>(
                              value: entry.key,
                              child: Text(entry.value),
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
                            decoration: InputDecoration(
                              labelText: loc.currencyAmount,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _currencyRateController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: loc.currencyRate,
                              border: const OutlineInputBorder(),
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
              loc.sectionCashDebt,
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
                      decoration: InputDecoration(
                        labelText: loc.cashAmount,
                        icon: const Icon(Icons.money, color: Colors.teal),
                        suffixText: "₺",
                      ),
                    ),
                    const Divider(),
                    TextField(
                      controller: _debtController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: loc.debtAmount,
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
              onPressed: _handleCalculateButton,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                loc.calculateButton,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
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
                      color: _isEligible
                          ? Colors.teal.withValues(alpha: 0.2)
                          : Colors.orange.withValues(alpha: 0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                  border: Border.all(
                    color: _isEligible ? Colors.teal : Colors.orange,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isEligible ? Icons.check_circle : Icons.info,
                          color: _isEligible ? Colors.teal : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isEligible
                              ? loc.zakatEligible
                              : loc.zakatNotEligible,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _isEligible ? Colors.teal : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Text(
                      loc.zakatResultTitle,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "${_zakatAmount.toStringAsFixed(2)} ₺",
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: _isEligible ? Colors.teal : Colors.grey,
                      ),
                    ),
                    const Divider(height: 30),
                    _buildResultRow(
                      loc.netAssets,
                      "${_totalAssets.toStringAsFixed(2)} ₺",
                    ),
                    const SizedBox(height: 8),
                    _buildResultRow(
                      loc.nisabLimit,
                      "${_nisabThreshold.toStringAsFixed(2)} ₺",
                      isSubtle: true,
                    ),
                    if (!_isEligible)
                      Padding(
                        padding: const EdgeInsets.only(top: 15),
                        child: Text(
                          loc.belowNisabMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.orange,
                          ),
                        ),
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

  Widget _buildResultRow(String label, String value, {bool isSubtle = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isSubtle ? Colors.grey : Colors.black87,
            fontSize: isSubtle ? 13 : 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSubtle ? Colors.grey : Colors.black,
            fontSize: isSubtle ? 13 : 14,
          ),
        ),
      ],
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
