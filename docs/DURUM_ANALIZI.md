# Vaktinde — Durum (v1.0.1+14)

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

## Bilinen sınırlar
- ~~Kalıcı bildirim/widget uygulama açılmazsa eski günde kalıyordu~~ → WorkManager 6 saatte bir `PrayerRefreshService.runHeadless`; NotificationUpdater her vakitte kendini yeniler. Cihazda doğrulanmadı.
- `test/`: vakit hesaplama, alarm planı, arka plan yenileme (platform kanalı taklidiyle), ince ayar ekranı.

## Yayın öncesi kontrol (cihazda)
1. Ana ekranda vakitler, şehir değiştirme, internetsiz açılış.
2. Ezan bildirimi geliyor mu (bir vakti 2 dk sonraya denk getirip bekle).
3. Zekat ekranında canlı kur (dart-define ile derlendiyse).
4. Firebase konsolunda Crashlytics'in ilk açılışı görmesi.

## Öneriler (onay bekliyor)
Bkz. sohbet; onaylananlar buraya taşınır.
