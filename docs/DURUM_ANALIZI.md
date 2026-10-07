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

## ⏸ DURAKLATILDI — Arayüz yenilemesi (yarım, bu dalda DEĞİL)
Kullanıcı isteğiyle durduruldu (2026-10-07). Bu dal (v1.1.0+14) kararlı ve cihazda denendi; yarım arayüz işi koda karışmadı.
- Yarım iş arşivi: `docs/wip/ui-yenileme-wip.bundle` (taban `287cfaa`). Geri yükleme:
  `git fetch docs/wip/ui-yenileme-wip.bundle 'refs/heads/wip/*:refs/heads/wip/*'` → dallar `wip/ui-wpa`, `wip/ui-wpb`, `wip/ui-wpc`.
  İş bitince bundle dosyası silinecek.
- Plan (UX denetimi): evrimsel yenileme, ortak tasarım `lib/core/ui/` (`ui.dart`), 3 iş paketi, dosya sahipliği ayrık.
  - **WP-A** `wip/ui-wpa` 841eea0 (taban 9d1e365 = tema + ortak bileşenler + çeviri anahtarları, testli). Ana ekran/alt menü/uygulama açılışı yenilendi (sayaç odaklı üst alan, dokunulabilir şehir, hicri tarih, kerahat/Ramazan çipleri, ayet/hadis okunabilir sayfa, tek güncelleme akışı, UMP reklam izni, sekme reklamı kaldırıldı, initializeApp tek sefer). Analyze temiz; KALAN: tam test, ekran görüntüsü kontrolü, prayer_schedule testi, story_view + upgrader bağımlılıklarını kaldır, CLAUDE.md/doküman.
  - **WP-B** `wip/ui-wpb` 88389d6: Araçlar listesi (gruplu, kesilen kart düzeldi) + İmsakiye + 23 çeviri anahtarı. KALAN: Zekat (sonuç reklama bağlı; 'Hisse Senedi' ve tarım türü varsayılanları en/de/fr/ar'da hatalı; gümüş/manuel fiyat alanı yazılamıyor; "2500,50" virgüllü sayı 0 okunuyor; ₺ etiketi; `AdConsent.canRequestAds` kontrolü), Esmâ, Cuma (çeviri, italik yok), Dini Günler (x gün kaldı), Kaza, Namaz Takibi (`test/prayer_tracker_widgets_test.dart` kısıtlarına dikkat), `test/tools_widgets_test.dart`.
  - **WP-C** `wip/ui-wpc` c346a83: Kıble (gerçek kıble açısı + telefon yönü ayrı, harfler dik, kayıtlı konum yedeği, pusulasız ekran, tek kalibrasyon uyarısı). KALAN: Zikirmatik (çeviriler, düzenle butonu, sıfırlama onayı, mor tonlar, zikir listesinde Arapça taşma hatası), Ayarlar (gerçek sürüm package_info_plus, dalgalanma efekti, bg_quran.webp yok, dil seçimi), konum arama, onboarding izin adımı, `test/screens_c_test.dart` (İstanbul kıble ≈151–152°).
- Devam sırası: üç dalı birleştir (çakışan arb'ler: anahtar birleşimi + `flutter gen-l10n`), kalanları ajanlara böl, ekran görüntüsü düzeneği (`SCREENSHOT_DIR=... flutter test test/screenshots/`) ile önce/sonra karşılaştır, inceleme ajanı, cihaz testi.

## Bilinen sınırlar
- Cihazda kısa test edildi (vakitler, ince ayar, imsakiye paylaşımı OK); "Kıldım" bildirim butonu henüz denenmedi. `flutter analyze` temiz, 88 test geçiyor.
- Yüksek enlemde (NL/BE/FR, Haziran) Yatsı gece yarısını geçebilir; "HH:mm" modeli tarihsiz → sayaç Yatsı'yı atlar (eski sürümde de aynıydı, alarm doğru saatte çalar).
- Konum telefonun saat diliminde gösterilir (başka ülkedeki şehir seçilirse saat farkı kadar kayar).
- 2029+ Ramazan tarihleri `religious_days.json`'a eklenmezse hijri paketinden (±1 gün) gelir.

## Yayın öncesi kontrol (cihazda, önerilen)
1. Ana ekran vakitleri, şehir değiştirme, internetsiz açılış.
2. Ezan bildirimi + "Kıldım" butonu (uygulama kapalıyken) → Bugün satırında görünmeli.
3. Ana ekran widget'ı ve kalıcı bildirim ertesi gün güncel mi.
