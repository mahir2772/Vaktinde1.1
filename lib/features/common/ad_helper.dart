import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// Geçiş reklamı yerleri ve sıklığı. Reklam sadece kullanıcının açtığı bir
/// ekrana geçişte istenir (kendiliğinden, açılışta ya da çıkışta değil):
/// Araçlar'daki araçlar (Dualar, Ayarlar, Yakındaki Camiler hariç), ana
/// ekranda "Bugün için" Cuma mesajları / dini günler ve Namaz Takibi. Kur'an,
/// Kıble, Zikir, Dualar/Tesbihat ve Ayarlar hiç reklam göstermez. Yeni
/// kullanıcıya ilk kurulumdan sonraki 24 saat geçiş reklamı yok.
class AdHelper {
  // Singleton yapısı: Uygulama boyunca sadece 1 tane AdHelper yaşar
  static final AdHelper instance = AdHelper._internal();
  AdHelper._internal();

  /// İki geçiş reklamı arasında en az bu kadar süre olur
  static const Duration cooldown = Duration(minutes: 4);

  /// Günde en çok bu kadar geçiş reklamı
  static const int dailyCap = 8;

  /// Yeni kullanıcıya bu cihazdaki ilk kurulumdan sonra bu süre geçiş reklamı
  /// yok (banner'lar değişmez)
  static const Duration newUserGrace = Duration(hours: 24);

  /// Son gösterim + günün sayısı (süreç kapansa da sıklık korunur):
  /// "<epoch ms>|<yyyy-MM-dd>|<sayı>"
  static const String logKey = 'interstitial_log';

  /// Bu cihazdaki ilk kurulum zamanı (InstallGuard açılışta PackageInfo'dan
  /// okur; main.dart verir). Bilinmiyorsa yeni kullanıcı kısıtı uygulanmaz.
  DateTime? installTime;

  InterstitialAd? _interstitialAd;
  bool _loading = false;
  DateTime? _lastAdShowTime;
  String? _countDay;
  int _countToday = 0;
  bool _restored = false;

  // Şimdilik sadece Android'de reklam var
  bool get _isSupported => Platform.isAndroid;

  bool _waitingForConsent = false;

  // Arka planda reklamı önceden yükler (rıza/SDK hazır değilse hazır olunca)
  void loadInterstitialAd() {
    if (!_isSupported) return;
    restoreLog();
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

  static String _day(DateTime t) =>
      '${t.year}-${t.month.toString().padLeft(2, '0')}-'
      '${t.day.toString().padLeft(2, '0')}';

  /// Şu an geçiş reklamı gösterilebilir mi: kurulumdan [newUserGrace] geçti,
  /// son reklamdan [cooldown] geçti ve bugün [dailyCap]'e ulaşılmadı.
  /// Uygulamadaki tüm geçiş reklamları (genel + zekat) bu ortak sınıra uyar.
  /// Saat geri alındıysa (kurulumdan / son reklamdan önceye) beklenmez.
  bool canShowInterstitial([DateTime? now]) {
    final t = now ?? DateTime.now();
    final installed = installTime;
    if (installed != null &&
        !t.isBefore(installed) &&
        t.difference(installed) < newUserGrace) {
      return false;
    }
    final last = _lastAdShowTime;
    if (last != null && !t.isBefore(last) && t.difference(last) < cooldown) {
      return false;
    }
    return !(_countDay == _day(t) && _countToday >= dailyCap);
  }

  /// Bir geçiş reklamı gösterildi (genel ya da zekat): süre ve günlük sayı
  void markInterstitialShown([DateTime? at]) {
    final t = at ?? DateTime.now();
    final day = _day(t);
    _lastAdShowTime = t;
    _countToday = day == _countDay ? _countToday + 1 : 1;
    _countDay = day;
    _save();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        logKey,
        '${_lastAdShowTime!.millisecondsSinceEpoch}|$_countDay|$_countToday',
      );
    } catch (e) {
      debugPrint('Reklam kaydı yazılamadı: $e');
    }
  }

  /// Önceki süreçteki son gösterim ve günün sayısı (bellekteki daha yeniyse o);
  /// ilk yüklemede bir kez
  Future<void> restoreLog() async {
    if (_restored) return;
    _restored = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final parts = prefs.getString(logKey)?.split('|');
      if (parts == null || parts.length != 3) return;
      final ms = int.tryParse(parts[0]);
      final count = int.tryParse(parts[2]);
      if (ms == null || count == null) return;
      final last = DateTime.fromMillisecondsSinceEpoch(ms);
      if (_lastAdShowTime == null || last.isAfter(_lastAdShowTime!)) {
        _lastAdShowTime = last;
      }
      if (_countDay == null || _countDay == parts[1]) {
        _countDay = parts[1];
        if (count > _countToday) _countToday = count;
      }
    } catch (e) {
      debugPrint('Reklam kaydı okunamadı: $e');
    }
  }

  /// Testler: sıklık durumu sıfırlanır
  @visibleForTesting
  void debugReset() {
    installTime = null;
    _lastAdShowTime = null;
    _countDay = null;
    _countToday = 0;
    _restored = false;
  }

  /// Gösterme istekleri (test için; soğuma ve hazır olmama dahil)
  @visibleForTesting
  int debugShowRequests = 0;

  /// Kullanıcının açtığı ekrana geçişte çağrılır; sıklık sınırındaysa ya da
  /// reklam hazır değilse hiçbir şey göstermez (hazır değilse yükler)
  void showInterstitialAd() {
    debugShowRequests++;
    final now = DateTime.now();

    if (!canShowInterstitial(now)) {
      debugPrint('Reklam sıklık sınırında. Kullanıcıyı darlamıyoruz.');
      return;
    }

    if (_interstitialAd != null) {
      _interstitialAd!.show();
      markInterstitialShown(now);
    } else {
      loadInterstitialAd(); // Yüklü değilse arkadan yükle
    }
  }
}
