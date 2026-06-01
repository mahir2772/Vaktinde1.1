import 'dart:convert';
import 'package:http/http.dart' as http;

class EconomyService {
  final String _apiKey = "apikey 7LiBL1SnVHNhH3cHfzg6sM:3QO6gRHqAEPMA4KS0lcbcu";

  Future<Map<String, double>> getLiveRates() async {
    Map<String, double> rates = {};

    try {
      print("💰 Ekonomi verileri çekiliyor (Diyanet Fetva Algoritması)...");

      // 1. ALTIN VERİLERİ
      final goldUrl = Uri.parse("https://api.collectapi.com/economy/goldPrice");
      final goldResponse = await http.get(
        goldUrl,
        headers: {"content-type": "application/json", "authorization": _apiKey},
      );

      if (goldResponse.statusCode == 200) {
        final jsonBody = json.decode(goldResponse.body);
        if (jsonBody['success'] == true) {
          print("✅ Altın verisi alındı!");
          List<dynamic> data = jsonBody['result'];

          var gramItem = data.firstWhere(
            (e) => e['name'] == 'Gram Altın',
            orElse: () => null,
          );

          if (gramItem != null) {
            double gramFiyati = _parsePrice(gramItem['selling']);

            // --- DİYANETİN TÜM ALTIN VE ZİYNET ORANLARI ---
            rates['24 Ayar Gram Altın'] = gramFiyati;
            rates['22 Ayar Gram Altın'] = gramFiyati * (22 / 24); // 0.9166
            rates['Ata Toptan'] = gramFiyati * 6.6146;
            rates['Ata Cumhuriyet'] = gramFiyati * 6.6146;
            rates['22 Ayar Bilezik'] = gramFiyati * (22 / 24);
            rates['18 Ayar Altın'] = gramFiyati * (18 / 24); // 0.7500
            rates['14 Ayar Altın'] = gramFiyati * (14 / 24); // 0.5833
            rates['Çeyrek Altın'] = gramFiyati * 1.6065;
            rates['Yarım Altın'] = gramFiyati * 3.213;
            rates['Teklik (Tam) Altın'] = gramFiyati * 6.426;
            rates['Gremse Altın'] = gramFiyati * 16.065;
            rates['Ata Beşli'] = gramFiyati * 33.073;
            rates['Reşat Altın'] = gramFiyati * 6.6146;
            rates['Hamit Altın'] = gramFiyati * 6.6146;
          }
        }
      }

      // 2. DÖVİZ VERİLERİ
      final currencyUrl = Uri.parse(
        "https://api.collectapi.com/economy/allCurrency",
      );
      final currencyResponse = await http.get(
        currencyUrl,
        headers: {"content-type": "application/json", "authorization": _apiKey},
      );

      if (currencyResponse.statusCode == 200) {
        final jsonBody = json.decode(currencyResponse.body);
        if (jsonBody['success'] == true) {
          print("✅ Döviz verisi alındı!");
          List<dynamic> data = jsonBody['result'];

          _addCurrencyRate(rates, data, 'USD', 'Amerikan Doları (USD)');
          _addCurrencyRate(rates, data, 'EUR', 'Euro (EUR)');
          _addCurrencyRate(rates, data, 'CHF', 'İsviçre Frangı (CHF)');
          _addCurrencyRate(rates, data, 'GBP', 'İngiliz Sterlini (GBP)');
          _addCurrencyRate(rates, data, 'JPY', 'Japon Yeni (JPY)');
          _addCurrencyRate(rates, data, 'SAR', 'Suudi Arabistan Riyali (SAR)');
          _addCurrencyRate(rates, data, 'AUD', 'Avustralya Doları (AUD)');
          _addCurrencyRate(rates, data, 'CAD', 'Kanada Doları (CAD)');
          _addCurrencyRate(rates, data, 'RUB', 'Rus Rublesi (RUB)');
          _addCurrencyRate(rates, data, 'AZN', 'Azerbaycan Manatı (AZN)');
          _addCurrencyRate(rates, data, 'CNY', 'Çin Yuanı (CNY)');
          _addCurrencyRate(rates, data, 'RON', 'Romanya Leyi (RON)');
          _addCurrencyRate(rates, data, 'AED', 'BAE Dirhemi (AED)');
          _addCurrencyRate(rates, data, 'BGN', 'Bulgar Levası (BGN)');
          _addCurrencyRate(rates, data, 'KWD', 'Kuveyt Dinarı (KWD)');
        }
      }

      print("📊 GÜNCEL KURLAR (DİYANET USULÜ): $rates");
    } catch (e) {
      print("❌ Ekonomi Servis Çökmesi: $e");
    }

    return rates;
  }

  void _addCurrencyRate(
    Map<String, double> rates,
    List<dynamic> data,
    String code,
    String myKey,
  ) {
    var item = data.firstWhere((e) => e['code'] == code, orElse: () => null);
    if (item != null) {
      rates[myKey] = _parsePrice(item['selling']);
    }
  }

  double _parsePrice(dynamic price) {
    if (price == null) return 0.0;
    if (price is double) return price;
    if (price is int) return price.toDouble();
    if (price is String) {
      String clean = price.replaceAll('.', '').replaceAll(',', '.');
      return double.tryParse(clean) ?? 0.0;
    }
    return 0.0;
  }
}
