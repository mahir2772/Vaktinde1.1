# Vaktinde — Durum (v1.1.2+16; dahili testte 1.1.1+15, Play'de 1.1.0+14)

Mimari: `CLAUDE.md`. Bu ortamda Android SDK yok (dl.google.com kapalı) → APK derlenemiyor; `flutter analyze` + birim testi çalışıyor.

## Kapatılanlar ✅
| # | Konu | Çözüm |
|---|---|---|
| 1 | Ana ekranda "Hata" (Aladhan API her gün başarısız) | Vakitler `adhan_dart` ile cihazda (Diyanet ±1 dk, testli); Aladhan sadece yedek |
| 2 | Test reklam ID'leri | `AdIds` + `kReleaseMode` |
| 3 | Sürüm | 1.0.1+14 (Play'de 13) |
| 4 | CollectAPI anahtarı kodda | `--dart-define=COLLECT_API_KEY=...` (README). **Eski anahtar git geçmişinde → CollectAPI'den yenile** |
| 5 | Pusulasız cihazlar Play'de uygulamayı göremiyordu | `sensor.compass required=false` |
| 6 | Android 15 `dataSync` FGS 6 saat limiti (çökme riski) | Servis sadece `specialUse` |
| 7 | Exact alarm izinleri | `SCHEDULE_EXACT_ALARM maxSdk=32` + `USE_EXACT_ALARM`, tekrar kaldırıldı |
| 8 | Alarmlar tek günlük | Koordinat varsa 5 gün önceden (ID 0-71, vaktin tarihine bağlı) |
| 9 | HTTP timeout yok | `http_client.dart` → `httpGet` (10 sn) |
| 10 | Hatalar görünmüyordu | Firebase Crashlytics (release'de açık) |
| 11 | Temizlik | Bozuk widget_test silindi, `android/build` + translator cache git'ten çıktı, `fromList` ölü kod, kullanılmayan `workmanager` kaldırıldı, Kotlin klasörü `com/mmdigital/vaktinde`, README, pubspec açıklaması, iOS'ta AdHelper çökmez |
| 12 | İnternetsiz ilk açılışta font yok | Poppins `assets/google_fonts` içinde gömülü |

## v1.1.0 yeni özellikler ✅
| Özellik | Nerede |
|---|---|
| Vakit ince ayarı (±30 dk) | Ayarlar → `time_adjust_view.dart`; `forDate()` her yerde uygular |
| Namaz takibi ("Kıldım" bildirim butonu, Bugün satırı, 7 gün/30 gün/seri, kazaya ekle) | `prayer_tracker_*`, araçlar kartı |
| İmsakiye (aylık + Ramazan, PNG paylaşım) | `features/imsakiye/` (Ramazan tarihleri Diyanet `religious_days.json`, yoksa hijri) |
| Ramazan sayacı + iftar/sahur bildirim metinleri | `ramadan_card.dart`, `buildAlarmPlan` |
| Kerahat kartı + "vakit çıkıyor" hatırlatması (varsayılan kapalı, ID 100–124) | `kerahat_*`, `end_reminder_setting.dart` |
| Arka plan günlük yenileme (WorkManager 6 saat; widget, kalıcı bildirim, 5 günlük alarm) | `prayer_refresh_service.dart` |
| İnceleme düzeltmeleri: Avrupa yazında İmsak=Yatsı, de/fr ana ekran hatası, gece yarısı bayatlığı, alarm yarışları, tepsideki bildirimlerin silinmesi | — |

## v1.1.0 güvenilirlik paketleri ✅
| Paket | Ne değişti | Nerede |
|---|---|---|
| A — ezan güvenilirliği | Tam zamanlı alarm izni yoksa (Android 12/12L'de "Alarmlar ve hatırlatıcılar" kapalı) ezan gecikmeli kiple kurulur (eskiden hiç kurulmuyordu); kurulum hataları yutulmaz (Crashlytics); izin değişince aynı gün yeniden kurulur; ana ekran + Alarmlar sekmesinde uyarı şeridi (bildirimler kapalı → "Aç", alarm izni kapalı → "İzin ver"); "Sessiz modda da çal" (ezan alarm ses seviyesinde, Android 8+) | `notification_service.dart`, `prayer_refresh_service.dart`, `alarm_health*.dart` |
| B — widget'lar / güvenlik | Gün dönümü ve yatsı sonrası yarının imsakı, saat/dilim değişiminde hemen yeniden çizim, sağlayıcı başına tek alarm, seçicide ad/açıklama/önizleme, 30 dk yenileme; uygulama kilit ekranı üstünde açılmaz | `PrayerWidgetData.kt`, `res/xml/widget_info_*` |
| C — gizlilik / izin / reklam / değerlendirme | Yedekten ya da başka telefondan gelen veride cihaza özgü bayraklar silinir (izin akışı yeni telefonda yeniden çalışır); analitikte konum ve vakit yok (tek kapı); Ayarlar reklamsız açılır; reklam içerik sınırı PG; 7 günlük tam seride bir kez uygulama içi değerlendirme | `install_guard.dart`, `app_analytics.dart`, `ad_consent.dart`, `streak_review.dart` |
| İnceleme düzeltmeleri | İzin yokken widget/kalıcı bildirim yenilemesi uyandırmayan 10 dk pencereli alarmla (setAlarmClock hata veriyordu; Doze'da ezanın kotasını da yemez); gecikmiş (henüz çalmamış) ezan yeniden kurulumda iptal edilmez, üzerine yazılmaz (ID tarihe bağlı, son 90 dk; saati ve ayarları değiştiyse — ince ayar, konum, ses, dil — eskisi iptal); gecikmeli kipte hatırlatmalar "X dakika kaldı" yerine saatli; uyarı metni "yaklaşık 1 saate kadar, imsak/sahur dahil"; "Sessiz modda da çal" Android 7'de gizli | — |

## v1.1.1 düzeltmeleri ✅ (1.1.0 yayınından gelen bildirimler)
| Sorun | Çözüm |
|---|---|
| Ezanlar/bildirimler kapalıyken durum çubuğunda alarm simgesi | Günün ayeti/hadisi (10:00/19:00) herkese alarmClock ile kuruluyordu. alarmClock sadece açık ezanda; hatırlatmalar exactAllowWhileIdle, günlük içerik inexact; bildirimler kapalıyken alarmClock yok; 'schedule_mode_v2' ile mevcut kurulumlarda bir kez yeniden kurulum; Ayarlar'da "Günün ayeti ve hadisi" anahtarı |
| Widget ve kalıcı bildirim vakit girince eksiye sayıyor ("İkindiye −17:08", Honor) | Vakit alarmı bazı üreticilerde gelmiyor: VaktindeApplication + WidgetRefresher (ekran/kilit açılınca ve ekran açıkken dakikada bir denetim, bayat yüzey yeniden çizilir; alarm simgesi yok); başlık her zaman "Akşama" (title_* anahtarları) |
| Kıble bazen yanlış | flutter_compass manyetik kuzey veriyordu (Türkiye'de ~6° sabit hata): GeomagneticField ile sapma düzeltmesi, dairesel süzgeç, manyetik parazit uyarısı, manyetometre durumuyla kalibrasyon; "yaklaşık yön" notu + "Doğru sonuç için" ipuçları |
| Gizlilik politikası eksik/yanlış | Metin güncellendi (Firebase, konum akışı, AdMob, KVKK) → docs/gizlilik_politikasi.md, Google Sites'ta yayında; Ayarlar > Destek'te bağlantı |

## Ertelenenler
- CollectAPI anahtarı: koda yazılamıyor; derlemede `--dart-define=COLLECT_API_KEY=...` verilmezse zekat ekranında canlı kur gelmez. Anahtar yenilenmeli (git geçmişinde açık).
- Play Console: Veri güvenliği formuna Crashlytics (kilitlenme günlükleri, tanılama) eklenmeli.

## v1.1.0 arayüz yenilemesi ✅ (evrimsel, aynı düzen)
| Alan | Ne değişti |
|---|---|
| Ortak tasarım | `lib/core/ui/` (tema açık/koyu, `PrayerColors`, AppScaffold/AppCard/AppListSection/CounterStepper… ), mor M3 renkleri gitti, en küçük yazı 13sp, Poppins + Amiri gömülü |
| Ana ekran | Sıradaki vakit + sayaç odakta, dokunulabilir şehir, miladi · hicri tarih, kerahat/Ramazan kapsülleri, Bugün satırı ekrana sığar, ayet/hadis okunabilir sayfa (3 sn'de kapanmıyor) |
| Alt menü / açılış | "Araçlar", sekme geçişinde reklam yok, sekmeler ilk ziyarette kurulur, initializeApp tek sefer, tek güncelleme akışı, AdMob UMP rızası + Ayarlar'da gizlilik seçeneği, izin açıklama penceresi (tur yarıda kalsa da sonraki açılışta sorulur), pil izni en fazla bir kez |
| Araçlar | Ayarlar ile aynı dikey liste (Namaz/Bilgi/Hesap), tek ekrana sığar |
| Zekat | Sonuç reklamı beklemez; varsayılan seçim çökmesi (en/de/fr/ar) düzeldi; "10.000" / "2500,50" doğru okunur; altın fiyatı yoksa "zekat gerekir" denmez; gümüş/manuel kur yazılabilir; reklamlar ortak 5 dk soğuma |
| Diğer araçlar | İmsakiye, Esmâ, Cuma (çeviri), Dini Günler (Diyanet tarihleri, "x gün kaldı", 2029+ kandil düzeltmesi), Kaza (±48dp), Namaz Takibi (istatistik kutuları) |
| Kıble | Gerçek kıble açısı (İstanbul 152°) + telefon yönü ayrı, harfler dik, kayıtlı konum yedeği, pusulasız cihaz ekranı |
| Zikirmatik | Çeviriler, görünür "Sayacı Düzenle", sıfırlama onayı, zikir listesi Arapça taşma hatası düzeldi |
| Ayarlar | Dil ilk satır, gerçek sürüm, tutarlı satırlar, arka plan resminde okunur başlıklar |
| Bağımlılık | story_view + upgrader kaldırıldı (16 paket az), package_info_plus doğrudan |
- Test: 330 geçiyor (+10 ekran görüntüsü testi env ile). Ekran görüntüsü düzeneğinde tr/de/fr/ar, açık/koyu/arka plan, 320dp + %130'da düzen hatası yok.
- Kotlin (widget'lar, kalıcı bildirim, MainActivity) bulutta API 36 çerçevesine ve SDK'daki flutter.jar'a karşı derlendi, Robolectric testleri geçti (düzenek repo dışında); gerçek cihaz testinin yerini tutmaz.
- AdMob: AB kullanıcıları için AdMob panelinde "Gizlilik ve mesajlaşma → GDPR mesajı" yayınlanmış olmalı; yoksa AB'de reklam gösterilmeyebilir (ertelendi, kullanıcı işi).

## Sonrası (bu dalda) ✅
- Çeviri denetimi: 5 dil ana dil gözüyle denetlendi, ikinci ajan onaylı 360 düzeltme (`a40c3f4`); yinelenen arb anahtarları temizlendi.
- Kıble pusulası sadece sekme görünür + uygulama ön plandayken çalışır (arka planda/reklamda sensör kapanır), kalibrasyon uyarısı 2 sn gecikmeli (`7cd668d`).
- Araştırma raporu (widget, üyelik, rakipler) → öneriler aşağıda **Yol haritası**'nda.

## Bilinen sınırlar
- Önceki sürüm cihazda kısa test edildi (vakitler, ince ayar, imsakiye paylaşımı OK). Yeni arayüz henüz cihazda denenmedi; "Kıldım" butonu, AB rıza formu ve Play esnek güncelleme yalnızca gerçek cihaz/Play sürümünde görülebilir.
- Yüksek enlemde (NL/BE/FR, Haziran) Yatsı gece yarısını geçebilir; "HH:mm" modeli tarihsiz → sayaç Yatsı'yı atlar (eski sürümde de aynıydı, alarm doğru saatte çalar).
- Konum telefonun saat diliminde gösterilir (başka ülkedeki şehir seçilirse saat farkı kadar kayar).
- Widget/kalıcı bildirim "HH:mm" verisi telefonun saat diliminde yazılır: saat dilimi değişince (yolculuk) widget
  hemen yeniden çizilir ama vakitler, Dart yeniden hesaplayana kadar (uygulama açılışı veya ≤6 saatte WorkManager) eski
  dilimdedir. Gün dönümü ve yatsı sonrası imsak artık doğru (`times_date` + `tomorrow_*`, `PrayerWidgetData.kt`).
- 2029+ Ramazan/Kadir tarihleri `religious_days.json`'a eklenmezse hijri paketinden (±1 gün) gelir; kandiller düzeltilmiş.
- Android 12/12L'de "Alarmlar ve hatırlatıcılar" kapatılırsa ezan ve hatırlatmalar yaklaşık 1 saate kadar gecikebilir (sistem sınırı;
  uyarı şeridi gösterilir). Bu kipte hatırlatmalar saatli metinle gelir; gecikmiş farz ezanı (saati/ayarı değişmediyse) 90 dk korunur, Güneş bildirimi ve
  hatırlatmalar korunmaz (yeniden kurulumda iptal). Android 13+ etkilenmez (USE_EXACT_ALARM).
- "Sessiz modda da çal" Android 8+ (ses türü bildirim kanalıyla verilir); 7.x'te anahtar gösterilmez.
- Pil optimizasyonu muafiyeti penceresi açılmaz: `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` manifest'ten çıkarıldı (1e9c763), permission_handler
  sessizce reddeder. Honor/Huawei gibi agresif pil yönetiminde ezan için kullanıcı pil ayarını elle "sınırsız" yapmalı. Geri
  eklemek Play'de izin politikası incelemesi gerektirir; karar uygulama sahibinin.

## Yayın öncesi kontrol (cihazda, önerilen)
1. Ana ekran vakitleri, şehir değiştirme, internetsiz açılış.
2. Ezan bildirimi + "Kıldım" butonu (uygulama kapalıyken) → Bugün satırında görünmeli.
3. Ana ekran widget'ı ve kalıcı bildirim ertesi gün güncel mi (gece yarısından hemen sonra yeni günün vakitleri,
   yatsıdan sonra sayaç yarının imsakına); saati elle değiştirince sayaç hemen düzeliyor mu; widget seçicide üç ayrı
   ad + açıklama + önizleme (Android 12+); kilitliyken bildirime dokununca önce kilit açılıyor mu.
4. Yeni ekranlar: ana ekran, Araçlar, Zekat (10.000 yaz → doğru), Kıble, Zikirmatik, Ayarlar; koyu tema.
5. "Sessiz modda da çal": telefon sessiz/titreşimdeyken açık → ezan alarm ses seviyesinde çalar; kapalı → sessiz kalır.
6. Bildirim izni (Android 13+): izni reddet → ana ekranda uyarı → "Aç" → izin penceresi ya da ayarlar; izin verilince uyarı kalkar.
7. Güncelleme: Play'deki sürümün üzerine kur, uygulamayı aç → sonraki ezanlar birer kez çalar (alarm ID'leri değişti, çift ezan yok).
8. Yedekten geri yükleme / yeni telefona aktarım → izin açıklaması ve bildirim/konum izni yeniden sorulur.
9. Araçlar → Ayarlar reklamsız açılır; 7 günlük tam seride bir kez değerlendirme penceresi (Play sürümünde).
10. (Android 12/12L cihaz varsa) "Alarmlar ve hatırlatıcılar"ı kapat → yeni uyarı metni + "İzin ver"; kapalıyken ezan gelir (gecikebilir),
    hatırlatmalar saatli metinle; vakitten hemen sonra uygulamayı açınca gecikmiş ezan yine çalar; widget ve kalıcı bildirim vakitten
    sonra ekran açıkken en geç ~10 dk içinde yenilenir. (Android 7.x varsa: "Sessiz modda da çal" görünmez.)

## Yayın (1.1.0+14)
- Derleme ayarı v13 (a3e7cd2) ile aynı: R8 ve kaynak küçültme kapalı (`isMinifyEnabled`/`isShrinkResources = false` →
  flutter_local_notifications Gson kayıtları ve `res/raw` ezan sesleri korunur), compile/target SDK 36. Arka plan giriş
  noktaları (`callbackDispatcher`, `onNotificationActionBackground`, `onStart`) `@pragma('vm:entry-point')`'lu (AOT'de silinmez).
- Manifest farkı (v13'e göre): FGS türü `dataSync|specialUse` → `specialUse`; `USE_EXACT_ALARM` v13'te de vardı → yeni izin beyanı yok.
- Akış: `flutter build appbundle --release --dart-define=COLLECT_API_KEY=<anahtar>` → Play Dahili test (Play sürümünün üstüne
  güncelleme = kontrol 7) → Üretim, kademeli %20 → %100. Aynı gün: Veri güvenliği formuna Crashlytics.

## Yol haritası (öneriler; sıra kullanıcı onayıyla)
Efor: S ≤1 gün · M 2–4 gün · L 1 hafta+. Kaynak: araştırma raporu (Ekim 2026); yapılanlar çıkarıldı.

**Kasım — Üç Aylar 10 Aralık 2026'dan önce yayında**
1. Bildirim sağlık ekranı (M): bildirim/tam zamanlı alarm izni, pil, ses ve Rahatsız Etmeyin, sıradaki alarmın saati,
   "1 dk sonra test ezanı"; üretici rehberi (Xiaomi otomatik başlatma, Honor/Huawei, Oppo/Realme, Vivo, Samsung; dontkillmyapp);
   WorkManager son koşu kaydı 12–24 sa eskiyse "uygulama öldürülüyor" uyarısı. Ayarlar'daki "Bildirim Gelmiyor mu?" diyaloğunun yerine.
2. Kandil / Üç Aylar bildirimleri (S–M): `religious_days.json`'dan — Üç Aylar + Regaib 10.12.2026, Miraç 04.01.2027,
   Berat 22.01.2027, Ramazan 08.02.2027, Kadir 05.03.2027; Ayarlar'da aç/kapa. (json'da "12 Ocak 2025 Üç Ayların Başlangıcı"
   Diyanet'e göre 1 Ocak 2025 olmalı; geçmiş tarih, bu işte düzeltilsin.)
3. Widget iyileştirme (M): kontrast (açık duvar kâğıdında yetersiz), açık/koyu tema + Material You, en/ar'da 12 saat (widget
   hep 24 saat), kalıcı bildirimin sabit renkleri ve "Vakit" yedek metni (`custom_notification.xml`), uygulama içi
   "Ana ekrana ekle" (home_widget 0.7, yeni bağımlılık yok).
4. Tam ekran reklam yalnız Zekat'ta (S): araç açılışlarındaki interstitial kalkar (`tools_view.dart`); gelir etkisi ölçülür.
5. ~~Gizlilik politikası linki~~ (1.1.1'de yapıldı) + AB'de Analytics'i UMP rızasına bağlama (`setConsent`) (S).

**Aralık – 10 Ocak 2027 — Ramazan 8 Şubat 2027**
6. Ramazan widget'ı (S–M): iftar/sahur sayacı; Ramazan dışında "Ramazan'a X gün".
7. Fitre/fidye hesaplayıcı (S): Diyanet tutarı uygulama güncellemeden değiştirilebilmeli.
8. Tek seferlik "Reklamsız" satın alma (M): abonelik yok; Play hesabıyla geri yüklenir; ezan/widget/imsakiye/takip hep ücretsiz.

**Ramazan sonrası**
9. Yedekle / Geri yükle (S–M): takip, kaza, zikir, ayarlar tek dosya (share_plus) → Drive/WhatsApp; hesap gerekmez.
10. Ön plan servisini isteğe bağlı yapma (M): kalıcı bildirimi NotificationUpdater zaten çiziyor; FGS otomatik yedeği engelliyor
    ve Play beyanı istiyor. Yedek kuralları (`dataExtractionRules`) ile birlikte.
11. Erişilebilirlik (M): %200 yazı, TalkBack etiketleri (saniyelik sayaç okunmasın), sade mod, ezan bildiriminde "Durdur".
12. 81 il / 973 ilçe + Avrupa şehir koordinatları gömülü (M): internetsiz şehir seçimi, ilçe merkezinden hesap; gurbetçiye
    "memleket vakitleri".
13. Kadın modu (özel gün: seri bozulmaz, kazaya sayılmaz, istenirse ezan susar) + kaza sihirbazı (M–L).
14. "Namazdayım" (S–M): vakit girince X dk sessiz (Rahatsız Etmeyin erişimi); Cuma penceresi öğle vaktine göre.
15. Yeni widget'lar (M–L): sıradaki vakit halkası (`VaktindeWidgetSmallProvider` sınıfı korunmalı), etkileşimli "Bugün" takip widget'ı.
16. Kur'an modülü + namaz hocası (L): meal lisansı kontrol edilmeli (alquran.cloud `tr.diyanet`).

**Yapılmayacak:** üyelik/giriş (şimdilik), yapay zekâ hoca, abonelik, uygulama içinde sadaka/zekat toplama.
**Kullanıcı işleri:** CollectAPI anahtarı (yenile, dart-define), AdMob GDPR mesajı + hassas kategori engelleri, Veri güvenliği
(Crashlytics), pil izni kararı; mağaza görselleri: Aralık başı Üç Aylar, ~11 Ocak "Ramazan 2027 İmsakiye".

## Yayın öncesi kontrol (1.1.1, cihazda)
1. Tüm ezanlar kapalı → durum çubuğunda alarm simgesi yok (güncellemeden sonra uygulamayı bir kez açınca 1.1.0'ın alarmları da yeniden kurulur).
2. Bir ezan açık → simge var (beklenen: ezan alarmı); Ayarlar > "Günün ayeti ve hadisi" kapat → 10:00/19:00 bildirimi gelmez.
3. Widget/kalıcı bildirim: vakit geçtikten sonra ekranı aç → en geç ~1 dk içinde sıradaki vakte sayar, başlık "Akşama" gibi.
4. Kıble: bilinen bir yönle (cami) karşılaştır; mıknatıslı kılıf/metal yanında parazit uyarısı; alttaki not ve bilgi sayfası.
5. Ayarlar > Destek > Gizlilik Politikası tarayıcıda açılır.

## v1.1.2: R8 (Play "DEX kodu optimizasyonu, eşiğimizin altında"; Kod karartma %1, son tarih Şub 2027)
Release derlemesinde R8 açıldı (küçültme + optimizasyon + karartma), kaynak küçültme kapalı kaldı (res/raw sesleri).
Kurallar `android/app/proguard-rules.pro`. Bu ortamda R8 çalıştırılamadığı için dahili testte cihazda denenecekler:
1. Derleme "Missing classes detected while running R8" ile durursa missing_rules.txt satırları kurallara eklenir.
2. 1.1.1 kuruluyken 1.1.2'ye güncelle → uygulamayı aç → bir sonraki vakit için ezan aç; ezan çalar, "Kıldım" işler.
3. Telefonu yeniden başlat → kurulu ezan yine çalar (eklenti Gson kaydını okur).
4. Widget'lar, kalıcı bildirim, kıble pusulası, reklamlar çalışır; Crashlytics'te "kurulamadı" kaydı yok.
