import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdHelper {
  // Singleton yapısı: Uygulama boyunca sadece 1 tane AdHelper yaşar
  static final AdHelper instance = AdHelper._internal();
  AdHelper._internal();

  InterstitialAd? _interstitialAd;
  DateTime? _lastAdShowTime;

  // SOĞUMA SÜRESİ: 5 dakika geçmeden 2. kez tam ekran reklam ÇIKMAZ.
  final int _cooldownMinutes = 5;

  // Platforma göre otomatik test reklamı seçen yapı
  String get _interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-4975388193054410/8232165658'; // Android Geçiş Test ID
    } else {
      throw UnsupportedError('Desteklenmeyen platform');
    }
  }

  // Arka planda reklamı önceden yükler
  void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          debugPrint('Tam ekran reklam hazırda bekliyor.');

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              loadInterstitialAd(); // Kapanınca hemen yenisini pusuya yatır
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (err) {
          debugPrint('Tam ekran reklam yüklenemedi: $err');
          _interstitialAd = null;
        },
      ),
    );
  }

  // Reklam gösterme fonksiyonu (Süreyi kontrol eder)
  void showInterstitialAd() {
    final now = DateTime.now();

    // Soğuma süresi kontrolü
    if (_lastAdShowTime != null &&
        now.difference(_lastAdShowTime!).inMinutes < _cooldownMinutes) {
      debugPrint('Reklam soğuma süresinde. Kullanıcıyı darlamıyoruz.');
      return;
    }

    if (_interstitialAd != null) {
      _interstitialAd!.show();
      _lastAdShowTime = now;
    } else {
      loadInterstitialAd(); // Yüklü değilse arkadan yükle
    }
  }
}
