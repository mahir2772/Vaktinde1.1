import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ad_consent.dart';
import 'widgets/ad_info_sheet.dart';

/// Reklam birimleri: debug/profile'da Google test ID'leri, release'de gerçek ID'ler.
/// (Geliştirirken kendi reklamına tıklayıp AdMob'dan ban yememek için otomatik seçilir.)
class AdIds {
  static const String _testBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitial =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testAppOpen = 'ca-app-pub-3940256099942544/9257395921';

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
  // Uygulama açıkken reklamı (vaktinde_app_open)
  static String get appOpen =>
      kReleaseMode ? 'ca-app-pub-4975388193054410/6771542342' : _testAppOpen;
}

/// Geçiş ve uygulama açılış reklamlarının sıklığı. Geçiş reklamı sadece
/// kullanıcının açtığı bir ekrana geçişte istenir (kendiliğinden, açılışta ya
/// da çıkışta değil): Araçlar'daki araçlar (Dualar, Namaz Hocası, Ayarlar,
/// Yakındaki Camiler hariç), ana ekranda "Bugün için" Cuma mesajları / dini
/// günler ve Namaz Takibi. Kur'an, Kıble, Zikir, Dualar/Tesbihat, Namaz Hocası
/// ve Ayarlar hiç tam ekran reklam göstermez. Uygulama açılış reklamı yalnızca
/// en az 30 sn arka planda kaldıktan sonra dönüşte, günde en çok 2 kez ve
/// ibadet sekmeleri dışındayken gösterilir. Yeni kullanıcıya ilk kurulumdan
/// sonraki 24 saat tam ekran reklam yok.
class AdHelper {
  // Singleton yapısı: Uygulama boyunca sadece 1 tane AdHelper yaşar
  static final AdHelper instance = AdHelper._internal();
  AdHelper._internal();

  /// İki geçiş reklamı arasında en az bu kadar süre olur
  static const Duration cooldown = Duration(minutes: 4);

  /// Günde en çok bu kadar geçiş reklamı
  static const int dailyCap = 8;

  /// Uygulama açılış reklamı (dönüşte): günde en çok 2 kez, en az 4 saat arayla
  static const int appOpenDailyCap = 2;
  static const Duration appOpenCooldown = Duration(hours: 4);

  /// AdMob kuralı: 4 saatten eski yüklenen açılış reklamı gösterilmez
  static const Duration appOpenMaxAge = Duration(hours: 4);

  /// Kısa süreli ekran değiştirme/izin dönüşünde açılış reklamı çıkmaz
  static const Duration appOpenMinBackground = Duration(seconds: 30);

  /// Yeni kullanıcıya bu cihazdaki ilk kurulumdan sonra bu süre tam ekran
  /// reklam yok (banner'lar değişmez)
  static const Duration newUserGrace = Duration(hours: 24);

  /// Son gösterim + günün sayısı (süreç kapansa da sıklık korunur):
  /// "<epoch ms>|<yyyy-MM-dd>|<sayı>"
  static const String logKey = 'interstitial_log';
  static const String appOpenLogKey = 'app_open_log';

  /// Bu cihazdaki ilk kurulum zamanı (InstallGuard açılışta PackageInfo'dan
  /// okur; main.dart verir). Bilinmiyorsa yeni kullanıcı kısıtı uygulanmaz.
  DateTime? installTime;

  /// "Reklamlar hakkında" açıklaması gösterildi (cihaza özgü ya da kullanıcı
  /// tercihi değil: InstallGuard'a ve yedeğe girmez)
  static const String infoSeenKey = 'ad_info_seen';
  bool _infoSeen = false;

  /// Açılış penceresi (tanıtım turu, izin akışı, rıza formu) açık mı;
  /// MainWrapper verir. Açıkken ilk fırsatta ne açıklama ne reklam.
  bool Function() startupWindowOpen = () => false;

  /// Uygulama açılış reklamı bu ekranda yasak mı (Kur'an, Kıble, Zikir vb.);
  /// MainWrapper günceller.
  bool Function() appOpenSuppressed = () => false;

  InterstitialAd? _interstitialAd;
  bool _loading = false;
  DateTime? _lastAdShowTime;
  String? _countDay;
  int _countToday = 0;
  bool _restored = false;

  AppOpenAd? _appOpenAd;
  DateTime? _appOpenLoadedAt;
  bool _appOpenLoading = false;
  bool _appOpenShowing = false;
  DateTime? _lastAppOpenShowTime;
  String? _appOpenDay;
  int _appOpenCountToday = 0;
  bool _waitingAppOpenConsent = false;

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

  /// Uygulama açılış reklamını arka planda önceden yükler (rıza gelince)
  void loadAppOpenAd() {
    if (!_isSupported) return;
    restoreLog();
    if (!AdConsent.canRequestAds.value) {
      if (!_waitingAppOpenConsent) {
        _waitingAppOpenConsent = true;
        AdConsent.whenAdsStarted(() {
          _waitingAppOpenConsent = false;
          loadAppOpenAd();
        });
      }
      return;
    }
    if (_appOpenLoading) return;
    if (_appOpenAd != null && !_isAppOpenExpired()) return;
    _appOpenAd?.dispose();
    _appOpenAd = null;
    _appOpenLoadedAt = null;
    _appOpenLoading = true;
    AppOpenAd.load(
      adUnitId: AdIds.appOpen,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenLoading = false;
          _appOpenAd = ad;
          _appOpenLoadedAt = DateTime.now();
          debugPrint('Uygulama açılış reklamı hazır.');
        },
        onAdFailedToLoad: (err) {
          _appOpenLoading = false;
          debugPrint('Uygulama açılış reklamı yüklenemedi: $err');
          _appOpenAd = null;
          _appOpenLoadedAt = null;
        },
      ),
    );
  }

  bool _isAppOpenExpired([DateTime? now]) {
    final loadedAt = _appOpenLoadedAt;
    if (loadedAt == null) return true;
    final t = now ?? DateTime.now();
    return t.isAfter(loadedAt) && t.difference(loadedAt) >= appOpenMaxAge;
  }

  static String _day(DateTime t) =>
      '${t.year}-${t.month.toString().padLeft(2, '0')}-'
      '${t.day.toString().padLeft(2, '0')}';

  bool _inNewUserGrace(DateTime t) {
    final installed = installTime;
    return installed != null &&
        !t.isBefore(installed) &&
        t.difference(installed) < newUserGrace;
  }

  /// Şu an geçiş reklamı gösterilebilir mi: kurulumdan [newUserGrace] geçti,
  /// son reklamdan [cooldown] geçti ve bugün [dailyCap]'e ulaşılmadı.
  /// Uygulamadaki tüm geçiş reklamları (genel + zekat) bu ortak sınıra uyar.
  /// Saat geri alındıysa (kurulumdan / son reklamdan önceye) beklenmez.
  bool canShowInterstitial([DateTime? now]) {
    final t = now ?? DateTime.now();
    if (_inNewUserGrace(t)) return false;
    final last = _lastAdShowTime;
    if (last != null && !t.isBefore(last) && t.difference(last) < cooldown) {
      return false;
    }
    return !(_countDay == _day(t) && _countToday >= dailyCap);
  }

  /// Uygulama açılış reklamı gösterilebilir mi: ilk 24 saat geçti, bugün en
  /// fazla [appOpenDailyCap], son açılış reklamından [appOpenCooldown] geçti,
  /// son geçiş reklamından [cooldown] geçti ve açılış/ibadet kısıtı yok.
  bool canShowAppOpen([DateTime? now]) {
    final t = now ?? DateTime.now();
    if (_appOpenShowing || startupWindowOpen() || appOpenSuppressed()) {
      return false;
    }
    if (_inNewUserGrace(t)) return false;
    final lastInterstitial = _lastAdShowTime;
    if (lastInterstitial != null &&
        !t.isBefore(lastInterstitial) &&
        t.difference(lastInterstitial) < cooldown) {
      return false;
    }
    final lastOpen = _lastAppOpenShowTime;
    if (lastOpen != null &&
        !t.isBefore(lastOpen) &&
        t.difference(lastOpen) < appOpenCooldown) {
      return false;
    }
    return !(_appOpenDay == _day(t) && _appOpenCountToday >= appOpenDailyCap);
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

  /// Bir uygulama açılış reklamı gösterildi
  void markAppOpenShown([DateTime? at]) {
    final t = at ?? DateTime.now();
    final day = _day(t);
    _lastAppOpenShowTime = t;
    _appOpenCountToday = day == _appOpenDay ? _appOpenCountToday + 1 : 1;
    _appOpenDay = day;
    _saveAppOpen();
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

  Future<void> _saveAppOpen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        appOpenLogKey,
        '${_lastAppOpenShowTime!.millisecondsSinceEpoch}|$_appOpenDay|$_appOpenCountToday',
      );
    } catch (e) {
      debugPrint('Açılış reklamı kaydı yazılamadı: $e');
    }
  }

  /// Önceki süreçteki son gösterim, günün sayısı (bellekteki daha yeniyse o)
  /// ve açıklamanın görülüp görülmediği; ilk yüklemede bir kez
  Future<void> restoreLog() async {
    if (_restored) return;
    _restored = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(infoSeenKey) ?? false) _infoSeen = true;
      final parts = prefs.getString(logKey)?.split('|');
      if (parts != null && parts.length == 3) {
        final ms = int.tryParse(parts[0]);
        final count = int.tryParse(parts[2]);
        if (ms != null && count != null) {
          final last = DateTime.fromMillisecondsSinceEpoch(ms);
          if (_lastAdShowTime == null || last.isAfter(_lastAdShowTime!)) {
            _lastAdShowTime = last;
          }
          if (_countDay == null || _countDay == parts[1]) {
            _countDay = parts[1];
            if (count > _countToday) _countToday = count;
          }
        }
      }
      final openParts = prefs.getString(appOpenLogKey)?.split('|');
      if (openParts != null && openParts.length == 3) {
        final ms = int.tryParse(openParts[0]);
        final count = int.tryParse(openParts[2]);
        if (ms != null && count != null) {
          final last = DateTime.fromMillisecondsSinceEpoch(ms);
          if (_lastAppOpenShowTime == null ||
              last.isAfter(_lastAppOpenShowTime!)) {
            _lastAppOpenShowTime = last;
          }
          if (_appOpenDay == null || _appOpenDay == openParts[1]) {
            _appOpenDay = openParts[1];
            if (count > _appOpenCountToday) _appOpenCountToday = count;
          }
        }
      }
    } catch (e) {
      debugPrint('Reklam kaydı okunamadı: $e');
    }
  }

  /// Hazır bir reklamın ilk gösterilebileceği fırsat (genel ya da zekat; sıklık
  /// sınırı çağıranda denetlenir): reklam yerine bir kez açıklama. Fırsat
  /// reklam molası sayılır (soğuma başlar), böylece açıklama hiçbir reklamla
  /// aynı dokunuşa bağlanmaz. Açılış penceresi açıksa hiçbir şey gösterilmez,
  /// sonraki fırsata kalır. Açıklama çağrı yerinin açtığı ekranın üstünde, bir
  /// sonraki karede açılır. true: fırsat açıklamanın, reklam gösterilmez.
  bool showInfoInstead(BuildContext context, [DateTime? now]) {
    if (_infoSeen) return false;
    if (startupWindowOpen()) return true;
    markInterstitialShown(now);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) showAdInfo(context);
    });
    return true;
  }

  /// Açıklamayı gösterir (Ayarlar > Destek de; reklamsız); bir daha
  /// kendiliğinden çıkmaz
  Future<void> showAdInfo(BuildContext context) async {
    _infoSeen = true;
    final sheet = showAdInfoSheet(context);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(infoSeenKey, true);
    } catch (e) {
      debugPrint('Reklam açıklaması kaydedilemedi: $e');
    }
    return sheet;
  }

  /// Testler: sıklık durumu sıfırlanır
  @visibleForTesting
  void debugReset() {
    installTime = null;
    _lastAdShowTime = null;
    _countDay = null;
    _countToday = 0;
    _restored = false;
    _infoSeen = false;
    _interstitialAd = null;
    _appOpenAd = null;
    _appOpenLoadedAt = null;
    _appOpenLoading = false;
    _appOpenShowing = false;
    _lastAppOpenShowTime = null;
    _appOpenDay = null;
    _appOpenCountToday = 0;
    startupWindowOpen = () => false;
    appOpenSuppressed = () => false;
  }

  /// Testler: yüklenmiş sayılan geçiş reklamı (platform kanalı yok)
  @visibleForTesting
  set debugLoadedAd(InterstitialAd? ad) => _interstitialAd = ad;

  /// Gösterme istekleri (test için; soğuma ve hazır olmama dahil)
  @visibleForTesting
  int debugShowRequests = 0;

  /// Kullanıcının açtığı ekrana geçişte çağrılır; sıklık sınırındaysa ya da
  /// reklam hazır değilse hiçbir şey göstermez (hazır değilse yükler). İlk
  /// fırsatta reklam yerine açıklama ([showInfoInstead]).
  void showInterstitialAd(BuildContext context) {
    debugShowRequests++;
    final now = DateTime.now();

    if (!canShowInterstitial(now)) {
      debugPrint('Reklam sıklık sınırında. Kullanıcıyı darlamıyoruz.');
      return;
    }

    if (_interstitialAd != null) {
      if (showInfoInstead(context, now)) return;
      _interstitialAd!.show();
      markInterstitialShown(now);
    } else {
      loadInterstitialAd(); // Yüklü değilse arkadan yükle
    }
  }

  /// Uygulamaya arka plandan dönüşte çağrılır ([MainWrapper] lifecycle).
  /// İlk 24 saatte, "Reklamlar hakkında" henüz görülmediyse, açılış/ibadet
  /// kısıtındaysa ya da sıklık sınırındaysa göstermez; hazır değilse/bayatsa
  /// yenisini yükler.
  void showAppOpenAdIfAvailable({DateTime? now}) {
    if (!_isSupported || !AdConsent.canRequestAds.value) return;
    final t = now ?? DateTime.now();
    // "Reklamlar hakkında" görülmeden uygulama dönüşünde ani reklam gösterilmez
    if (!_infoSeen || !canShowAppOpen(t)) return;

    final ad = _appOpenAd;
    if (ad == null || _isAppOpenExpired(t)) {
      loadAppOpenAd();
      return;
    }

    _appOpenShowing = true;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (shown) {
        _appOpenShowing = false;
        shown.dispose();
        _appOpenAd = null;
        _appOpenLoadedAt = null;
        loadAppOpenAd();
      },
      onAdFailedToShowFullScreenContent: (shown, error) {
        _appOpenShowing = false;
        shown.dispose();
        _appOpenAd = null;
        _appOpenLoadedAt = null;
        loadAppOpenAd();
      },
    );
    markAppOpenShown(t);
    ad.show();
  }
}
