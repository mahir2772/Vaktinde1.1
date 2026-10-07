import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';

import '../../../data/services/economy_service.dart';
import '../../common/ad_consent.dart';
import '../../common/ad_helper.dart';

/// "1.234,56", "2500,50", "2500.5" → sayı. Tek ayraç ondalık sayılır; aynı
/// ayraç birden çok geçerse binlik ayracıdır; iki farklı ayraç varsa sonuncusu
/// ondalıktır. Okunamazsa 0.
double parseAmount(String text) {
  final s = text.replaceAll(RegExp(r'[\s₺]'), '');
  if (s.isEmpty) return 0;
  final lastComma = s.lastIndexOf(',');
  final lastDot = s.lastIndexOf('.');
  var decimalAt = lastComma > lastDot ? lastComma : lastDot;
  if (decimalAt >= 0) {
    final sep = s[decimalAt];
    final hasOther = s.contains(sep == ',' ? '.' : ',');
    if (!hasOther && sep.allMatches(s).length > 1) decimalAt = -1;
  }
  final String normalized;
  if (decimalAt < 0) {
    normalized = s.replaceAll(RegExp(r'[.,]'), '');
  } else {
    final whole = s.substring(0, decimalAt).replaceAll(RegExp(r'[.,]'), '');
    final fraction = s.substring(decimalAt + 1);
    normalized = '${whole.isEmpty ? '0' : whole}.$fraction';
  }
  return double.tryParse(normalized) ?? 0;
}

// Servis/hesap anahtarları (ekranda yerelleştirilmiş adları gösterilir)
const String _tryKey = 'Türk Lirası (TRY)';
const String _manualKey = 'Diğer (Manuel)';
const String _gold24Key = '24 Ayar Gram Altın';

/// Diğer varlık ve tarım ürünü türleri: sadece etiket, hesabı etkilemez
enum _OtherAsset { check, bond, sukuk, leaseCert, stock }

enum _AgriType { soil, soilless }

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
  bool _adShown = false;

  final GlobalKey _resultKey = GlobalKey();

  String _selectedGoldType = _gold24Key;
  String _selectedCurrencyType = 'Amerikan Doları (USD)';
  String _selectedCommercialCurrencyType = _tryKey;
  _OtherAsset _selectedOtherAssetType = _OtherAsset.stock;
  String _selectedOtherCurrencyType = _tryKey;
  String _selectedReceivableAssetType = _tryKey;
  String _selectedDebtAssetType = _tryKey;

  _AgriType _selectedAgriType = _AgriType.soil;
  double _agriculturalRate = 0.10;

  // Canlı fiyat yoksa nisab için elle girilen 24 ayar gram altın fiyatı
  final TextEditingController _nisabGoldPriceController =
      TextEditingController();

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
    if (!AdConsent.canRequestAds.value) return;
    InterstitialAd.load(
      adUnitId: AdIds.zakatInterstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) => ad.dispose(),
            onAdFailedToShowFullScreenContent: (ad, err) => ad.dispose(),
          );
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (err) {
          debugPrint('Reklam yüklenemedi: $err');
          _interstitialAd = null;
        },
      ),
    );
  }

  // Sonuç reklamı beklemez; reklam (varsa) ziyaret başına bir kez gösterilir
  void _maybeShowAd() {
    if (!AdConsent.canRequestAds.value) return;
    final ad = _interstitialAd;
    if (ad == null || _adShown) return;
    _adShown = true;
    _interstitialAd = null;
    ad.show();
  }

  void _refreshRates() {
    if (_isLoadingRates) return;
    setState(() => _isLoadingRates = true);
    _fetchLiveRates();
  }

  Future<void> _fetchLiveRates() async {
    Map<String, double> rates;
    try {
      rates = await _economyService.getLiveRates();
    } catch (_) {
      rates = {};
    }
    if (!mounted) return;
    setState(() {
      _liveRates = rates;
      _isLoadingRates = false;
      // Yenilemede canlı değeri olmayan alanlardaki elle girilen değer korunur
      _applyRate(_goldPriceController, _selectedGoldType, keepManual: true);
      _applyRate(
        _currencyRateController,
        _selectedCurrencyType,
        keepManual: true,
      );
      _applyRate(
        _commercialRateController,
        _selectedCommercialCurrencyType,
        keepManual: true,
      );
      _applyRate(
        _otherAssetsRateController,
        _selectedOtherCurrencyType,
        keepManual: true,
      );
      _applyRate(
        _receivableRateController,
        _selectedReceivableAssetType,
        keepManual: true,
      );
      _applyRate(
        _debtRateController,
        _selectedDebtAssetType,
        keepManual: true,
      );
    });
  }

  bool get _hasLiveGold => _liveRates.containsKey(_gold24Key);

  /// Seçilen türün TL karşılığını alana yazar: TL → 1.00, canlı kur varsa o;
  /// yoksa (tür değiştiyse) alan boşalır ve elle girilir.
  void _applyRate(
    TextEditingController controller,
    String key, {
    bool keepManual = false,
  }) {
    if (key == _tryKey) {
      controller.text = "1.00";
      return;
    }
    final live = _liveRates[key];
    if (live != null) {
      controller.text = live.toStringAsFixed(2);
      return;
    }
    // Canlı fiyat yok: 24 ayar için nisab alanına girilen fiyat kullanılır
    if (key == _gold24Key && _nisabGoldPriceController.text.trim().isNotEmpty) {
      controller.text = _nisabGoldPriceController.text.trim();
      return;
    }
    if (!keepManual) controller.clear();
  }

  void _onNisabGoldPriceChanged(String value) {
    if (_selectedGoldType == _gold24Key && !_hasLiveGold) {
      _goldPriceController.text = value.trim();
    }
  }

  void _handleCalculateButton() {
    FocusScope.of(context).unfocus();
    _performCalculation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _resultKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 300),
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        );
      }
    });
    _maybeShowAd();
  }

  void _performCalculation() {
    double goldCount = parseAmount(_goldCountController.text);
    double goldPrice = parseAmount(_goldPriceController.text);
    double totalGoldValue = goldCount * goldPrice;

    double silverCount = parseAmount(_silverCountController.text);
    double silverPrice = parseAmount(_silverPriceController.text);
    double totalSilverValue = silverCount * silverPrice;

    double currencyAmount = parseAmount(_currencyAmountController.text);
    double currencyRate = parseAmount(_currencyRateController.text);
    double totalCurrencyValue = currencyAmount * currencyRate;

    double commercialAmount = parseAmount(_commercialGoodsController.text);
    double commercialRate = parseAmount(_commercialRateController.text);
    double totalCommercialValue = commercialAmount * commercialRate;

    double otherAssetsValue = parseAmount(_otherAssetsValueController.text);
    double otherAssetsRate = parseAmount(_otherAssetsRateController.text);
    double totalOtherAssetsValue = otherAssetsValue * otherAssetsRate;

    double receivableAmount = parseAmount(_receivableAmountController.text);
    double receivableRate = parseAmount(_receivableRateController.text);
    double totalReceivablesValue = receivableAmount * receivableRate;

    double debtAmount = parseAmount(_debtAmountController.text);
    double debtRate = parseAmount(_debtRateController.text);
    double totalDebtValue = debtAmount * debtRate;

    double cash = parseAmount(_cashController.text);

    double current24kPrice = _liveRates[_gold24Key] ?? 0;
    if (current24kPrice == 0) {
      current24kPrice = parseAmount(_nisabGoldPriceController.text);
    }
    if (current24kPrice == 0 &&
        _selectedGoldType == _gold24Key &&
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

    double agriValue = parseAmount(_agriculturalValueController.text);
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
    for (final c in [
      _nisabGoldPriceController,
      _goldCountController,
      _goldPriceController,
      _silverCountController,
      _silverPriceController,
      _currencyAmountController,
      _currencyRateController,
      _cashController,
      _commercialGoodsController,
      _commercialRateController,
      _otherAssetsValueController,
      _otherAssetsRateController,
      _receivableAmountController,
      _receivableRateController,
      _debtAmountController,
      _debtRateController,
      _agriculturalValueController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // --- Etiketler ---

  Map<String, String> _goldLabels(AppLocalizations loc) => {
    _gold24Key: loc.goldGram,
    '22 Ayar Gram Altın': loc.gold22kGram,
    'Ata Toptan': loc.goldAtaToptan,
    'Ata Cumhuriyet': loc.goldAtaCumhuriyet,
    '22 Ayar Bilezik': loc.gold22kBracelet,
    '18 Ayar Altın': loc.gold18k,
    '14 Ayar Altın': loc.gold14k,
    'Çeyrek Altın': loc.goldQuarter,
    'Yarım Altın': loc.goldHalf,
    'Teklik (Tam) Altın': loc.goldFull,
    'Gremse Altın': loc.goldGremse,
    'Ata Beşli': loc.goldAtaBesli,
    'Reşat Altın': loc.goldResat,
    'Hamit Altın': loc.goldHamit,
  };

  Map<String, String> _currencyLabels(AppLocalizations loc) => {
    'Amerikan Doları (USD)': loc.usd,
    'Euro (EUR)': loc.eur,
    'İsviçre Frangı (CHF)': '${loc.currencyChf} (CHF)',
    'İngiliz Sterlini (GBP)': loc.gbp,
    'Japon Yeni (JPY)': '${loc.currencyJpy} (JPY)',
    'Suudi Arabistan Riyali (SAR)': '${loc.currencySar} (SAR)',
    'Avustralya Doları (AUD)': '${loc.currencyAud} (AUD)',
    'Kanada Doları (CAD)': '${loc.currencyCad} (CAD)',
    'Rus Rublesi (RUB)': '${loc.currencyRub} (RUB)',
    'Azerbaycan Manatı (AZN)': '${loc.currencyAzn} (AZN)',
    'Çin Yuanı (CNY)': '${loc.currencyCny} (CNY)',
    'Romanya Leyi (RON)': '${loc.currencyRon} (RON)',
    'BAE Dirhemi (AED)': '${loc.currencyAed} (AED)',
    'Bulgar Levası (BGN)': '${loc.currencyBgn} (BGN)',
    'Kuveyt Dinarı (KWD)': '${loc.currencyKwd} (KWD)',
  };

  String _otherAssetLabel(_OtherAsset type, AppLocalizations loc) =>
      switch (type) {
        _OtherAsset.check => loc.assetCheck,
        _OtherAsset.bond => loc.assetBond,
        _OtherAsset.sukuk => loc.assetSukuk,
        _OtherAsset.leaseCert => loc.assetLeaseCert,
        _OtherAsset.stock => loc.assetStock,
      };

  String _formatTry(double value, String localeName) {
    try {
      return '${NumberFormat.decimalPatternDigits(locale: localeName, decimalDigits: 2).format(value)} ₺';
    } catch (_) {
      return '${value.toStringAsFixed(2)} ₺';
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final goldLabels = _goldLabels(loc);
    final currencyLabels = _currencyLabels(loc);
    final tryLabel = '${loc.currencyTry} (TRY)';

    final generalCurrencyMap = {
      _tryKey: tryLabel,
      ...currencyLabels,
      _manualKey: loc.typeOther,
    };
    final multiAssetMap = {
      _tryKey: tryLabel,
      ...currencyLabels,
      ...goldLabels,
      _manualKey: loc.typeOther,
    };
    final goldDropdownMap = {...goldLabels, _manualKey: loc.typeOther};
    final currencyDropdownMap = {...currencyLabels, _manualKey: loc.typeOther};

    return AppScaffold(
      title: loc.zakatCalculatorTitle,
      actions: [
        IconButton(
          icon: _isLoadingRates
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: theme.appBarTheme.foregroundColor,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.refresh),
          onPressed: _isLoadingRates ? null : _refreshRates,
          tooltip: loc.retry,
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InfoBanner(
              message: '${loc.zakatDescription} ${loc.zakatCurrencyNote}',
            ),
            const SizedBox(height: AppSpacing.md),
            ..._buildRatesStatus(loc),

            _ZakatSection(
              icon: Icons.account_balance_wallet_outlined,
              title: loc.cashAndCurrencyTitle,
              children: [
                _amountField(_cashController, loc.zakatCashTry),
                const SizedBox(height: AppSpacing.md),
                _dropdown<String>(
                  label: loc.currencyType,
                  value: _selectedCurrencyType,
                  items: currencyDropdownMap,
                  onChanged: (val) => setState(() {
                    _selectedCurrencyType = val;
                    _applyRate(_currencyRateController, val);
                  }),
                ),
                const SizedBox(height: AppSpacing.md),
                _pair(
                  _amountField(_currencyAmountController, loc.currencyAmount),
                  _amountField(
                    _currencyRateController,
                    loc.currencyRate,
                    suffix: '₺',
                  ),
                ),
              ],
            ),

            _ZakatSection(
              icon: Icons.monetization_on_outlined,
              title: loc.goldAndSilverTitle,
              children: [
                _dropdown<String>(
                  label: loc.goldType,
                  value: _selectedGoldType,
                  items: goldDropdownMap,
                  onChanged: (val) => setState(() {
                    _selectedGoldType = val;
                    _applyRate(_goldPriceController, val);
                  }),
                ),
                const SizedBox(height: AppSpacing.md),
                _pair(
                  _amountField(_goldCountController, loc.goldAmount),
                  _amountField(
                    _goldPriceController,
                    loc.goldUnitPrice,
                    suffix: '₺',
                  ),
                ),
                const Divider(height: AppSpacing.xxl),
                _pair(
                  _amountField(_silverCountController, loc.silverGram),
                  _amountField(
                    _silverPriceController,
                    loc.unitPrice,
                    suffix: '₺',
                  ),
                ),
              ],
            ),

            _ZakatSection(
              icon: Icons.storefront_outlined,
              title: loc.commercialGoodsTitle,
              children: [
                _dropdown<String>(
                  label: loc.commercialEvalCurrency,
                  value: _selectedCommercialCurrencyType,
                  items: generalCurrencyMap,
                  onChanged: (val) => setState(() {
                    _selectedCommercialCurrencyType = val;
                    _applyRate(_commercialRateController, val);
                  }),
                ),
                const SizedBox(height: AppSpacing.md),
                _pair(
                  _amountField(
                    _commercialGoodsController,
                    loc.commercialGoodsValue,
                  ),
                  _amountField(
                    _commercialRateController,
                    loc.exchangeRateValue,
                    suffix: '₺',
                    readOnly: _selectedCommercialCurrencyType == _tryKey,
                  ),
                ),
              ],
            ),

            _ZakatSection(
              icon: Icons.receipt_long_outlined,
              title: loc.receivablesTitle,
              children: [
                _dropdown<String>(
                  label: loc.receivableType,
                  value: _selectedReceivableAssetType,
                  items: multiAssetMap,
                  onChanged: (val) => setState(() {
                    _selectedReceivableAssetType = val;
                    _applyRate(_receivableRateController, val);
                  }),
                ),
                const SizedBox(height: AppSpacing.md),
                _pair(
                  _amountField(_receivableAmountController, loc.amountOrCount),
                  _amountField(
                    _receivableRateController,
                    loc.exchangeRateValue,
                    suffix: '₺',
                    readOnly: _selectedReceivableAssetType == _tryKey,
                  ),
                ),
              ],
            ),

            _ZakatSection(
              icon: Icons.pie_chart_outline,
              title: loc.otherAssetsTitle,
              children: [
                _dropdown<_OtherAsset>(
                  label: loc.assetType,
                  value: _selectedOtherAssetType,
                  items: {
                    for (final type in _OtherAsset.values)
                      type: _otherAssetLabel(type, loc),
                  },
                  onChanged: (val) =>
                      setState(() => _selectedOtherAssetType = val),
                ),
                const SizedBox(height: AppSpacing.md),
                _dropdown<String>(
                  label: loc.currencyLabel,
                  value: _selectedOtherCurrencyType,
                  items: generalCurrencyMap,
                  onChanged: (val) => setState(() {
                    _selectedOtherCurrencyType = val;
                    _applyRate(_otherAssetsRateController, val);
                  }),
                ),
                const SizedBox(height: AppSpacing.md),
                _pair(
                  _amountField(_otherAssetsValueController, loc.valueOrAmount),
                  _amountField(
                    _otherAssetsRateController,
                    loc.exchangeRateValue,
                    suffix: '₺',
                    readOnly: _selectedOtherCurrencyType == _tryKey,
                  ),
                ),
              ],
            ),

            _ZakatSection(
              icon: Icons.agriculture_outlined,
              title: loc.agriProductsTitle,
              children: [
                InfoBanner(message: loc.agriDiyanetNote),
                const SizedBox(height: AppSpacing.md),
                _dropdown<_AgriType>(
                  label: loc.assetType,
                  value: _selectedAgriType,
                  items: {
                    _AgriType.soil: loc.agriSoil,
                    _AgriType.soilless: loc.agriSoilless,
                  },
                  onChanged: (val) => setState(() => _selectedAgriType = val),
                ),
                const SizedBox(height: AppSpacing.md),
                _amountField(
                  _agriculturalValueController,
                  loc.harvestedProductValue,
                  suffix: '₺',
                ),
                const SizedBox(height: AppSpacing.md),
                _dropdown<double>(
                  label: loc.irrigationMethod,
                  value: _agriculturalRate,
                  items: {0.10: loc.agriRateNoCost, 0.05: loc.agriRateCostly},
                  onChanged: (val) => setState(() => _agriculturalRate = val),
                ),
              ],
            ),

            _ZakatSection(
              icon: Icons.money_off,
              title: loc.debtsTitle,
              children: [
                _dropdown<String>(
                  label: loc.debtType,
                  value: _selectedDebtAssetType,
                  items: multiAssetMap,
                  onChanged: (val) => setState(() {
                    _selectedDebtAssetType = val;
                    _applyRate(_debtRateController, val);
                  }),
                ),
                const SizedBox(height: AppSpacing.md),
                _pair(
                  _amountField(_debtAmountController, loc.amountOrCount),
                  _amountField(
                    _debtRateController,
                    loc.exchangeRateValue,
                    suffix: '₺',
                    readOnly: _selectedDebtAssetType == _tryKey,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: _handleCalculateButton,
              icon: const Icon(Icons.calculate_outlined),
              label: Text(loc.calculateButton),
            ),
            const SizedBox(height: AppSpacing.lg),

            if (_isCalculated) _buildResult(loc),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRatesStatus(AppLocalizations loc) {
    if (_isLoadingRates) {
      return [
        InfoBanner(icon: Icons.downloading, message: loc.liveRatesLoading),
        const SizedBox(height: AppSpacing.md),
      ];
    }
    if (_hasLiveGold) {
      return [
        InfoBanner(
          tone: InfoTone.success,
          message: loc.liveRatesInfo,
        ),
        const SizedBox(height: AppSpacing.md),
      ];
    }
    // Canlı kur yok (anahtar/ağ yok): fiyatlar elle; nisab için gram altın
    return [
      InfoBanner(tone: InfoTone.warning, message: loc.zakatRatesUnavailable),
      const SizedBox(height: AppSpacing.md),
      AppCard(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        child: TextField(
          controller: _nisabGoldPriceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [_amountFormatter],
          onChanged: _onNisabGoldPriceChanged,
          decoration: InputDecoration(
            labelText: loc.zakatGoldGramPrice,
            helperText: loc.zakatGoldGramPriceHelp,
            helperMaxLines: 3,
            prefixIcon: const Icon(Icons.monetization_on_outlined),
            suffixText: '₺',
          ),
        ),
      ),
    ];
  }

  Widget _buildResult(AppLocalizations loc) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final localeName = loc.localeName;
    final nisabUnknown = _nisabThreshold <= 0;

    Widget resultRow(String label, double value, {bool subtle = false}) {
      final color = subtle ? scheme.onSurfaceVariant : scheme.onSurface;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium!.copyWith(color: color),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              _formatTry(value, localeName),
              textDirection: TextDirection.ltr,
              style: theme.textTheme.bodyMedium!.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return AppCard(
      key: _resultKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            liveRegion: true,
            child: InfoBanner(
              tone: _isEligible ? InfoTone.success : InfoTone.info,
              icon: _isEligible ? Icons.check_circle_outline : null,
              message: _isEligible ? loc.zakatEligible : loc.zakatNotEligible,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            loc.zakatResultTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge!.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _formatTry(_zakatAmount, localeName),
              textDirection: TextDirection.ltr,
              style: theme.textTheme.headlineMedium!.copyWith(
                color: _isEligible ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
          ),
          const Divider(height: AppSpacing.xxl),
          resultRow(loc.netAssets, _totalAssets),
          resultRow(loc.nisabLimit, _nisabThreshold, subtle: true),
          if (_agriZakatAmount > 0)
            resultRow(loc.zakatAgriIncluded, _agriZakatAmount, subtle: true),
          if (nisabUnknown) ...[
            const SizedBox(height: AppSpacing.md),
            InfoBanner(tone: InfoTone.warning, message: loc.zakatNisabUnknown),
          ] else if (!_isEligible) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              loc.belowNisabMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium!.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- Form parçaları ---

  static final TextInputFormatter _amountFormatter =
      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'));

  Widget _amountField(
    TextEditingController controller,
    String label, {
    String? suffix,
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [_amountFormatter],
      decoration: InputDecoration(labelText: label, suffixText: suffix),
    );
  }

  /// Dar ekranda / büyük yazıda iki alan alt alta
  Widget _pair(Widget first, Widget second) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(1);
        if (constraints.maxWidth < 300 * scale) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [first, const SizedBox(height: AppSpacing.md), second],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: second),
          ],
        );
      },
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T value,
    required Map<T, String> items,
    required ValueChanged<T> onChanged,
  }) {
    final theme = Theme.of(context);
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: items.containsKey(value) ? value : null,
          isDense: true,
          isExpanded: true,
          menuMaxHeight: 420,
          style: theme.textTheme.bodyLarge,
          items: [
            for (final entry in items.entries)
              DropdownMenuItem<T>(
                value: entry.key,
                child: Text(entry.value, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
        ),
      ),
    );
  }
}

/// Açılır kapanır bölüm kartı (tek ikon rengi)
class _ZakatSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _ZakatSection({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        leading: Container(
          width: AppSizes.iconBox,
          height: AppSizes.iconBox,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(icon, size: 22, color: scheme.onPrimaryContainer),
        ),
        title: Text(
          title,
          style: theme.textTheme.bodyLarge!.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xs,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}
