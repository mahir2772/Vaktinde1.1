# Vaktinde — Durum Analizi (2026-10-06)

Kaynak: `main` @ a3e7cd2. Mimari için `CLAUDE.md`.
Not: Bu ortamda Flutter SDK yok ve `api.aladhan.com` erişimi kapalı; API canlı test edilemedi, bulgular kod okumasına dayanıyor.

## 🔴 Kritik

### 1–2. Ana ekranda "Hata" — vakitler gelmiyor ✅ (v1.0.1+14)
- Belirti: "Hata" + "Tekrar Dene" → yine hata; manuel şehir seçimi de çözmüyor.
- Neden: cache günlük (`cached_prayer_date`), her yeni gün Aladhan `timingsByCity` çağrılıyor; API her istekte başarısız → `dataError`. Yani sorun her gün **tüm kullanıcılarda**.
- Çözüm: vakitler `adhan_dart` ile cihazda hesaplanıyor (Diyanet yöntemi, Diyanet resmi verisiyle ±1 dk, testli). Koordinat: GPS / arama sonucu / il-ilçe adından geocode, `saved_lat/lng` olarak saklanıyor. Aladhan sadece koordinat bulunamazsa yedek (10 sn timeout). Gün değişince (uygulama öne gelince) otomatik yeniden hesaplama. Eski kullanıcılar ilk açılışta otomatik geçiyor.
- Yan kazanç: yurt dışı konumlar da artık doğru (eskiden `country=Turkey` sabitti).

### 3. Test reklam ID'leri yayında (gelir = 0) ✅ (v1.0.1+14)
- Hepsi `AdIds`'e taşındı, `kReleaseMode` ile otomatik seçim. Alt menü banner'ı: `/3285554173`.
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
8. **Sürüm:** Play'deki son sürüm 13 (1.0.0) → pubspec `1.0.1+14` yapıldı ✅. İsim `ezan_saati`, açıklama "A new Flutter project" duruyor.
9b. **Alarmlar tek seferlik:** `_rescheduleAlarms` her vakit için sadece bir sonraki alarmı kuruyor; uygulama hiç açılmazsa ertesi gün ezan bildirimi gelmeyebilir. Birkaç günlük alarm önceden kurulmalı (vakitler artık her gün için hesaplanabiliyor).

## 🟡 Orta / Temizlik
9. `test/widget_test.dart` varsayılan sayaç testi, hiç çalışmaz.
10. `android/build/reports/` git'e girmiş; `.vscode/flutter-translator/` gereksiz.
11. `README.md` varsayılan şablon.
12. Ölü kod: `PrayerTimesModel.fromList` (eski API kalıntısı).
13. `GoogleFonts` runtime indirme → ilk açılış internetsizse font yok; fontlar asset'e gömülebilir.
14. `AdHelper` iOS'ta exception atıyor (iOS yayını planlanırsa).
15. Kotlin dosyaları `com/example/mmdigital` klasöründe, package `com.mmdigital.vaktinde` (çalışır, düzensiz).

## Önerilen yol haritası
- **Faz 1 – Acil hotfix sürümü:** #1, #2, #3, version bump ✅ — kalan: #4 (CollectAPI key).
- **Faz 2 – Stabilite:** Crashlytics, manifest izin temizliği, diğer timeout'lar, test.
- **Faz 3 – İyileştirme:** offline hesaplama yedeği, temizlik maddeleri, yeni özellikler.
