# Vaktinde — v1.5.0+21 Sürüm ve Geliştirme Özeti

- **Uygulama / Paket:** Vaktinde (`com.mmdigital.vaktinde` / repo: `ezan_saati`)
- **Sürüm:** `1.5.0+21` (önceki: `1.4.1+20`)
- **Yayın Tarihi:** 22 Kasım 2026
- **Git Referansı:** `main` — commit `bafb40c`, etiket `v1.5.0`
- **Desteklenen Diller:** Türkçe (`tr`), İngilizce (`en`), Almanca (`de`), Fransızca (`fr`), Arapça (`ar`)
- **Dağıtım Durumu:** Google Play Console Üretim kanalında tam kullanıma sunma olarak yayında.

---

## 1. v1.5.0 Sürümünde Yapılan Geliştirmeler

### 1.1. "Namazdayım" Otomatik Sessiz Modu (Android DND)
- **Native Android Motoru:** `android/app/src/main/kotlin/com/mmdigital/vaktinde/PrayerSilence.kt` ile Android `ACCESS_NOTIFICATION_POLICY` (Rahatsız Etmeyin) erişimi üzerinden belirlenen pencerelerde otomatik sessize alma ve süre bitince telefonun önceki ses/DND durumuna dönme mekanizması kuruldu.
- **Akıllı Pencere Kuralları (`lib/data/services/prayer_silence.dart`):**
  - Telefon pencere başında zaten DND modundaysa mevcut duruma dokunulmaz.
  - Sesli ezan aktif olan vakitlerde ezanın kesilmemesi için sessiz mod vakitten 1 dakika sonra başlar.
  - Cuma namazı penceresi (öğleden 15 dk önce → 45 dk sonra) ayrı anahtarla yönetilir ve çakışan öğle penceresiyle birleştirilir.
  - Farklı saat dilimi ve gece yarısını geçen yaz Yatsısı senaryolarıyla uyumlu çalışır.
- **Arayüz & Entegrasyon:**
  - `lib/features/settings/view/prayer_silence_setting.dart` ve `notification_settings_view.dart` altına "Namazdayım (otomatik sessiz)" satırı ve alt ayar sayfası (izin kontrolü/yönlendirme, süre seçimi, vakit seçimi, Cuma penceresi) eklendi.
  - `HomeViewModel` ve `PrayerRefreshService` akışına bağlandı; ayarlardan izin verip dönüldüğünde pencereler otomatik eşitlenir.
  - `StorageService` ve `BackupService` (doğrulama kurallarıyla) kapsamına alındı, 5 dilde çevrildi.

### 1.2. Seçilen Şehrin Yerel Saati ("Memleket Vakitleri") & Avrupa Yaz Yatsısı
- Vakit gösterimi, geri sayım, alarmlar, kerahat hesabı, Ramazan kartı, yedekleme ve native Android ana ekran widget'ları seçilen şehrin IANA saat dilimine göre çalışacak şekilde güncellendi.
- Avrupa yaz aylarında gece yarısını geçen Yatsı vakitlerindeki gün/sıralama kayması düzeltildi.

### 1.3. Kaza Bitiş Tahmini
- Namaz Takibi > Kaza sekmesine, kullanıcının günlük kaza hedefine göre toplam borcun tahmini tamamlanma süresini gösteren hesaplama ve arayüz eklendi.

### 1.4. Çevrimdışı Hadis Havuzu & Tekrar Önleme (`HadithService`)
- `lib/data/services/hadith_service.dart` güncellendi:
  - 5 dilin her biri için 10'ar hadislik yerel çevrimdışı yedek havuz (`_fallbackTr`, `_fallbackEn`, `_fallbackDe`, `_fallbackFr`, `_fallbackAr`) oluşturuldu.
  - Gösterilen hadis kimlikleri `seen_hadith_ids` (en fazla 1000 kayıt, `BackupService` kapsamına dahil) ile kalıcı takip edilerek tekrarlar engellendi.
  - HadeethEnc'in 7 ana kök kategorisi ve sayfa ilerletme (`hadith_category_pages`) mekanizmasıyla geniş havuzdan seçim ve sonraki 7 gün için önceden önbellekleme (`prefetch`) sağlandı.

### 1.5. Dini Gün Bildirim Yönlendirmesi
- Dini gün ve kandil bildirimlerine tıklandığında kullanıcının doğrudan ilgili Dini Günler ekranına yönlendirilmesi sağlandı.

### 1.6. Uygulama Açılış Reklamı (App Open Ad)
- AdMob App Open Ad birimi entegre edildi.
- Sıklık sınırı, yeni kurulumda ilk 24 saat koruma süresi ve ibadet ekranlarında reklam göstermeme kısıtları uygulandı.

### 1.7. Sürüm Artışı & "Yenilikler" (`WhatsNew`) Ekranı
- `pubspec.yaml` sürümü `1.4.1+20` → `1.5.0+21` olarak güncellendi.
- `lib/features/app_guide/whats_new.dart` içindeki `WhatsNew.version` değeri `1.5.0` yapıldı ve önceki sürümden güncelleyen kullanıcılara bir kez gösterilecek 4 yeni kart (Namazdayım → `notificationSettings`, Şehir Saati → `location`, Kaza Tahmini → `kaza`, Çevrimdışı Hadisler & Dini Günler → `religiousDays`) 5 dilde eklendi.

---

## 2. Doğrulama, Test ve Kalite Özeti

- **Statik Analiz:** `flutter analyze` → `0` hata, `0` uyarı.
- **Flutter Test Paketi:** `flutter test` → `984` geçti, `40` atlandı, `0` başarısız.
  - `test/prayer_silence_test.dart`: 12/12 geçti (pencere planı, 1 dk sesli ezan kayması, Cuma birleşimi, Amsterdam yaz Yatsısı, Storage, Backup, 5 dil ve Bildirim Ayarları widget testi).
  - `test/settings_rows_test.dart`: 21/21 geçti (Bildirim Ayarları 8 `Switch` ve sıralama kontrolü).
  - `test/feature_discovery_test.dart`: 17/17 geçti (1.5.0 `WhatsNew` satır yönlendirmeleri ve 320dp %130 yazı boyutunda `tr`/`de`/`ar` taşma kontrolü dahil).
- **Android Native Testleri:** `.\gradlew :app:testDebugUnitTest` → `BUILD SUCCESSFUL`.
- **Gerçek Cihaz Release Testi:** `flutter run --release` ve `adb shell pm clear com.mmdigital.vaktinde` ile sıfır kurulum (dil seçimi, tanıtım turu, HadeethEnc API, AdMob yükleme, şehir saati, Namazdayım) doğrulandı.

---

## 3. Yayın Sonrası Teknik Takip Maddeleri

- [ ] USB release kurulumunu kaldırıp Play Store'dan canlı `1.5.0+21` sürümünü indirerek son kontrolü yapmak.
- [ ] İlk 48 saatte Firebase Crashlytics (`1.5.0 (21)`) üzerinde Samsung/Xiaomi/Honor cihazlarda `PrayerSilence` (DND) veya saat dilimi kaynaklı istisna kontrolü.
- [ ] Play Console Ön Lansman Raporu (*Pre-launch report*) kontrolü.
- [ ] AdMob panelinde yeni App Open Ad biriminin gösterim ve politika durumu takibi.

---

## 4. Bir Sonraki Odak Alanı

- **Öncelik 1 — Büyüme ve Görünürlük:** Uygulama teknik olarak olgunlaştı; bundan sonraki ana odak Play Store organik görünürlüğü (ASO) ve sosyal medya üzerinden düzenli indirme akışı oluşturmak.