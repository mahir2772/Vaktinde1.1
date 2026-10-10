import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import 'http_client.dart';
import 'prayer_tracker.dart';

/// Kişi başı fitre tutarı (bir günlük fidye de aynı tutardır)
class FitreAmount {
  final double amount;
  final String currency;
  final DateTime validFrom;
  final String source;

  const FitreAmount({
    required this.amount,
    required this.currency,
    required this.validFrom,
    required this.source,
  });
}

/// Fitre/fidye tutarı: gömülü assets/data/fitre.json + GitHub Pages'teki aynı
/// şemalı dosya (docs/site/fitre.json; Diyanet yeni tutarı açıklayınca uygulama
/// güncellemesi beklenmez). Uzak dosyanın son geçerli hali saklanır; bozuksa
/// yok sayılır. Şema:
/// {"currency":"TRY","amounts":[{"validFrom":"yyyy-MM-dd","amount":240,"source":"Diyanet"}]}
class FitreService {
  static const String assetPath = 'assets/data/fitre.json';
  static final Uri remoteUrl = Uri.parse(
    'https://mahir2772.github.io/fitre.json',
  );

  /// Son geçerli uzak dosya (ham json)
  static const String cacheKey = 'fitre_remote_json';

  final Future<String> Function() _loadAsset;
  final Future<String?> Function(Uri url) _fetch;

  /// [loadAsset] / [fetch]: test için (varsayılan: rootBundle, httpGet 10 sn)
  FitreService({
    Future<String> Function()? loadAsset,
    Future<String?> Function(Uri url)? fetch,
  }) : _loadAsset = loadAsset ?? (() => rootBundle.loadString(assetPath)),
       _fetch = fetch ?? _httpFetch;

  static Future<String?> _httpFetch(Uri url) async {
    final response = await httpGet(url);
    return response.statusCode == 200 ? response.body : null;
  }

  /// Metindeki geçerli kayıtlar; bozuk kayıt atlanır, dosya bozuksa boş liste
  static List<FitreAmount> parse(String? raw) {
    if (raw == null) return const [];
    try {
      final data = jsonDecode(raw);
      if (data is! Map) return const [];
      final currency = data['currency'];
      final amounts = data['amounts'];
      if (currency is! String || currency.trim().isEmpty || amounts is! List) {
        return const [];
      }
      return [
        for (final e in amounts)
          if (_entry(e, currency.trim()) case final entry?) entry,
      ];
    } catch (_) {
      return const [];
    }
  }

  static FitreAmount? _entry(Object? e, String currency) {
    if (e is! Map) return null;
    final amount = e['amount'];
    final from = e['validFrom'];
    final source = e['source'];
    if (amount is! num || !amount.isFinite || amount <= 0 || from is! String) {
      return null;
    }
    final date = PrayerTracker.parseDateKey(from);
    if (date == null) return null;
    return FitreAmount(
      amount: amount.toDouble(),
      currency: currency,
      validFrom: date,
      source: source is String && source.trim().isNotEmpty
          ? source.trim()
          : 'Diyanet',
    );
  }

  /// [today] günü geçerli tutar: başlangıcı bugün ya da daha önce olan en yeni
  /// kayıt. Aynı başlangıç tarihinde sonraki kayıt (uzak dosya) kazanır.
  static FitreAmount? select(Iterable<FitreAmount> entries, DateTime today) {
    FitreAmount? best;
    for (final e in entries) {
      if (PrayerTracker.daysBetween(e.validFrom, today) < 0) continue;
      if (best == null || !e.validFrom.isBefore(best.validFrom)) best = e;
    }
    return best;
  }

  /// Gömülü dosya + saklanan uzak dosya (ağsız)
  Future<FitreAmount?> loadLocal(DateTime today) async {
    var bundled = const <FitreAmount>[];
    String? cached;
    try {
      bundled = parse(await _loadAsset());
    } catch (_) {}
    try {
      cached = (await SharedPreferences.getInstance()).getString(cacheKey);
    } catch (_) {}
    return select([...bundled, ...parse(cached)], today);
  }

  /// Uzak dosyayı indirir, geçerliyse saklar; ağ yoksa ya da dosya bozuksa
  /// yerel sonuç döner
  Future<FitreAmount?> refresh(DateTime today) async {
    try {
      final raw = await _fetch(remoteUrl);
      if (raw != null && parse(raw).isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(cacheKey, raw);
      }
    } catch (_) {}
    return loadLocal(today);
  }
}
