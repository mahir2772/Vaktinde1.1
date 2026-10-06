# Vaktinde — Proje Haritası

Flutter ezan vakti uygulaması (Play Store: `com.mmdigital.vaktinde`). Bu dosya mimarinin tek kaynağıdır; projeyi baştan taramak yerine buraya bakın. Güncel durum ve yapılacaklar listesi: `docs/DURUM_ANALIZI.md`.

## Teknoloji
- Flutter (Dart SDK >=3.10), state: `provider` (ChangeNotifier), mimari: feature-based MVVM (gevşek).
- Dil: tr/en/de/fr/ar — `lib/l10n/*.arb` → `flutter gen-l10n` (`generate: true`), çıktı `lib/l10n/app_localizations*.dart` (elle düzenleme yok).
- Android-only fiilen (`AdHelper` iOS'ta `UnsupportedError` atar). iOS/macOS klasörleri şablon.
- Firebase (core + analytics), AdMob (`google_mobile_ads`), home_widget, flutter_background_service, workmanager, flutter_local_notifications.

## Giriş akışı
`lib/main.dart` → Firebase init → `MobileAds.initialize` + `AdHelper.loadInterstitialAd` → `BackgroundManager.initializeService` → `MultiProvider` (HomeViewModel, LanguageProvider, ThemeProvider, ZikirViewModel) → dil seçilmemişse `OnboardingLanguageView` → `IntroView`, yoksa `MainWrapper`.

`MainWrapper` (alt menü + banner reklam + showcase turu): HomeView, QiblaView, ZikirView, ToolsView, SettingsView.
`ToolsView` → Zakat, EsmaulHusna, FridayMessages, MissedPrayers, ReligiousDays, Dhikr list/stats.

## Klasörler
```
lib/
  data/
    models/   prayer_times_model (6 vakit, String "HH:mm", TARİHSİZ), hadith_model
    services/
      prayer_time_service   calculate(lat,lng): adhan_dart ile cihazda hesaplama (Diyanet/turkiye yöntemi, internetsiz).
                            getPrayerTimes(city): yedek Aladhan API (timingsByCity, 10 sn timeout)
      storage_service       SharedPreferences sarmalayıcı (konum adı + koordinat 'saved_lat/lng', günlük cache 'cached_prayer_times'+'cached_prayer_date', ayarlar, kaza, hadis)
      location_service      geolocator + geocoding → {city: administrativeArea, district: subAdministrativeArea|locality}; getCoordinatesFromAddress(il, ilçe)
      notification_service  flutter_local_notifications, tz; ezan/hatırlatma alarmları
      background_manager    flutter_background_service foreground servisi; kalıcı bildirimde sıradaki vakit (prefs'ten okur)
      widget_service        home_widget → Android widget'larına veri yazar
      hadith_service        hadeethenc.com API + yerel json fallback
      ayah_service          api.alquran.cloud
      economy_service       CollectAPI altın/döviz (zekat için) — API key kaynak kodda
      json_service          assets/data/*.json (esma, dini günler, cuma mesajları)
      dini_gunler_service   dini gün hesaplama (hijri paketi)
  features/<özellik>/{view,view_model,widgets}
    home/view_model/home_view_model.dart   ANA MANTIK: init (kayıtlı koordinattan hesapla → yoksa cache → yoksa geocode), gün değişince
                                           yeniden hesaplama (resume), konum, alarm planlama,
                                           arka plan servisine/widget'a veri gönderme, günlük hadis/ayet
    home/view/home_view.dart               vakit kartları, hata ekranları (errorMessageKey), sayaç
    home/widgets/countdown_widget.dart     "HH:mm" parse eder (split(':'))
    common/ad_helper.dart                  interstitial singleton (5 dk cooldown)
    common/widgets/ad_banner_widget.dart   banner
    common/{language,theme}_provider.dart
android/app/src/main/
  AndroidManifest.xml   AdMob APP ID, izinler, servis/receiver/widget tanımları
  kotlin/com/example/mmdigital/... (package adı com.mmdigital.vaktinde) — 3 widget provider + NotificationUpdater
  res/layout/vaktinde_widget_*.xml, custom_notification.xml
assets/data/  esma/cuma mesajları (dil başına json), religious_days.json
```

## Reklam birimleri (AdMob, yayıncı ca-app-pub-4975388193054410)
| Yer | Dosya | Gerçek ID |
|---|---|---|
| App ID | AndroidManifest.xml | `~3263720480` |
| Interstitial (genel) | `AdIds.interstitial` | `/8232165658` |
| Interstitial (zekat) | `AdIds.zakatInterstitial` | `/2151461471` |
| Banner (iç ekranlar) | `AdIds.innerBanner` | `/6543014509` |
| Banner (alt menü) | `AdIds.mainBanner` | `/3285554173` |
Tüm ID'ler `common/ad_helper.dart` → `AdIds` içinde; `kReleaseMode` ile debug'da otomatik Google test ID'si, release'de gerçek ID. Yeni ID eklerken buraya ekle, sayfalara sabit yazma.

## Build / yayın
- `pubspec.yaml` version `x.y.z+build` → versionCode. Play'e her yüklemede build numarası artmalı.
- İmza: `android/key.properties` (+ .jks) git'te yok, yerelde olmalı. `flutter build appbundle --release`.
- Test: `TZ=Europe/Istanbul flutter test test/prayer_time_service_test.dart` (Diyanet referansıyla ±1 dk). `test/widget_test.dart` eski şablon, bozuk.
- Bulut ortamında Flutter SDK hazır gelmiyor (gerekirse scratchpad'e indirilir); api.aladhan.com ve diyanet.gov.tr erişimi kapalı.

## Kurallar
- Kullanıcı min token istiyor: projeyi baştan tarama, bu dosyayı kullan; mimari değişince burayı güncelle.
- Commit mesajları Türkçe.
