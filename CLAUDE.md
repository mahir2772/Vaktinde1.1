# Vaktinde — Proje Haritası

Flutter ezan vakti uygulaması (Play Store: `com.mmdigital.vaktinde`). Bu dosya mimarinin tek kaynağıdır; projeyi baştan taramak yerine buraya bakın. Güncel durum ve yapılacaklar listesi: `docs/DURUM_ANALIZI.md`.

## Teknoloji
- Flutter (Dart SDK >=3.10), state: `provider` (ChangeNotifier), mimari: feature-based MVVM (gevşek).
- Dil: tr/en/de/fr/ar — `lib/l10n/*.arb` → `flutter gen-l10n` (`generate: true`), çıktı `lib/l10n/app_localizations*.dart` (elle düzenleme yok).
- Android-only fiilen (`AdHelper` iOS'ta `UnsupportedError` atar). iOS/macOS klasörleri şablon.
- Firebase (core + analytics + crashlytics), AdMob (`google_mobile_ads`), home_widget, flutter_background_service (sadece `specialUse` FGS), flutter_local_notifications, adhan_dart, workmanager (arka plan yenileme).
- Fontlar: Poppins `assets/google_fonts/` içinde gömülü (google_fonts önce asset'e bakar).

## Giriş akışı
`lib/main.dart` → Firebase init + Crashlytics hata yakalayıcıları → `MobileAds.initialize` + `AdHelper.loadInterstitialAd` → `BackgroundManager.initializeService` → Workmanager periyodik görev (6 sa, `keep`; `callbackDispatcher` → `PrayerRefreshService.runHeadless`) → `MultiProvider` (HomeViewModel, LanguageProvider, ThemeProvider, ZikirViewModel) → dil seçilmemişse `OnboardingLanguageView` → `IntroView`, yoksa `MainWrapper`.

`MainWrapper` (alt menü + banner reklam + showcase turu): HomeView, QiblaView, ZikirView, ToolsView, SettingsView.
`ToolsView` → Zakat, EsmaulHusna, FridayMessages, MissedPrayers, ReligiousDays, Dhikr list/stats.

## Klasörler
```
lib/
  data/
    models/   prayer_times_model (6 vakit, String "HH:mm", TARİHSİZ), hadith_model
    services/
      prayer_time_service   calculate(lat,lng,{date,offsets}): adhan_dart ile cihazda hesaplama (Diyanet/turkiye yöntemi, internetsiz).
                            forDate(date): kayıtlı koordinat + ince ayar (offsets) ile; vakit hesaplayan her yer bunu/offsets'i kullanır
                            getPrayerTimes(city): yedek Aladhan API (timingsByCity, 10 sn timeout)
      storage_service       SharedPreferences sarmalayıcı (konum adı + koordinat 'saved_lat/lng', günlük cache 'cached_prayer_times'+'cached_prayer_date', ayarlar, kaza, hadis)
      location_service      geolocator + geocoding → {city: administrativeArea, district: subAdministrativeArea|locality}; getCoordinatesFromAddress(il, ilçe)
      notification_service  flutter_local_notifications, tz; ezan/hatırlatma alarmları (alarmClock modu; namaz ID 0-59, günlük içerik 1000/1900, kalıcı 888)
      background_manager    flutter_background_service foreground servisi; sadece ilk bildirim metni ('bg_display'), asıl içerik NotificationUpdater'da
      prayer_refresh_service BuildContext'siz ortak mantık: widget/kalıcı bildirim verisi, 5 günlük alarm planı (buildAlarmPlan),
                            günlük ayet/hadis bildirimi, hicri tarih (de/fr → en). runHeadless(): WorkManager görevi — bugünün
                            vakitleri → cache + widget + bg_display; alarmlar günde bir ('alarms_scheduled_date'), toplu iptal yok
      widget_service        home_widget → Android widget'larına veri yazar
      hadith_service        hadeethenc.com API + yerel json fallback
      ayah_service          api.alquran.cloud
      economy_service       CollectAPI altın/döviz (zekat için) — anahtar `--dart-define=COLLECT_API_KEY`, yoksa canlı kur atlanır
      http_client           httpGet(): tüm dış isteklerde 10 sn timeout
      json_service          assets/data/*.json (esma, dini günler, cuma mesajları)
      dini_gunler_service   dini gün hesaplama (hijri paketi)
  features/<özellik>/{view,view_model,widgets}
    home/view_model/home_view_model.dart   ANA MANTIK: init (kayıtlı koordinattan hesapla → yoksa cache → yoksa geocode), gün değişince
                                           yeniden hesaplama (resume), konum, alarm planlama (koordinat varsa 5 gün),
                                           arka plan servisine/widget'a veri gönderme, günlük hadis/ayet
                                           (widget/alarm/günlük içerik → PrayerRefreshService'e delege; applyTimeOffsets())
    settings/view/time_adjust_view.dart    vakit ince ayarı (-30..+30 dk) → StorageService.saveTimeOffsets + applyTimeOffsets
    home/view/home_view.dart               vakit kartları, hata ekranları (errorMessageKey), sayaç
    home/widgets/countdown_widget.dart     "HH:mm" parse eder (split(':'))
    common/ad_helper.dart                  interstitial singleton (5 dk cooldown)
    common/widgets/ad_banner_widget.dart   banner
    common/{language,theme}_provider.dart
android/app/src/main/
  AndroidManifest.xml   AdMob APP ID, izinler, servis/receiver/widget tanımları
  kotlin/com/mmdigital/vaktinde/ — MainActivity, 3 widget provider, NotificationUpdater (kalıcı bildirim 888;
                                   HomeWidgetPreferences'tan çizer, her vakitte exact alarmla kendini yeniler)
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
- İmza: `android/key.properties` (+ .jks) git'te yok, yerelde olmalı. `flutter build appbundle --release --dart-define=COLLECT_API_KEY=<anahtar>` (README).
- Crashlytics gradle plugin: root `build.gradle.kts` classpath + app `plugins`.
- Test: `TZ=Europe/Istanbul flutter test test/prayer_time_service_test.dart` (Diyanet referansıyla ±1 dk). Tüm testler: `TZ=Europe/Istanbul flutter test`.
- Bulut ortamında Flutter SDK hazır gelmiyor (gerekirse scratchpad'e indirilir); Android SDK indirilemiyor (dl.google.com kapalı) → APK derlenemez. api.aladhan.com ve diyanet.gov.tr erişimi kapalı.
- `flutter pub get` farklı SDK ile SDK-pinli paketleri (characters, meta, intl…) değiştirir; lock'a sadece gerçek bağımlılık değişikliklerini al. `flutter analyze` analysis_options.yaml'a exclude ekler → geri al.

## Kurallar
- Kullanıcı min token istiyor: projeyi baştan tarama, bu dosyayı kullan; mimari değişince burayı güncelle.
- Commit mesajları Türkçe.
