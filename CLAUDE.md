# Vaktinde — Proje Haritası

Flutter ezan vakti uygulaması (Play Store: `com.mmdigital.vaktinde`). Bu dosya mimarinin tek kaynağıdır; projeyi baştan taramak yerine buraya bakın. Güncel durum ve yapılacaklar listesi: `docs/DURUM_ANALIZI.md`.

## Teknoloji
- Flutter (Dart SDK >=3.10), state: `provider` (ChangeNotifier), mimari: feature-based MVVM (gevşek).
- Dil: tr/en/de/fr/ar — `lib/l10n/*.arb` → `flutter gen-l10n` (`generate: true`), çıktı `lib/l10n/app_localizations*.dart` (elle düzenleme yok).
- Android-only fiilen (`AdHelper` iOS'ta `UnsupportedError` atar). iOS/macOS klasörleri şablon.
- Firebase (core + analytics + crashlytics), AdMob (`google_mobile_ads`), home_widget, flutter_background_service (sadece `specialUse` FGS), flutter_local_notifications, adhan_dart, workmanager (arka plan yenileme).
- Fontlar: pubspec `fonts:` ile gömülü — `Poppins` (400-900, `assets/google_fonts/`, italik yok) ve Arapça metin için `Amiri` (`assets/fonts/amiri/`); OFL lisansları main.dart'ta LicenseRegistry'ye kayıtlı. Tema `google_fonts` kullanmaz.

## Arayüz (lib/core/ui) — her ekran buradan beslenir
- Tek import: `package:ezan_saati/core/ui/ui.dart`.
- `app_tokens.dart`: `AppSpacing` (xs4 sm8 md12 lg16 xl24 xxl32), `AppRadius` (sm8 md12 lg16 xl24), `AppSizes` (dokunma 48, satır 56, buton 52), `AppColors` (palet; ekranlarda doğrudan değil tema üzerinden).
- `app_theme.dart`: `AppTheme.light()/dark({hasBackgroundImage})` — `ColorScheme.fromSeed(#00796B)` + copyWith (mor M3 yedeği yok), Poppins tip ölçeği (en küçük 13sp, yedek `sans-serif` = sistem fontu, Arapça arayüz metni buna düşer), tek AppBar stili (açıkta teal, koyuda #161D1C), opak kartlar (r16, açıkta 1px çerçeve), NavigationBar, Switch, FilledButton (52dp), input, yüzen SnackBar. TabBar teması AppBar.bottom içindir. Arka plan resmi seçiliyse Scaffold şeffaf, resim `MaterialApp.builder`'da.
- `prayer_colors.dart`: `PrayerColors.of(context)` tema uzantısı — hero yazı/karartma, sıradaki/şu anki/geçmiş vakit, Güneş, uyarı (kerahat), başarı.
- Bileşenler: `AppScaffold` (AppBar + altta banner), `AppCard`, `SectionHeader`, `AppListTile`/`AppListSection`, `PrayerTimeRow` (+`PrayerRowState`), `EmptyState`/`ErrorState`/`LoadingState`, `InfoBanner` (+`InfoTone`), `StatTile`, `ToolTile`, `CounterStepper`, `showConfirmDialog`, `TabularText` (Poppins'te tnum yok → sayaçlar bununla), `app_format.dart` (`formatPrayerTime`: en/ar 12 saat sıfırsız, diğerleri 24 saat; `formatClockTime`; `formatCountdown`).
- Kurallar: sabit renk/boyut yazma (token + `Theme.of(context)`), yazı ≥13sp, fotoğraf üstünde opak kart/karartma, RTL için `EdgeInsetsDirectional`, %130 yazıda taşma yok. Test: `test/core_ui_test.dart`.

## Giriş akışı
`lib/main.dart` → Firebase init + Crashlytics hata yakalayıcıları → `AdHelper.loadInterstitialAd` (rıza gelince yükler) → `BackgroundManager.initializeService` → Workmanager periyodik görev (6 sa, `keep`; `callbackDispatcher` → `PrayerRefreshService.runHeadless`) → `MultiProvider` (HomeViewModel, LanguageProvider, ThemeProvider, ZikirViewModel) → `runApp` → `AdConsent.gatherAndStartAds()` (beklemez) → dil seçilmemişse `OnboardingLanguageView` → `MainWrapper`, yoksa `ShowCaseWidget(MainWrapper)` (tur bitince bildirim + konum izni).
- Reklam rızası: `common/ad_consent.dart` — AdMob UMP (`requestConsentInfoUpdate` 10 sn zaman aşımı → `loadAndShowConsentFormIfRequired`), `canRequestAds()` true ise `MobileAds.initialize` (10 sn) ve `AdConsent.canRequestAds` (ValueNotifier) true; banner'lar/interstitial bunu bekler. Hata/ağ yokluğu açılışı bekletmez.
- Güncelleme: tek akış, Play esnek güncelleme (`_checkForUpdate`): iner, "Yeniden başlat" SnackBar'ı (`scaffoldMessengerKey`) ile kullanıcı onaylayınca `completeFlexibleUpdate`. UpgradeAlert yok.

`MainWrapper` (alt menü + ana banner + showcase turu; `app_showcase.dart`: tur anahtarları + `AppShowcase`): HomeView, QiblaView, ZikirView, ToolsView ("Araçlar"). Sekmeler IndexedStack'te ilk ziyarette kurulur (kıble pusulası/konum açılışta başlamaz). Sekme geçişinde reklam yok; interstitial sadece araç açılışlarında (5 dk soğuma). `HomeViewModel.initializeApp` sadece buradan, tek sefer (`_initRun`). SettingsView araçlar ekranındaki karttan açılır.
`ToolsView` → Imsakiye, Zakat, EsmaulHusna, FridayMessages, MissedPrayers, ReligiousDays, Dhikr list/stats.

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
      notification_service  flutter_local_notifications, tz; ezan/hatırlatma alarmları (alarmClock modu; namaz ID 0-59, vakit çıkış 100-124, günlük içerik 1000/1900, kalıcı 888).
                            Her initialize'a onDidReceiveBackgroundNotificationResponse: onNotificationActionBackground verilir ("Kıldım")
      prayer_tracker        saf: namaz takibi (tarih→5 vakit bit maskesi, seri, oran, kaza adayları), aksiyon yükü "prayed|yyyy-MM-dd|Öğle",
                            vakit çıkış ID'si (hatırlatma günü epochDay%5 → ID 100-124, günden bağımsız sabit)
      prayer_tracker_service kayıt + kaza ekleme (SerialQueue ile sıralı), "Kıldım" arka plan işleyicisi (ayrı isolate; prefs.reload şart),
                            kılınan vaktin hatırlatmasını iptal eder; kazaya eklenmiş vakit işaretlenmez. Ekranlar 30 sn'de bir kaydı yeniden okur
      background_manager    flutter_background_service foreground servisi; sadece ilk bildirim metni ('bg_display'), asıl içerik NotificationUpdater'da
      prayer_refresh_service BuildContext'siz ortak mantık: widget/kalıcı bildirim verisi, 5 günlük alarm planı (buildAlarmPlan),
                            günlük ayet/hadis bildirimi, hicri tarih (de/fr → en). runHeadless(): WorkManager görevi — bugünün
                            vakitleri → cache + widget + bg_display; alarmlar günde bir ('alarms_scheduled_date', en az biri kurulunca), toplu iptal yok.
                            buildEndReminderPlan/syncEndReminders: "vakit çıkmadan hatırlat" (ayar: end_reminder_*). Alarm işleri SerialQueue ile sıralı.
                            Ramazan günlerinde (gün gün, loadRamadanCalendar; olmazsa hijriOnly) imsak/akşam ezanı sahur/iftar metniyle
      widget_service        home_widget → Android widget'larına veri yazar
      hadith_service        hadeethenc.com API + yerel json fallback
      ayah_service          api.alquran.cloud
      economy_service       CollectAPI altın/döviz (zekat için) — anahtar `--dart-define=COLLECT_API_KEY`, yoksa canlı kur atlanır
      http_client           httpGet(): tüm dış isteklerde 10 sn timeout
      json_service          assets/data/*.json (esma, dini günler, cuma mesajları)
      dini_gunler_service   dini gün hesaplama (hijri paketi)
  features/<özellik>/{view,view_model,widgets}
    home/view_model/home_view_model.dart   ANA MANTIK: init (kayıtlı koordinattan hesapla → yoksa cache → yoksa geocode), gün değişince
                                           yeniden hesaplama (resume + gece yarısı zamanlayıcısı; ayet/hadis de yenilenir), konum,
                                           alarm planlama (koordinat varsa 5 gün; üst üste gelen istekler tek koşuda birleşir;
                                           toplu iptal yok, sadece plandan çıkan bekleyenler iptal → çekmecedeki bildirimler kalır),
                                           arka plan servisine/widget'a veri gönderme, günlük hadis/ayet
                                           (widget/alarm/günlük içerik → PrayerRefreshService'e delege; applyTimeOffsets())
                                           initializeApp tek sefer; pil optimizasyonu izni en fazla bir kez ('battery_optimization_asked',
                                           tanıtım turundan sonraki açılışta)
    settings/view/time_adjust_view.dart    vakit ince ayarı (-30..+30 dk) → StorageService.saveTimeOffsets + applyTimeOffsets
    home/view/home_view.dart               hero (sıradaki vakte göre gradyan + karartma; dokunulabilir konum → LocationSearchDialog,
                                           miladi · hicri tarih, sayaç, kerahat/Ramazan kapsülleri) + tek parça zemin (DecoratedSliver)
                                           üstünde ızgara, Bugün, günün ayet/hadisi; "Alarmlar" sekmesi; yükleniyor/hata/veri yok
                                           durumları (çevirili ErrorState + "Konum Değiştir")
    home/prayer_schedule.dart              saf: upcomingPrayer (yatsıdan sonra yarının imsakı), prayerRowStates (sıradaki/şu an/
                                           geçmiş; güneşten öğleye "şu an" yok), localizedPrayerName — test/prayer_schedule_test.dart
    home/widgets/countdown_widget.dart     sıradaki vakit adı + saati + 44sp TabularText sayaç (saniyelik)
    home/widgets/prayer_times_grid.dart    2×3 ızgara (Güneş ikonla ayrık, 5 sn'de bir durum kontrolü)
    home/widgets/daily_content.dart        ayet/hadis tek kart + okuma alt sayfası (Amiri, kopyala/paylaş; kendiliğinden kapanmaz)
    home/widgets/alarm_settings_list.dart  vakit başına açılır alarm kartı (ezan/sessiz/ses seçimi/önceden uyar)
    home/widgets/hero_chip.dart            hero bilgi kapsülü
    home/widgets/ramadan_card.dart         sadece Ramazan'da sahur/iftar sayacı (hero kapsülü)
    home/kerahat_logic.dart + widgets/kerahat_card.dart   kerahat (45 dk) sürüyorsa/60 dk içindeyse; onHero: kapsül, değilse InfoBanner
    home/widgets/prayer_tracker_row.dart   "Bugün" 5 vakit işareti (resume'da yenilenir) → prayer_tracker/view/prayer_tracker_view.dart
                                           (7 gün ızgara, 30 gün oran, seri, kılınmayanları kazaya ekle; araçlarda da kart)
    settings/view/end_reminder_setting.dart vakit çıkış hatırlatması anahtarı + 15/30/45 dk
    imsakiye/imsakiye_logic.dart           saf hesaplar: RamadanCalendar (Diyanet tarihleri religious_days.json'dan, yoksa hijri paketi),
                                           Türkçe tarih ayrıştırma, ay günleri, Ramazan sayacı; ramadan_calendar_loader.dart tek sefer yükler
    imsakiye/view/imsakiye_view.dart       aylık/Ramazan imsakiyesi (forDate ile); paylaşım = ekran dışı RepaintBoundary → PNG
    common/ad_helper.dart                  interstitial singleton (5 dk cooldown; rıza yoksa AdConsent.whenAdsStarted ile bekler)
    common/ad_consent.dart                 AdMob UMP rızası + MobileAds.initialize; kendi reklamını yükleyen ekran
                                           önce AdConsent.canRequestAds.value'ya bakmalı
    common/widgets/ad_banner_widget.dart   banner (adUnitId; varsayılan innerBanner), rıza gelince yüklenir
    main_wrapper/app_showcase.dart         tanıtım turu anahtarları + AppShowcase (marka renkli balon)
    common/{language,theme}_provider.dart
android/app/src/main/
  AndroidManifest.xml   AdMob APP ID, izinler, servis/receiver/widget tanımları
  kotlin/com/mmdigital/vaktinde/ — MainActivity, 3 widget provider, NotificationUpdater (kalıcı bildirim 888;
                                   HomeWidgetPreferences'tan çizer, her vakitte exact alarmla kendini yeniler)
  res/layout/vaktinde_widget_*.xml, custom_notification.xml
assets/data/  esma/cuma mesajları (dil başına json), religious_days.json
assets/google_fonts/ (Poppins), assets/fonts/amiri/ (Amiri + OFL)
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
- Ekran görüntüleri: `SCREENSHOT_DIR=<klasör> TZ=Europe/Istanbul flutter test test/screenshots/` → tüm ana ekranlar PNG (tr açık/koyu/arka plan/%130 yazı, de, ar) + `_errors.txt`. Env yoksa atlanır.
- Bulut ortamında Flutter SDK hazır gelmiyor (gerekirse scratchpad'e indirilir); Android SDK indirilemiyor (dl.google.com kapalı) → APK derlenemez. api.aladhan.com ve diyanet.gov.tr erişimi kapalı.
- `flutter pub get` farklı SDK ile SDK-pinli paketleri (characters, meta, intl…) değiştirir; lock'a sadece gerçek bağımlılık değişikliklerini al. `flutter analyze` analysis_options.yaml'a exclude ekler → geri al.

## Kurallar
- Kullanıcı min token istiyor: projeyi baştan tarama, bu dosyayı kullan; mimari değişince burayı güncelle.
- Commit mesajları Türkçe.
