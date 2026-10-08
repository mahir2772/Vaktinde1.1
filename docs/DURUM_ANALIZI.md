# Vaktinde — Durum (v1.1.0+14)

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
| 8 | Alarmlar tek günlük | Koordinat varsa 5 gün önceden (ID 0-59) |
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
- Test: 221 geçiyor (+10 ekran görüntüsü testi env ile). Ekran görüntüsü düzeneğinde tr/de/fr/ar, açık/koyu/arka plan, 320dp + %130'da düzen hatası yok.
- AdMob: AB kullanıcıları için AdMob panelinde "Gizlilik ve mesajlaşma → GDPR mesajı" yayınlanmış olmalı; yoksa AB'de reklam gösterilmeyebilir (ertelendi, kullanıcı işi).

## Sonrası (bu dalda) ✅
- Çeviri denetimi: 5 dil ana dil gözüyle denetlendi, ikinci ajan onaylı 360 düzeltme (`a40c3f4`); yinelenen arb anahtarları temizlendi.
- Kıble pusulası sadece sekme görünür + uygulama ön plandayken çalışır (arka planda/reklamda sensör kapanır), kalibrasyon uyarısı 2 sn gecikmeli (`7cd668d`).
- Araştırma raporu (widget, üyelik, rakipler): sohbette kullanıcıya verildi; öneri sırası orada.

## ⏸ DURAKLATILDI — Güvenilirlik düzeltmeleri (yarım, bu dalda DEĞİL)
Kullanıcı isteğiyle durduruldu (2026-10-08). Bu dal kararlı; yarım iş koda karışmadı.
- Arşiv: `docs/wip/guvenilirlik-wip.bundle` (taban `326a624`, dal `wip/ui-int` @ `1805062`). Geri yükleme:
  `git fetch docs/wip/guvenilirlik-wip.bundle 'refs/heads/wip/ui-int:refs/heads/wip/ui-int'`. İş bitince bundle + `inceleme_bulgular.json` silinecek.
- Arşivdeki hazır işler (analyze temiz, 302 test geçiyor; henüz cihazda denenmedi):
  - **A Ezan güvenilirliği:** tam zamanlı alarm izni yoksa `inexactAllowWhileIdle` yedeği (ezan kaybolmaz), kurulum hataları alarm başına yakalanır + Crashlytics (non-fatal), ana ekran/Alarmlar'da izin ve "bildirimler kapalı" uyarı kartları, isteğe bağlı "Sessiz modda da çal" (alarm ses kanalı, varsayılan kapalı).
  - **B Android yüzeyleri/güvenlik:** kilit ekranı açığı kapatıldı (showWhenLocked/turnScreenOn kaldırıldı), 3 widget 30 dk yenilenir, ayrı ad/açıklama/önizleme, saat/saat dilimi değişince yenilenir, gün dönümü için yarının vakitleri yazılır, silinen widget'ın alarmı iptal. Kotlin ajan tarafından derlenip Robolectric ile (API 26/31/34/35) test edildi.
  - **C Gizlilik/izin/reklam:** yedekten/telefon değişiminden sonra cihaz bayrakları sıfırlanır (`InstallGuard`, izin tekrar sorulur), analitikte konum/vakit yok, Ayarlar reklamsız açılır, reklam içerik sınırı PG, 7 günlük seride bir kez uygulama içi değerlendirme.
- Son inceleme turu (4 açı, her bulgu 2 doğrulayıcı) 7 bulgu çıkardı (`docs/wip/inceleme_bulgular.json`); düzeltici yarıda durdu:
  1. ✅ İzin yoksa widget/kalıcı bildirim yenilemesi `setAlarmClock` ile hep hata veriyordu → gecikmeli alarm (`74b9209`; Kotlin değişikliği, yeniden derleme doğrulaması önerilir).
  2. ⏳ Gecikmeli (inexact) modda yeniden kurulum, vakti gelmiş ama henüz teslim edilmemiş ezanı iptal ediyor (prayer_refresh_service ~657) — yarım: sadece test saati eklendi (`1805062`).
  3. Gecikmeli modda "X dk kaldı" hatırlatmaları olaydan sonra gelebiliyor; uyarı metni "birkaç dakika" diyor ama Android 12'de ~1 saate kadar gecikebilir (metin + mutlak saatli içerik).
  4. "Sessiz modda da çal" Android 7'de çalışmaz (minSdk 24) → Android 8 altı gizlenmeli.
  5. Yedek, yeni telefonda ilk açılıştan önce Play tarafından güncellenirse InstallGuard eski bayrakları benimseyebilir (düşük).
  6. Belgeler: CLAUDE.md/DURUM_ANALIZI paket A ve C'yi tam yansıtmıyor.
  7. (6. ile birlikte) InstallGuard anahtar listesi ve testleri güncel tutulmalı.
- Devam adımları: bundle'ı geri yükle → 2–7'yi düzelt (testli) → Kotlin'i yeniden derle/Robolectric → analyze + test + ekran görüntüsü → kısa yeniden inceleme → ana dala ff + push.

## Bilinen sınırlar
- Önceki sürüm cihazda kısa test edildi (vakitler, ince ayar, imsakiye paylaşımı OK). Yeni arayüz henüz cihazda denenmedi; "Kıldım" butonu, AB rıza formu ve Play esnek güncelleme yalnızca gerçek cihaz/Play sürümünde görülebilir.
- Yüksek enlemde (NL/BE/FR, Haziran) Yatsı gece yarısını geçebilir; "HH:mm" modeli tarihsiz → sayaç Yatsı'yı atlar (eski sürümde de aynıydı, alarm doğru saatte çalar).
- Konum telefonun saat diliminde gösterilir (başka ülkedeki şehir seçilirse saat farkı kadar kayar).
- 2029+ Ramazan/Kadir tarihleri `religious_days.json`'a eklenmezse hijri paketinden (±1 gün) gelir; kandiller düzeltilmiş.

## Yayın öncesi kontrol (cihazda, önerilen)
1. Ana ekran vakitleri, şehir değiştirme, internetsiz açılış.
2. Ezan bildirimi + "Kıldım" butonu (uygulama kapalıyken) → Bugün satırında görünmeli.
3. Ana ekran widget'ı ve kalıcı bildirim ertesi gün güncel mi.
4. Yeni ekranlar: ana ekran, Araçlar, Zekat (10.000 yaz → doğru), Kıble, Zikirmatik, Ayarlar; koyu tema.
