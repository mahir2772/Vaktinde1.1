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
- Bileşenler: `AppScaffold` (AppBar + altta banner), `AppCard`, `SectionHeader` (arka plan resminde koyu kapsül + beyaz yazı; `onImage` ile zorlanabilir), `AppListTile`/`AppListSection`, `PrayerTimeRow` (+`PrayerRowState`), `EmptyState`/`ErrorState`/`LoadingState`, `InfoBanner` (+`InfoTone`), `StatTile`, `ToolTile`, `CounterStepper`, `showConfirmDialog`, `TabularText` (Poppins'te tnum yok → sayaçlar bununla), `app_format.dart` (`formatPrayerTime`: en/ar 12 saat sıfırsız, diğerleri 24 saat; `formatClockTime`; `formatCountdown`).
- Kurallar: sabit renk/boyut yazma (token + `Theme.of(context)`), yazı ≥13sp, fotoğraf üstünde opak kart/karartma, RTL için `EdgeInsetsDirectional`, %130 yazıda taşma yok. Uçtan uca: alt sayfa içeriği alt boşluğa `MediaQuery.paddingOf(context).bottom` ekler (`useSafeArea` sadece üstü korur); sistem çubuğu stili `AppTheme.lightBars` (renksiz; `SystemUiOverlayStyle.light/.dark` gezinme çubuğunu siyaha boyar). Test: `test/core_ui_test.dart`.

## Giriş akışı
`lib/main.dart` → Firebase init + Crashlytics hata yakalayıcıları → `InstallGuard.run` (3 sn) → `AdHelper.loadInterstitialAd` (rıza gelince yükler) → `BackgroundManager.initializeService` → Workmanager periyodik görev (6 sa, `keep`; `callbackDispatcher` → `PrayerRefreshService.runHeadless`) → `MultiProvider` (HomeViewModel, LanguageProvider, ThemeProvider, ZikirViewModel) → `runApp` → `AdConsent.gatherAndStartAds()` (beklemez) → dil seçilmemişse `OnboardingLanguageView` → `MainWrapper`, yoksa `ShowCaseWidget(MainWrapper)` (tur bitince bildirim + konum izni).
- Reklam rızası: `common/ad_consent.dart` — AdMob UMP (`requestConsentInfoUpdate` 10 sn zaman aşımı → `loadAndShowConsentFormIfRequired`), `canRequestAds()` true ise önce `updateRequestConfiguration(maxAdContentRating: PG)` (aile dostu; hata olursa yine başlar), sonra `MobileAds.initialize` (10 sn) ve `AdConsent.canRequestAds` (ValueNotifier) true; banner'lar/interstitial bunu bekler (`whenAdsStarted`; rıza geri çekilirse yeniden verilene kadar bekler). `getPrivacyOptionsRequirementStatus` → `AdConsent.privacyOptionsRequired`; gerekliyse Ayarlar > Destek'te "Reklam gizlilik ayarları" satırı (`AdConsent.showPrivacyOptions` → `ConsentForm.showPrivacyOptionsForm`). Hata/ağ yokluğu açılışı bekletmez, çökertmez.
- Güncelleme: tek akış, Play esnek güncelleme (`_checkForUpdate`): iner, "Yeniden başlat" SnackBar'ı (`scaffoldMessengerKey`) ile kullanıcı onaylayınca `completeFlexibleUpdate`. UpgradeAlert yok.
- Kurulum denetimi (`onboarding/install_guard.dart`): Android yedeği / cihazdan cihaza aktarım prefs'i yeni kuruluma taşır. 'install_marker' ≠ `PackageInfo.installTime` (firstInstallTime) → `InstallGuard.deviceKeys` silinir ('permissions_primed', 'battery_optimization_asked', 'alarms_scheduled_date', 'qibla_calibration_dialog_seen', 'exact_alarms_allowed', 'alarm_plan_meta', 'schedule_mode_v2', 'notifications_enabled', 'last_headless_run'; yeni cihaza özgü bayrak buraya ve test/install_guard_test.dart fikstürüne eklenir). İşaretsiz eski veri: kurulum bu cihazda güncellenmişse sessizce işaretlenir, hiç güncellenmemişse (yedek) silinir.
- Analytics: tek kapı `common/app_analytics.dart` (`AppAnalytics.logEvent`; sadece `allowedParameters`, konum/vakit gönderilmez). `FirebaseAnalytics` başka yerde kullanılmaz (testli).

`MainWrapper` (alt menü + ana banner + showcase turu; `app_showcase.dart`: tur anahtarları + `AppShowcase`): HomeView, QiblaView, ZikirView, ToolsView ("Araçlar"). Sekmeler IndexedStack'te ilk ziyarette kurulur (kıble pusulası/konum açılışta başlamaz). Sekme geçişinde reklam yok; interstitial sadece araç açılışlarında (5 dk soğuma; Ayarlar satırı reklamsız). `HomeViewModel.initializeApp` sadece buradan, tek sefer (`_initRun`). Alt menü etiketleri kısa (`navZikir`) ve tek satır (tema: `overflow: ellipsis`).
Açılış sırası (`_runStartupFlow`, yükleme bitince bir kez; pencereler üst üste binmez): tur hiç görülmediyse (`tourSeenKey` = 'is_first_launch_showcase_v3', tur BAŞLARKEN yazılır) → ekranda olan hedeflerle tur (`ShowcaseView.get().isTargetRendered`; eksik hedef 5.x'te turu bitirir), izinler turun `onFinish`'inde. Aksi halde → `primePermissionsIfNeeded` ('permissions_primed' yoksa: izinler zaten verilmişse sadece işaretlenir, değilse açıklama + bildirim + konum; tur yarıda kalsa bile Android 13+ bildirim izni sonraki açılışta istenir; elle seçilen şehir GPS ile ezilmez) → `requestBatteryOptimizationOnce`. Akış bitince (tur yolunda da) `StreakReviewPrompt.start()`: `PrayerTrackerService.changes` ile seri 7+'ya çıkınca bir kez `InAppReview.requestReview` ('review_requested'; isAvailable, ön plan, izin/rıza/tur penceresi yokken). SettingsView araçlar ekranındaki karttan açılır ("Bize Puan Ver" = openStoreListing).
`ToolsView` (gruplu liste: Namaz / Bilgi / Hesap + en altta Ayarlar; üst çubukta Ayarlar dişlisi, liste ekrana sığmıyor) → Imsakiye, PrayerTracker, MissedPrayers, Yakındaki Camiler (`tools/nearby_mosques.dart`: `geo:lat,lng?q=<nearbyMosquesQuery>`, olmazsa Google Haritalar web araması; uygulamadan çıkar, reklam yok), ReligiousDays, EsmaulHusna, FridayMessages, Zakat.

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
      notification_service  flutter_local_notifications, tz; ezan/hatırlatma alarmları (namaz ID 0-71 = vaktin tarihine bağlı
                            PrayerRefreshService.alarmId: epochDay%6 × 12 + vakit×2 (+1 hatırlatma), vakit çıkış 100-124, günlük içerik 1000/1900, test ezanı 1999, dini gün 2000-2399, kalıcı 888).
                            Her initialize'a onDidReceiveBackgroundNotificationResponse: onNotificationActionBackground verilir ("Kıldım")
                            Kip: scheduleModeFor(NotificationKind, exactAllowed:, notificationsEnabled:). alarmClock (durum çubuğunda alarm
                            simgesi + kilit ekranında "sonraki alarm") SADECE kullanıcının açtığı ezan (prayer) için, tam zamanlı izin ve bildirimler
                            açık/bilinmiyorken; hatırlatma (tek ID) ve vakit çıkış (100-124) exactAllowWhileIdle (simgesiz); günün ayeti/hadisi
                            (1000/1900) ve dini gün (religiousDay, 2000-2399) her zaman inexactAllowWhileIdle. İzin false → hepsi inexactAllowWhileIdle (çalar ama Android 12/12L'de
                            pencere 1 saate kadar + Doze'da 9 dk kota: ~1 saat gecikebilir, imsak/sahur dahil; uyarı alarmHealthExactOff); tam
                            zamanlı kip 'exact_alarms_not_permitted' ile reddedilirse aynı bildirim gecikmeli kurulur. Son durumlar
                            'exact_alarms_allowed', 'notifications_enabled' (refreshNotificationsEnabled, her kurulum turundan önce).
                            Gecikmeli kipte (buildAlarmPlan/buildEndReminderPlan exact:false) göreli metin yok: hatırlatma "X dk kaldı" yerine
                            vaktin saati, vakit çıkışı "çıkmasına X dk" yerine çıkış saati (nötr başlık), Ramazan imsakı "sahur HH:mm itibarıyla
                            sona erdi" — geç gelse de yanıltmaz (atlamak yerine; sahur hatırlatması kaybolmasın)
                            "Sessiz modda da çal" ('ezan_alarm_stream', varsayılan kapalı): sesli ezan 'alarm_channel_<ses>' kanalında
                            (AudioAttributesUsage.alarm; kanal sesi sonradan değişmediği için ayrı kanal); hatırlatma/yazılı bildirim değişmez.
                            Ses türü sadece kanalla verilir → Android 8+ (API 26); 7.x'te anahtar gizli (alarmStreamSupported: MainActivity
                            'vaktinde/device' kanalı 'sdkInt'; okunamazsa gösterilir)
      prayer_tracker        saf: namaz takibi (tarih→5 vakit bit maskesi, seri, oran, kaza adayları), aksiyon yükü "prayed|yyyy-MM-dd|Öğle",
                            vakit çıkış ID'si (hatırlatma günü epochDay%5 → ID 100-124, günden bağımsız sabit)
      prayer_tracker_service kayıt + kaza ekleme (SerialQueue ile sıralı), "Kıldım" arka plan işleyicisi (ayrı isolate; prefs.reload şart),
                            kılınan vaktin hatırlatmasını iptal eder; kazaya eklenmiş vakit işaretlenmez (takipte hücreye dokununca
                            removeFromKaza: kılındı + kaza sayacı −1, sayaç >0 ise onay; Kaza Takibi sayacı geçmiş işareti
                            değiştirmez, yoksa aynı vakit yeniden kazaya eklenirdi). Ekranlar 30 sn'de bir kaydı yeniden okur.
                            Özel gün (hayız/nifas): 'tracker_excused' (tarih kümesi; loadExcused/setExcused; saf isExcused/withExcused/
                            pruneExcused) → streak/completionRate/kazaCandidates `excused:` ile o günü atlar; işaretlenince o günün
                            kazaya eklenmiş namazları çıkarılır (sayaç −, onaylı). Gün adına/“Bugün” başlığına uzun basınca; oruç kazası
                            etkilenmez (kaza orucu gerekir)
      background_manager    flutter_background_service foreground servisi; sadece ilk bildirim metni ('bg_display'), asıl içerik NotificationUpdater'da
      prayer_refresh_service BuildContext'siz ortak mantık: widget/kalıcı bildirim verisi, 5 günlük alarm planı (buildAlarmPlan),
                            günlük ayet/hadis bildirimi, hicri tarih (de/fr → en). runHeadless(): WorkManager görevi — bugünün
                            vakitleri → cache + widget + bg_display; alarmlar günde bir ('alarms_scheduled_date', en az biri kurulunca), toplu iptal yok.
                            buildEndReminderPlan/syncEndReminders: "vakit çıkmadan hatırlat" (ayar: end_reminder_*). Alarm işleri SerialQueue ile sıralı.
                            Ramazan günlerinde (gün gün, loadRamadanCalendar; olmazsa hijriOnly) imsak/akşam ezanı sahur/iftar metniyle
                            Kurulum hatası yutulmaz: alarm başına yakalanır, diğerleri kurulur, tur sonunda tek Crashlytics kaydı; bekleyenler
                            okunamazsa da kurulur (gün kaydedilmez). Tam zamanlı ya da bildirim izni değişince ve kip geçişi
                            ('schedule_mode_v2': 1.1.0 her şeyi alarmClock kurdu) bitene kadar runHeadless aynı gün de yeniden kurar;
                            geçişte bekleyen 1000/1900 aynı metinle yeniden yazılır (pendingTexts). Günün ayeti/hadisi ayarı
                            'daily_content_enabled' (varsayılan açık; kapalıyken kurulmaz, bekleyen iptal; _dailyQueue ile sıralı).
                            Dini gün/kandil: buildReligiousDayPlan + syncReligiousDays (_religiousQueue, her rescheduleAlarms
                            turunda; sonucu 'alarms_scheduled_date' koşulunda). Kaynak DiniGunlerService.loadBildirimGunleri
                            (sadece json; 2028 sonrası json uzatılmalı). O gün 10:00, Ramazan başlangıcı bir gün önce, aynı
                            gün tek bildirim (Üç Aylar + Regaib ortak metin), bayramda arefe + 1. gün; 60 gün ileri; ID
                            religiousDayId = 2000 + epochDay%400; ayar 'religious_days_enabled' (varsayılan açık).
                            Test ezanı: scheduleTestEzan (ID 1999, ilk açık vaktin sesi/kanalı; temizlik dokunmaz).
                            nextScheduledEzan (bekleyen çift ID 0-71). 'last_headless_run': runHeadless başarı zamanı.
                            Geç ezan: vakti son 90 dk'da (lateWindow) girmiş, açık farz ezanı aynı "Kıldım" yüküyle hâlâ bekliyorsa
                            (gecikmeli kip, henüz çalmadı) ve kurulduğu saat + ayarlar bugünkü hesapla aynıysa yeniden kurulumda iptal
                            edilmez (recentlyDueEzans). Kayıt: 'alarm_plan_meta' (ID → alarmFingerprint: saat, başlık, ses, kanal, alarm
                            akışı, yük; gövde yok, kip sadece metni değiştirir) her kurulumda yazılır; ince ayar/konum/ses/dil değiştiyse
                            ya da kayıt yoksa (güncelleme, yedekten dönüş) eskisi iptal edilir. ID tarihe bağlı olduğundan üzerine başka
                            günün alarmı da yazılmaz. Güneş, hatırlatma ve vakit çıkış hatırlatması korunmaz
      widget_service        home_widget → Android widget'larına veri yazar (+ gün dönümü: times_date, tomorrow_*;
                            koordinat yoksa silinir; vakte kalan başlıkları title_imsak…title_yatsi = loc.toX, titleKeys).
                            updateHomeWidget yazımları SerialQueue ile sıralı. Ramazan widget'ı: ramadanData (saf) → 'ramadan_start/_end/
                            _next_start' (+ _text), başlıklar, 'ramadan_day_text' (%d) — 4. sağlayıcı VaktindeWidgetRamadanProvider
      hadith_service        hadeethenc.com API + yerel json fallback
      ayah_service          api.alquran.cloud
      economy_service       CollectAPI altın/döviz (zekat için) — anahtar `--dart-define=COLLECT_API_KEY`, yoksa canlı kur atlanır
      http_client           httpGet(): tüm dış isteklerde 10 sn timeout
      error_reporter        reportNonFatal(): Crashlytics ölümcül olmayan kayıt; Firebase yoksa (WorkManager isolate) başlatmayı dener, fırlatmaz.
                            installCrashlyticsHandlers(): Flutter/Dart hataları ÖLÜMCÜL OLMAYAN kayıt (uygulamayı kapatmayan hata çökme sayılmaz)
      json_service          assets/data/*.json (esma, dini günler, cuma mesajları)
      dini_gunler_service   dini günler: religious_days.json (Diyanet, 2025-2028) öncelikli, yoksa hijri hesap (turFromName, parseResmiGunler, yilinGunleri);
                            bildirim için parseBildirimGunleri/bildirimMetniOf (DiniGunTuru ucAylar/ramazanArefesi/kurbanArefesi sadece
                            bildirimde). json tutarlılık testi test/dini_gunler_test.dart (gün adı, Kadir = Ramazan+25, Arefe = bayram−1)
  features/<özellik>/{view,view_model,widgets}
    home/view_model/home_view_model.dart   ANA MANTIK: init (kayıtlı koordinattan hesapla → yoksa cache → yoksa geocode), gün değişince
                                           yeniden hesaplama (resume + gece yarısı zamanlayıcısı; ayet/hadis de yenilenir), konum,
                                           alarm planlama (koordinat varsa 5 gün; üst üste gelen istekler tek koşuda birleşir;
                                           toplu iptal yok, sadece plandan çıkan bekleyenler iptal → çekmecedeki bildirimler kalır),
                                           arka plan servisine/widget'a veri gönderme, günlük hadis/ayet
                                           (widget/alarm/günlük içerik → PrayerRefreshService'e delege; applyTimeOffsets())
                                           initializeApp tek sefer; pil optimizasyonu izni en fazla bir kez ('battery_optimization_asked';
                                           MainWrapper izin akışından sonra çağırır; manifest'te REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
                                           olmadığından şu an pencere açılmaz)
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
    home/alarm_health.dart                 AlarmHealth (HomeViewModel.alarmHealth): bildirim + tam zamanlı alarm izni; açılışta ve her
                                           resume'da okunur, izin değişince/bildirim açılınca alarmlar yeniden kurulur. Pencere açmaz;
                                           butonlar: requestExactAlarmsPermission / requestNotificationsPermission (pencere çıkmazsa ayarlar)
    home/widgets/alarm_health_banner.dart  ana ekran + Alarmlar sekmesi InfoBanner uyarısı (alarm açıksa; önce bildirim; "Ayrıntılar" →
                                           NotificationHealthView). HomeView.openAlarmsTab: Alarmlar sekmesine geçiş. Alarmlar
                                           sekmesinin başında "Sessiz modda da çal" (HomeViewModel.setEzanAlarmStream; 8.0 altında gizli:
                                           checkAlarmStreamSupport → alarmStreamSupported)
    home/widgets/hero_chip.dart            hero bilgi kapsülü
    home/widgets/ramadan_card.dart         sadece Ramazan'da sahur/iftar sayacı (hero kapsülü) + resimli paylaşım (ramadanShareContent)
    home/kerahat_logic.dart + widgets/kerahat_card.dart   kerahat (45 dk) sürüyorsa/60 dk içindeyse; onHero: kapsül, değilse InfoBanner
    home/widgets/prayer_tracker_row.dart   "Bugün" 5 vakit işareti (resume'da yenilenir) → prayer_tracker/view/prayer_tracker_view.dart
                                           (7 gün ızgara, 30 gün oran, seri, kılınmayanları kazaya ekle; araçlarda da kart)
    settings/view/end_reminder_setting.dart vakit çıkış hatırlatması anahtarı + 15/30/45 dk
    settings/view/settings_view.dart       Konum & Vakitler: EndReminderSetting altında "Günün ayeti ve hadisi" ve "Dini gün ve kandil"
                                           anahtarları (HomeViewModel.setDailyContentEnabled / setReligiousDaysEnabled), "Bildirim Kontrolü"
                                           satırı. Destek'te "Gizlilik Politikası" (core/app_links.dart AppLinks.privacyPolicy = Google Sites,
                                           harici tarayıcı; boşsa gizli). Metnin kaynağı docs/gizlilik_politikasi.md.
                                           Play linki tek yer: AppLinks.playStore / playStoreLink(kampanya) (utm_source=app_share)
    notification_health/notification_health.dart  saf: HealthStatus, DeviceStatus, vendorOf (üretici), guideSteps, volumeIssue,
                                           dndStatus, backgroundStatus (son WorkManager koşusu 48 sa'ten eskiyse uyarı)
    notification_health/view/notification_health_view.dart  Bildirim Kontrolü: durum kartı (açık ezan, sıradaki ezan, bildirim,
                                           alarm izni, ses, Rahatsız Etmeyin, pil, arka plan), üretici rehberi + dontkillmyapp, "1 dk sonra
                                           test ezanı"; resume'da yeniden okur
    settings/view/language_sheet.dart      dil seçimi (Ayarlar'da ilk satır); sürüm package_info_plus ile
    qibla/qibla_math.dart                  kıble açısı (adhan_dart, COĞRAFİ kuzey) + dönüş yönü; trueHeading (manyetik + sapma),
                                           Geomagnetic.tryParse, dairesel süzgeç (HeadingFilter, 0,25/olay), parazit (alan beklenenden
                                           >%25 sapma 1,5 sn → uyarı, <%15 1 sn → kapanır), calibrationPoor (manyetometre durumu biliniyorsa
                                           0/1 zayıf, yoksa eklentinin doğruluğu). flutter_compass MANYETİK kuzey verir: qibla_view pusula
                                           açılınca konum başına bir kez 'vaktinde/device' geomagnetic sorar (hata → sapma 0, parazit denetimi
                                           yok); 'vaktinde/magnetic' akışı pusulayla aynı yaşam döngüsünde (sekme görünür + ön plan); altta
                                           her zaman "yaklaşık yön" notu + "Doğru sonuç için" alt sayfası (ipuçları, kıble açısı, sapma)
    zikirmatik/view/dhikr_names.dart       zikir adları/Arapça metinleri (Amiri)
    onboarding/view/onboarding_language_view.dart  dil seçimi + requestPermissionsWithPriming (açıklama penceresi → bildirim → konum;
                                           oturumda bir kez, bitince 'permissions_primed') + primePermissionsIfNeeded;
                                           main.dart turu da aynı fonksiyonu navigatorKey bağlamıyla kullanır
    onboarding/install_guard.dart          yedekten / başka telefondan gelen prefs'te cihaza özgü bayrakları siler (main.dart)
    prayer_tracker/streak_review.dart      StreakReviewPrompt: 7 günlük tam seride tek değerlendirme isteği (MainWrapper) +
                                           UsageReviewPrompt: 5 farklı kullanım günü ('usage_days_count', 'usage_last_day'),
                                           açılışta/yeni güne dönüşte; ikisi 'review_requested' ve süreç kilidini paylaşır
    fitre/view/fitre_view.dart             Fitre & Fidye (Araçlar > Hesap): data/services/fitre_service.dart — assets/data/fitre.json
                                           + uzak https://mahir2772.github.io/fitre.json (docs/site/fitre.json yüklenir; prefs
                                           'fitre_remote_json'); validFrom ≤ bugün olan en yeni tutar. Yeni yıl: girdi EKLE, silme
    prayer_tracker/widgets/ramadan_fast_card.dart  Ramazan orucu kartı (Ramazan + bitişten 30 gün): data/services/
                                           fast_tracker(.dart|_service.dart), 'fast_log', 'fast_kaza_added' → kaza_Oruç (tekil, geri alınır)
    duas/                                  Dualar (Araçlar > Namaz): assets/data/duas.json (4 kategori, 21 dua: Arapça + tr okunuş + 5 dil
                                           anlam, kaynak) + dua_data.dart; tesbihat_view.dart: namaz sonrası adım adım sayaç
                                           (Âyetü'l-Kürsî, 33×3, tevhid). Arapça standart imla, harekeli; yeni dua eklerken harf harf kontrol
    common/share_card.dart                 ShareCard (1080×1350 PNG, teal, Amiri, "Google Play'de Vaktinde") + shareAsImage/
                                           shareAsText (metin sonuna AppLinks.playStoreLink(kampanya)) + MessageCard (Cuma, tebrik)
                                           + SheetMessenger (alt sayfada SnackBar). Kampanyalar: friday/daily/greeting/invite/dua/iftar/quran
    religious_days/view/religious_days_view.dart  "Tebrik gönder" alt sayfası (assets/data/greetings_<dil>.json,
                                           JsonService.getGreetings; gün yaklaşırken ve 3 gün sonrasına kadar; Regaib + Üç Aylar)
    settings/view/add_widget_sheet.dart    "Ana Ekrana Widget Ekle" (4 widget; HomeWidget.requestPinWidget, sağlayıcı adı manifestle aynı;
                                           satır sadece başlatıcı destekliyorsa)
    imsakiye/imsakiye_logic.dart           saf hesaplar: RamadanCalendar (Diyanet tarihleri religious_days.json'dan, yoksa hijri paketi),
                                           Türkçe tarih ayrıştırma, ay günleri, Ramazan sayacı; ramadan_calendar_loader.dart tek sefer yükler
    imsakiye/view/imsakiye_view.dart       aylık/Ramazan imsakiyesi (forDate ile); paylaşım = ekran dışı RepaintBoundary → PNG
    common/ad_helper.dart                  interstitial singleton (5 dk cooldown; rıza yoksa AdConsent.whenAdsStarted ile bekler)
    common/ad_consent.dart                 AdMob UMP rızası + MobileAds.initialize + gizlilik seçenekleri formu; kendi
                                           reklamını yükleyen ekran önce AdConsent.canRequestAds.value'ya bakmalı
    common/app_analytics.dart              Firebase Analytics tek kapısı (izinli parametre listesi)
    common/widgets/ad_banner_widget.dart   banner (adUnitId; varsayılan innerBanner), rıza gelince yüklenir
    main_wrapper/app_showcase.dart         tanıtım turu anahtarları + AppShowcase (marka renkli balon)
    common/{language,theme}_provider.dart  ThemeProvider: arka plan listesi tek yer (mosqueBackgrounds/kaabaBackgrounds); validBackground:
                                           eski .jpg → .webp, bilinmeyen (bg_quran) silinir; main.dart arka planı errorBuilder ile düşer
android/app/src/main/
  AndroidManifest.xml   application android:name=".VaktindeApplication"; AdMob APP ID, izinler, servis/receiver/widget tanımları
                        (showWhenLocked/turnScreenOn YOK: kilit ekranı üstünde açılmaz); widget'lar + NotificationUpdater
                        TIME_SET/TIMEZONE_CHANGED dinler
  kotlin/com/mmdigital/vaktinde/ — MainActivity: FlutterFragmentActivity; onCreate'te super'den SONRA enableEdgeToEdge()
                                   (API 30 altı gezinme çubuğu siyah: Flutter eski bayrakları her resume'da sıfırlar).
                                   DeviceChannels.kt: 'vaktinde/device' sdkInt + geomagnetic {lat,lng} → {declination doğu+,
                                   strength µT} + deviceInfo {manufacturer, brand, sdkInt, batteryOptimized, interruptionFilter,
                                   notificationVolume, alarmVolume, ringerMode} + openSettings {app|notifications|battery|dnd|sound}
                                   (bağlam DeviceMethods.appContext, VaktindeApplication'da); EventChannel 'vaktinde/magnetic'
                                   [µT, doğruluk 0..3/-1] ≤5/sn, no_sensor; onStop'ta durur), 3 widget provider, NotificationUpdater (kalıcı bildirim 888;
                                   HomeWidgetPreferences'tan çizer, her vakitte PrayerWidgetData.setRefreshAlarm ile kendini yeniler)
    PrayerWidgetData.kt   ortak vakit mantığı: 'times_date' (yazılan setin günü) + 'tomorrow_*' (yarının vakitleri,
                          'tomorrow_hijri_date_text'): yatsıdan sonra yarının imsakı, gün dönmüşse yarının seti;
                          yeni anahtar yoksa eski davranış. Sağlayıcı başına tek alarm (requestCode 0), onDisabled'da iptal.
                          setRefreshAlarm: tam zamanlı (setExactAndAllowWhileIdle); izin yoksa (Android 12/12L) uyandırmayan
                          setWindow(RTC, 10 dk): izinsiz setAlarmClock SecurityException atar, setAndAllowWhileIdle ise Doze'da
                          ezanla aynı "9 dk'da bir" kotasını paylaşıp ezanı geciktirir. NextPrayer(time, label, index);
                          title(): Dart'ın title_<vakit> anahtarı ("İkindiye"), yoksa title_text (±60 sn) / vakit adı; label(), epochDay()
    VaktindeWidgetRamadanProvider.kt  Ramazan widget'ı (2x2): Ramazan'da iftar/sahur Chronometer + "N. gün", dışında
                          "Ramazan'a N gün"; gün sayısını tarihten kendisi hesaplar; yenileme imsak/akşam/gece yarısı
    VaktindeApplication.kt + WidgetRefresher.kt  kendini onaran sayaç (alarm geç/hiç gelmeyen üreticiler): onCreate'te tek dinamik
                          alıcı (TIME_TICK, SCREEN_ON, USER_PRESENT; 33+ NOT_EXPORTED) + açılışta bir denetim. Her yüzey (4 widget
                          türü + 888, sağlayıcı başına beklenen durum) çizdiği hedef + günü 'vaktinde_widget_state'e yazar (markWidgetsDrawn/markNotificationDrawn);
                          hesaplanandan farklıysa sadece o yüzey süreç içinde yeniden çizilir (888 sadece açıksa). Hiçbir yol
                          fırlatmaz. Widget yenilemede setAlarmClock KULLANILMAZ (durum çubuğu alarm simgesi)
  res/layout/vaktinde_widget_*.xml, custom_notification.xml; res/xml/widget_info_* (30 dk, açıklama, previewLayout);
  res/values*/strings.xml (widget adları/açıklamaları, tr varsayılan + en/de/fr/ar)
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
app-ads.txt: `docs/site/` (app-ads.txt + index.html) GitHub Pages `mahir2772.github.io` kökünde; Play "Web sitesi" bu adres olmalı
(Google Sites alan adı app-ads.txt'de desteklenmez). Gizlilik politikası Google Sites'ta kalır.
Tüm ID'ler `common/ad_helper.dart` → `AdIds` içinde; `kReleaseMode` ile debug'da otomatik Google test ID'si, release'de gerçek ID. Yeni ID eklerken buraya ekle, sayfalara sabit yazma.

## Build / yayın
- `pubspec.yaml` version `x.y.z+build` → versionCode. Play'e her yüklemede build numarası artmalı.
- İmza: `android/key.properties` (+ .jks) git'te yok, yerelde olmalı. `flutter build appbundle --release --dart-define=COLLECT_API_KEY=<anahtar>` (README).
- Crashlytics gradle plugin: root `build.gradle.kts` classpath + app `plugins`.
- R8 (1.1.2+): release'de `isMinifyEnabled = true` (küçültme + optimizasyon + karartma; Play "DEX kodu optimizasyonu",
  son tarih Şub 2027), `proguard-android-optimize.txt` + `android/app/proguard-rules.pro`: `-keep class com.dexterous.** { *; }`
  (flutter_local_notifications kurulu bildirimleri Gson ile saklar; stil alt türü sınıfın kısa adıyla, enum alan adıyla
  kaydedilir → ad değişirse eski kayıt okunamaz, yeni bildirim kurulamaz) + Gson kuralları + Play Core/annotation dontwarn.
  `isShrinkResources = true` (1.2.0+): adla çağrılan kaynaklar res/raw/keep.xml tools:keep'te (@raw/ezan*, @raw/bildirim*,
  @mipmap/launcher_icon); adla çağrılan yeni ses/simge buraya eklenir, yoksa ezan sessiz kalır. androidx.activity.EdgeToEdge
  R8'de korunur (Play çağrıyı arar). Eşleme dosyası AAB'ye
  girer; Crashlytics eklentisi derlemede yükler (internet gerekir). Burada R8 çalıştırılamıyor → her R8 değişikliği dahili
  testte cihazda denenir. "Missing classes detected while running R8" çıkarsa
  build/app/outputs/mapping/release/missing_rules.txt satırları proguard-rules.pro'ya eklenir.
- Test: `TZ=Europe/Istanbul flutter test test/prayer_time_service_test.dart` (Diyanet referansıyla ±1 dk). Tüm testler: `TZ=Europe/Istanbul flutter test`.
- Ekran görüntüleri: `SCREENSHOT_DIR=<klasör> TZ=Europe/Istanbul flutter test test/screenshots/` → tüm ana ekranlar PNG (tr açık/koyu/arka plan/%130 yazı, de, ar) + `_errors.txt`. Env yoksa atlanır. "tr uçtan uca: sistem çubukları" çeşidi (üst 24 / alt 48 boşluk, `tr_edge_*`) çubuk altında kalan metin/düğmeyi `_errors.txt`'ye yazar.
- Bulut ortamında Flutter SDK hazır gelmiyor (gerekirse scratchpad'e indirilir); Android SDK indirilemiyor (dl.google.com kapalı) → APK derlenemez. api.aladhan.com ve diyanet.gov.tr erişimi kapalı.
- `flutter pub get` farklı SDK ile SDK-pinli paketleri (characters, meta, intl…) değiştirir; lock'a sadece gerçek bağımlılık değişikliklerini al. `flutter analyze` analysis_options.yaml'a exclude ekler → geri al.

## Kurallar
- Kullanıcı min token istiyor: projeyi baştan tarama, bu dosyayı kullan; mimari değişince burayı güncelle.
- Commit mesajları Türkçe.
