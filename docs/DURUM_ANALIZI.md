# Vaktinde — Durum Analizi (2026-10-06)

Kaynak: `main` @ a3e7cd2. Mimari için `CLAUDE.md`.
Not: Bu ortamda Flutter SDK yok ve `api.aladhan.com` erişimi kapalı; API canlı test edilemedi, bulgular kod okumasına dayanıyor.

## 🔴 Kritik

### 1. Vakitler günlük yenilenmiyor (kesin hata)
- `PrayerTimesModel` tarih tutmuyor; cache (`cached_prayer_times`) sadece 6 saat bilgisi.
- `HomeViewModel.initializeApp` (home_view_model.dart:131) cache varsa **API'ye hiç gitmeden** dönüyor.
- API yalnızca: ilk kurulumda, şehir değişince veya konumla manuel yenilemede çağrılıyor.
- Sonuç: kullanıcı aylarca **ilk günün vakitlerini** görüyor. Ezan alarmları, kalıcı bildirim ve widget da bu eski vakitlerle çalışıyor (yaz→kış farkı 2 saate kadar).
- Çözüm: aylık takvim çek (`/v1/calendar...`), tarihle birlikte cache'le, gün değişince/ay bitince yenile.

### 2. Ana ekranda vakitlerin hiç görünmemesi (olası nedenler)
| Neden | Yer | Belirti |
|---|---|---|
| `timingsByCity` metinle geocoding yapıyor; "ilçe, il" + Türkçe karakter bulunamazsa 400 → `null` | prayer_time_service.dart | "Veri hatası" ekranı |
| `http.get` timeout yok | prayer_time_service.dart:24 | Sonsuz yükleniyor |
| `initializeApp` içinde cache'ten önce gelen bir adım (ör. `notificationService.init`) hata atarsa cache bile gösterilmiyor | home_view_model.dart:113-161 | "Genel hata" ekranı |
| Geocoder `administrativeArea`'yı farklı yazabilir (ör. "Istanbul Province") | location_service.dart | Konumla yenileyince veri hatası |
| `prayerTimes!.imsak!` zorla açma; parse hatasında çökme | home_view.dart:60, countdown_widget.dart:62 | Gri/boş ekran |
- Çözüm: koordinat bazlı uç nokta (`/v1/timings` veya `/v1/calendar` + `latitude/longitude`) + 10 sn timeout + cache'i her koşulda önce göster. İsteğe bağlı: `adhan` paketiyle offline hesaplama yedeği (API tamamen çökse de vakit gösterilir).
- **Kullanıcıdan bilgi lazım:** telefonda hangi ekran görünüyor? (internet yok / veri hatası / genel hata / sürekli yükleniyor)

### 3. Test reklam ID'leri yayında (gelir = 0)
| Dosya | Şu an | Olması gereken |
|---|---|---|
| common/ad_helper.dart:22 | test interstitial | `ca-app-pub-4975388193054410/8232165658` |
| zakat/view/zakat_view.dart:22 | test interstitial | `.../2151461471` |
| common/widgets/ad_banner_widget.dart:17 | test banner | `.../6543014509` |
| main_wrapper/main_wrapper.dart:37 | test banner | **gerçek ID kodda yok** → AdMob panelinden alınmalı |
- Öneri: `kReleaseMode`'a göre otomatik test/gerçek seçimi (debug'da yanlışlıkla gerçek reklama tıklama riski de biter).

### 4. CollectAPI anahtarı kaynak kodda
- `economy_service.dart:5` — repo herkese açıksa anahtar sızmış demektir; CollectAPI panelinden yenilenmeli. Kodda tutmamak için `--dart-define` kullanılmalı.

## 🟠 Yüksek
5. **Play politikası:** `USE_EXACT_ALARM` sadece saat/takvim uygulamalarına izinli (ret/uyarı sebebi olabilir); `SCHEDULE_EXACT_ALARM` iki kez tanımlı. `FOREGROUND_SERVICE_SPECIAL_USE` Play Console'da beyan ister. Play Console'daki politika uyarılarına bakılmalı.
6. **Timeout yok:** ayah, hadith, economy servislerinde de.
7. **Hatalar yutuluyor:** onlarca `catch (e) {}`, Crashlytics yok → sahadaki çökme/hata görünmüyor. `firebase_crashlytics` eklenmeli.
8. **Sürüm:** `pubspec.yaml` 1.0.0+12, isim `ezan_saati`, açıklama "A new Flutter project". Play'deki son versionCode'dan büyük olmalı.

## 🟡 Orta / Temizlik
9. `test/widget_test.dart` varsayılan sayaç testi, hiç çalışmaz.
10. `android/build/reports/` git'e girmiş; `.vscode/flutter-translator/` gereksiz.
11. `README.md` varsayılan şablon.
12. Ölü kod: `PrayerTimesModel.fromList` (eski API kalıntısı).
13. `GoogleFonts` runtime indirme → ilk açılış internetsizse font yok; fontlar asset'e gömülebilir.
14. `AdHelper` iOS'ta exception atıyor (iOS yayını planlanırsa).
15. Kotlin dosyaları `com/example/mmdigital` klasöründe, package `com.mmdigital.vaktinde` (çalışır, düzensiz).

## Önerilen yol haritası
- **Faz 1 – Acil hotfix sürümü:** #1, #2 (koordinat + aylık cache + timeout), #3 (reklam ID'leri), #4, version bump.
- **Faz 2 – Stabilite:** Crashlytics, manifest izin temizliği, diğer timeout'lar, test.
- **Faz 3 – İyileştirme:** offline hesaplama yedeği, temizlik maddeleri, yeni özellikler.
