import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class IlIlceService {
  // Önbellek
  Map<String, List<String>>? _cacheData;

  Future<Map<String, List<String>>?> getIlIlceListesi() async {
    // Hafızada varsa döndür
    if (_cacheData != null) return _cacheData;

    try {
      // 1. Assets'ten JSON dosyasını oku
      final String jsonString = await rootBundle.loadString(
        'assets/data/il_ilce.json',
      );

      // 2. JSON'u Map formatına çevir
      final Map<String, dynamic> decoded = json.decode(jsonString);

      Map<String, List<String>> result = {};

      decoded.forEach((key, value) {
        // Gelen dinamik listeyi String listesine çevirip sıralıyoruz
        List<String> ilceler = List<String>.from(value);
        ilceler.sort();
        result[key] = ilceler;
      });

      _cacheData = result;
      return result;
    } catch (e) {
      print("❌ İl-İlçe JSON Okuma Hatası: $e");
      return null;
    }
  }
}
