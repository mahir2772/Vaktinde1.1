import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_consent.dart';

/// Reklam birimleri: debug/profile'da Google test ID'leri, release'de gerçek ID'ler.
/// (Geliştirirken kendi reklamına tıklayıp AdMob'dan ban yememek için otomatik seçilir.)
class AdIds {
  static const String _testBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitial =
      'ca-app-pub-3940256099942544/1033173712';

  // Alt menü banner'ı (banner kodu)
  static String get mainBanner =>
      kReleaseMode ? 'ca-app-pub-4975388193054410/3285554173' : _testBanner;
  // İç ekranlar banner'ı
  static String get innerBanner =>
      kReleaseMode ? 'ca-app-pub-4975388193054410/6543014509' : _testBanner;
  // Genel geçiş reklamı (Zikirmatik_Sifirlama_Gecis)
  static String get interstitial => kReleaseMode
      ? 'ca-app-pub-4975388193054410/8232165658'
      : _testInterstitial;
  // Zekat geçiş reklamı
  static String get zakatInterstitial => kReleaseMode
      ? 'ca-app-pub-4975388193054410/2151461471'
      : _testInterstitial;
}

class AdHelper {
  // Singleton yapısı: Uygulama boyunca sadece 1 tane AdHelper yaşar
  static final AdHelper instance = AdHelper._internal();
  AdHelper._internal();

  InterstitialAd? _interstitialAd;
  bool _loading = false;
  DateTime? _lastAdShowTime;

  // SOĞUMA SÜRESİ: 5 dakika geçmeden 2. kez tam ekran reklam ÇIKMAZ.
  final int _cooldownMinutes = 5;

  // Şimdilik sadece Android'de reklam var
  bool get _isSupported => Platform.isAndroid;

  bool _waitingForConsent = false;

  // Arka planda reklamı önceden yükler (rıza/SDK hazır değilse hazır olunca)
  void loadInterstitialAd() {
    if (!_isSupported) return;
    if (!AdConsent.canRequestAds.value) {
      if (!_waitingForConsent) {
        _waitingForConsent = true;
        AdConsent.whenAdsStarted(() {
          _waitingForConsent = false;
          loadInterstitialAd();
        });
      }
      return;
    }
    if (_interstitialAd != null || _loading) return;
    _loading = true;
    InterstitialAd.load(
      adUnitId: AdIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loading = false;
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
          _loading = false;
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
