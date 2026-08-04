import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import '../../../data/services/economy_service.dart';
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

  InterstitialAd? _interstitialAd;
  //Kendi reklam kodum
  //final String _adUnitId = 'ca-app-pub-4975388193054410/2151461471';
  final String _adUnitId = 'ca-app-pub-3940256099942544/1033173712';

  String _selectedGoldType = '24 Ayar Gram Altın';
  String _selectedCurrencyType = 'Amerikan Doları (USD)';
  String _selectedCommercialCurrencyType = 'Türk Lirası (TRY)';
  String _selectedOtherAssetType = 'Hisse Senedi';
  String _selectedOtherCurrencyType = 'Türk Lirası (TRY)';
  String _selectedReceivableAssetType = 'Türk Lirası (TRY)';
  String _selectedDebtAssetType = 'Türk Lirası (TRY)';

  String _selectedAgriType = 'Zirai Ürün (Topraklı Tarım)';
  double _agriculturalRate = 0.10;

  final TextEditingController _goldCountController = TextEditingController();
  final TextEditingController _goldPriceController = TextEditingController();
  final TextEditingController _silverCountController = TextEditingController();
  final TextEditingController _silverPriceController = TextEditingController();

  final TextEditingController _currencyAmountController =
      TextEditingController();
  final TextEditingController _currencyRateController = TextEditingController();

  final TextEditingController _cashController = TextEditingController();
  final TextEditingController _commercialGoodsController =
      TextEditingController();
  final TextEditingController _commercialRateController = TextEditingController(
    text: "1.00",
  );

  final TextEditingController _otherAssetsValueController =
      TextEditingController();
  final TextEditingController _otherAssetsRateController =
      TextEditingController(text: "1.00");

  final TextEditingController _receivableAmountController =
      TextEditingController();
  final TextEditingController _receivableRateController = TextEditingController(
    text: "1.00",
  );

  final TextEditingController _debtAmountController = TextEditingController();
  final TextEditingController _debtRateController = TextEditingController(
    text: "1.00",
  );

  final TextEditingController _agriculturalValueController =
      TextEditingController();

  double _totalAssets = 0;
  double _zakatAmount = 0;
  double _agriZakatAmount = 0;
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
        _updateCommercialRateField();
        _updateOtherAssetsRateField();
        _updateReceivableRateField();
        _updateDebtRateField();
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

  void _updateCommercialRateField() {
    if (_selectedCommercialCurrencyType == 'Türk Lirası (TRY)') {
      _commercialRateController.text = "1.00";
    } else if (_liveRates.containsKey(_selectedCommercialCurrencyType)) {
      _commercialRateController.text =
          _liveRates[_selectedCommercialCurrencyType]!.toStringAsFixed(2);
    } else {
      _commercialRateController.clear();
    }
  }

  void _updateOtherAssetsRateField() {
    if (_selectedOtherCurrencyType == 'Türk Lirası (TRY)') {
      _otherAssetsRateController.text = "1.00";
    } else if (_liveRates.containsKey(_selectedOtherCurrencyType)) {
      _otherAssetsRateController.text = _liveRates[_selectedOtherCurrencyType]!
          .toStringAsFixed(2);
    } else {
      _otherAssetsRateController.clear();
    }
  }

  void _updateReceivableRateField() {
    if (_selectedReceivableAssetType == 'Türk Lirası (TRY)') {
      _receivableRateController.text = "1.00";
    } else if (_liveRates.containsKey(_selectedReceivableAssetType)) {
      _receivableRateController.text = _liveRates[_selectedReceivableAssetType]!
          .toStringAsFixed(2);
    } else {
      _receivableRateController.clear();
    }
  }

  void _updateDebtRateField() {
    if (_selectedDebtAssetType == 'Türk Lirası (TRY)') {
      _debtRateController.text = "1.00";
    } else if (_liveRates.containsKey(_selectedDebtAssetType)) {
      _debtRateController.text = _liveRates[_selectedDebtAssetType]!
          .toStringAsFixed(2);
    } else {
      _debtRateController.clear();
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

    double silverCount = double.tryParse(_silverCountController.text) ?? 0;
    double silverPrice = double.tryParse(_silverPriceController.text) ?? 0;
    double totalSilverValue = silverCount * silverPrice;

    double currencyAmount =
        double.tryParse(_currencyAmountController.text) ?? 0;
    double currencyRate = double.tryParse(_currencyRateController.text) ?? 0;
    double totalCurrencyValue = currencyAmount * currencyRate;

    double commercialAmount =
        double.tryParse(_commercialGoodsController.text) ?? 0;
    double commercialRate =
        double.tryParse(_commercialRateController.text) ?? 0;
    double totalCommercialValue = commercialAmount * commercialRate;

    double otherAssetsValue =
        double.tryParse(_otherAssetsValueController.text) ?? 0;
    double otherAssetsRate =
        double.tryParse(_otherAssetsRateController.text) ?? 0;
    double totalOtherAssetsValue = otherAssetsValue * otherAssetsRate;

    double receivableAmount =
        double.tryParse(_receivableAmountController.text) ?? 0;
    double receivableRate =
        double.tryParse(_receivableRateController.text) ?? 0;
    double totalReceivablesValue = receivableAmount * receivableRate;

    double debtAmount = double.tryParse(_debtAmountController.text) ?? 0;
    double debtRate = double.tryParse(_debtRateController.text) ?? 0;
    double totalDebtValue = debtAmount * debtRate;

    double cash = double.tryParse(_cashController.text) ?? 0;

    double current24kPrice = _liveRates['24 Ayar Gram Altın'] ?? 0;
    if (current24kPrice == 0 &&
        _selectedGoldType == '24 Ayar Gram Altın' &&
        goldPrice > 0) {
      current24kPrice = goldPrice;
    }
    double calculatedNisab = current24kPrice * 80.18;

    double totalWealth =
        (totalGoldValue +
            totalSilverValue +
            totalCurrencyValue +
            cash +
            totalCommercialValue +
            totalOtherAssetsValue +
            totalReceivablesValue) -
        totalDebtValue;
    if (totalWealth < 0) totalWealth = 0;

    double wealthZakat = 0;
    bool isEligibleForWealth = false;

    if (totalWealth >= calculatedNisab && totalWealth > 0) {
      wealthZakat = totalWealth / 40;
      isEligibleForWealth = true;
    }

    double agriValue = double.tryParse(_agriculturalValueController.text) ?? 0;
    double agriZakat = agriValue * _agriculturalRate;

    setState(() {
      _totalAssets = totalWealth;
      _nisabThreshold = calculatedNisab;
      _agriZakatAmount = agriZakat;
      _zakatAmount = wealthZakat + agriZakat;

      _isEligible = isEligibleForWealth || (agriZakat > 0);
      _isCalculated = true;
    });
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();
    _goldCountController.dispose();
    _goldPriceController.dispose();
    _silverCountController.dispose();
    _silverPriceController.dispose();
    _currencyAmountController.dispose();
    _currencyRateController.dispose();
    _cashController.dispose();
    _commercialGoodsController.dispose();
    _commercialRateController.dispose();
    _otherAssetsValueController.dispose();
    _otherAssetsRateController.dispose();
    _receivableAmountController.dispose();
    _receivableRateController.dispose();
    _debtAmountController.dispose();
    _debtRateController.dispose();
    _agriculturalValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    // Burada Map'in KEY kısmı servisle uyuşması için orijinal kalmalı,
    // VALUE kısmı ise arayüzde görüneceği için loc. olarak güncellendi.
    final Map<String, String> goldTypeMap = {
      '24 Ayar Gram Altın': loc.goldGram,
      '22 Ayar Gram Altın': '22 Ayar Gram Altın',
      'Ata Toptan': 'Ata Toptan',
      'Ata Cumhuriyet': 'Ata Cumhuriyet',
      '22 Ayar Bilezik': '22 Ayar Bilezik',
      '18 Ayar Altın': '18 Ayar Altın',
      '14 Ayar Altın': '14 Ayar Altın',
      'Çeyrek Altın': loc.goldQuarter,
      'Yarım Altın': 'Yarım Altın',
      'Teklik (Tam) Altın': loc.goldFull,
      'Gremse Altın': 'Gremse Altın',
      'Ata Beşli': 'Ata Beşli',
      'Reşat Altın': 'Reşat Altın',
      'Hamit Altın': 'Hamit Altın',
    };

    final Map<String, String> currencyTypeMap = {
      'Amerikan Doları (USD)': loc.usd,
      'Euro (EUR)': loc.eur,
      'İsviçre Frangı (CHF)': 'İsviçre Frangı',
      'İngiliz Sterlini (GBP)': loc.gbp,
      'Japon Yeni (JPY)': 'Japon Yeni',
      'Suudi Arabistan Riyali (SAR)': 'Suudi Arabistan Riyali',
      'Avustralya Doları (AUD)': 'Avustralya Doları',
      'Kanada Doları (CAD)': 'Kanada Doları',
      'Rus Rublesi (RUB)': 'Rus Rublesi',
      'Azerbaycan Manatı (AZN)': 'Azerbaycan Manatı',
      'Çin Yuanı (CNY)': 'Çin Yuanı',
      'Romanya Leyi (RON)': 'Romanya Leyi',
      'BAE Dirhemi (AED)': 'BAE Dirhemi',
      'Bulgar Levası (BGN)': 'Bulgar Levası',
      'Kuveyt Dinarı (KWD)': 'Kuveyt Dinarı',
    };

    final Map<String, String> generalCurrencyMap = {
      'Türk Lirası (TRY)': 'Türk Lirası',
      ...currencyTypeMap,
      'Diğer (Manuel)': loc.typeOther,
    };

    final Map<String, String> multiAssetMap = {
      'Türk Lirası (TRY)': 'Türk Lirası',
      ...currencyTypeMap,
      ...goldTypeMap,
      'Diğer (Manuel)': loc.typeOther,
    };

    final List<String> otherAssetsList = [
      loc.assetCheck,
      loc.assetBond,
      loc.assetSukuk,
      loc.assetLeaseCert,
      loc.assetStock,
    ];

    final List<String> agriTypesList = [loc.agriSoil, loc.agriSoilless];

    final Map<String, String> goldDropdownMap = {
      ...goldTypeMap,
      'Diğer (Manuel)': loc.typeOther,
    };

    final Map<String, String> currencyDropdownMap = {
      ...currencyTypeMap,
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
            tooltip: loc.retry,
          ),
        ],
      ),
      bottomNavigationBar: const SafeArea(child: AdBannerWidget()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isLoadingRates)
              Container(
                margin: const EdgeInsets.only(bottom: 15),
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
                loc.zakatDescription,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 15),

            // --- 1. NAKİT VE DÖVİZ ---
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                leading: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.teal,
                ),
                title: Text(
                  loc.cashAndCurrencyTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                childrenPadding: const EdgeInsets.all(15),
                children: [
                  TextField(
                    controller: _cashController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: loc.cashTurkishLira,
                      border: const OutlineInputBorder(),
                      suffixText: "₺",
                    ),
                  ),
                  const SizedBox(height: 15),
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
                        items: currencyDropdownMap.entries.map((entry) {
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
                          readOnly: true,
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

            // --- 2. ALTIN VE GÜMÜŞ ---
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                leading: const Icon(Icons.monetization_on, color: Colors.amber),
                title: Text(
                  loc.goldAndSilverTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                childrenPadding: const EdgeInsets.all(15),
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
                        items: goldDropdownMap.entries.map((entry) {
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
                          readOnly: true,
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
                  const Divider(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _silverCountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: loc.silverGram,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _silverPriceController,
                          readOnly: true,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: loc.unitPrice,
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

            // --- 3. TİCARİ MALLAR ---
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                leading: const Icon(Icons.storefront, color: Colors.blue),
                title: Text(
                  loc.commercialGoodsTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                childrenPadding: const EdgeInsets.all(15),
                children: [
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: loc.commercialEvalCurrency,
                      border: const OutlineInputBorder(),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCommercialCurrencyType,
                        isDense: true,
                        isExpanded: true,
                        items: generalCurrencyMap.entries.map((entry) {
                          return DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(entry.value),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedCommercialCurrencyType = val!;
                            _updateCommercialRateField();
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
                          controller: _commercialGoodsController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: loc.commercialGoodsValue,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _commercialRateController,
                          readOnly: true,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: loc.exchangeRateValue,
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

            // --- 4. ALACAKLAR ---
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                leading: const Icon(Icons.receipt_long, color: Colors.orange),
                title: Text(
                  loc.receivablesTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                childrenPadding: const EdgeInsets.all(15),
                children: [
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: loc.receivableType,
                      border: const OutlineInputBorder(),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedReceivableAssetType,
                        isDense: true,
                        isExpanded: true,
                        items: multiAssetMap.entries.map((entry) {
                          return DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(entry.value),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedReceivableAssetType = val!;
                            _updateReceivableRateField();
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
                          controller: _receivableAmountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: loc.amountOrCount,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _receivableRateController,
                          readOnly: true,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: loc.exchangeRateValue,
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

            // --- 5. DİĞER VARLIKLAR ---
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                leading: const Icon(Icons.pie_chart, color: Colors.deepPurple),
                title: Text(
                  loc.otherAssetsTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                childrenPadding: const EdgeInsets.all(15),
                children: [
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: loc.assetType,
                      border: const OutlineInputBorder(),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedOtherAssetType,
                        isDense: true,
                        isExpanded: true,
                        items: otherAssetsList.map((asset) {
                          return DropdownMenuItem<String>(
                            value: asset,
                            child: Text(asset),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedOtherAssetType = val!;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: loc.currencyLabel,
                      border: const OutlineInputBorder(),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedOtherCurrencyType,
                        isDense: true,
                        isExpanded: true,
                        items: generalCurrencyMap.entries.map((entry) {
                          return DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(entry.value),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedOtherCurrencyType = val!;
                            _updateOtherAssetsRateField();
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
                          controller: _otherAssetsValueController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: loc.valueOrAmount,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _otherAssetsRateController,
                          readOnly: true,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: loc.exchangeRateValue,
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

            // --- 6. ZİRAİ ÜRÜNLER (ÖŞÜR) ---
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                leading: const Icon(Icons.agriculture, color: Colors.green),
                title: Text(
                  loc.agriProductsTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                childrenPadding: const EdgeInsets.all(15),
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(
                      color: Colors.cyan.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.cyan.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info, color: Colors.cyan.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            loc.agriDiyanetNote,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.cyan.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: loc.assetType,
                      border: const OutlineInputBorder(),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedAgriType,
                        isDense: true,
                        isExpanded: true,
                        items: agriTypesList.map((type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedAgriType = val!;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _agriculturalValueController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: loc.harvestedProductValue,
                      border: const OutlineInputBorder(),
                      suffixText: "₺",
                    ),
                  ),
                  const SizedBox(height: 10),
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: loc.irrigationMethod,
                      border: const OutlineInputBorder(),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<double>(
                        value: _agriculturalRate,
                        isDense: true,
                        isExpanded: true,
                        items: [
                          DropdownMenuItem(
                            value: 0.10,
                            child: Text(loc.agriRateNoCost),
                          ),
                          DropdownMenuItem(
                            value: 0.05,
                            child: Text(loc.agriRateCostly),
                          ),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _agriculturalRate = val!;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- 7. BORÇLAR ---
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                leading: const Icon(Icons.money_off, color: Colors.red),
                title: Text(
                  loc.debtsTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                childrenPadding: const EdgeInsets.all(15),
                children: [
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: loc.debtType,
                      border: const OutlineInputBorder(),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedDebtAssetType,
                        isDense: true,
                        isExpanded: true,
                        items: multiAssetMap.entries.map((entry) {
                          return DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(entry.value),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedDebtAssetType = val!;
                            _updateDebtRateField();
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
                          controller: _debtAmountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: loc.amountOrCount,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _debtRateController,
                          readOnly: true,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: loc.exchangeRateValue,
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

            const SizedBox(height: 25),

            // --- HESAPLA BUTONU ---
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
            const SizedBox(height: 25),

            // --- SONUÇ EKRANI ---
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

                    if (_agriZakatAmount > 0) ...[
                      const SizedBox(height: 8),
                      _buildResultRow(
                        loc.zakatAgriIncluded,
                        "${_agriZakatAmount.toStringAsFixed(2)} ₺",
                        isSubtle: true,
                      ),
                    ],

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
}
