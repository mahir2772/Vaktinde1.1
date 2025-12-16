import 'dart:convert';
import 'package:http/http.dart' as http;

class EconomyService {
  final String _apiKey = "apikey 7LiBL1SnVHNhH3cHfzg6sM:3QO6gRHqAEPMA4KS0lcbcu";

  Future<Map<String, double>> getLiveRates() async {
    Map<String, double> rates = {};

    try {
      print("💰 Ekonomi verileri çekiliyor...");

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

          _addRate(rates, data, 'Gram Altın', 'Gram Altın (24 Ayar)');
          _addRate(rates, data, 'Çeyrek Altın', 'Çeyrek Altın');
          _addRate(rates, data, 'Tam Altın', 'Tam Altın');
        }
      } else {
        print("❌ Altın API Hatası: ${goldResponse.statusCode}");
      }

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

          _addCurrencyRate(rates, data, 'USD', 'ABD Doları (USD)');
          _addCurrencyRate(rates, data, 'EUR', 'Euro (EUR)');
          _addCurrencyRate(rates, data, 'GBP', 'İngiliz Sterlini (GBP)');
        }
      } else {
        print("❌ Döviz API Hatası: ${currencyResponse.statusCode}");
      }
    } catch (e) {
      print("Ekonomi Servis Çökmesi: $e");
    }

    return rates;
  }

  void _addRate(
    Map<String, double> rates,
    List<dynamic> data,
    String apiName,
    String myKey,
  ) {
    var item = data.firstWhere((e) => e['name'] == apiName, orElse: () => null);
    if (item != null) {
      rates[myKey] = _parsePrice(item['buying']);
      print("   -> $myKey: ${rates[myKey]}");
    }
  }

  void _addCurrencyRate(
    Map<String, double> rates,
    List<dynamic> data,
    String code,
    String myKey,
  ) {
    var item = data.firstWhere((e) => e['code'] == code, orElse: () => null);
    if (item != null) {
      rates[myKey] = _parsePrice(item['buying']);
      print("   -> $myKey: ${rates[myKey]}");
    }
  }

  double _parsePrice(dynamic price) {
    if (price == null) return 0.0;
    if (price is double) return price;
    if (price is int) return price.toDouble();
    if (price is String) {
      // "2.450,50" -> Noktayı sil, virgülü nokta yap -> "2450.50"
      String clean = price.replaceAll('.', '').replaceAll(',', '.');
      return double.tryParse(clean) ?? 0.0;
    }
    return 0.0;
  }
}
