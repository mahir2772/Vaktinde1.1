# Vaktinde

Ezan vakitleri, kıble pusulası, zikirmatik ve dini araçlar içeren Flutter uygulaması (Android, Play Store: `com.mmdigital.vaktinde`).

- Vakitler cihazda, internetsiz hesaplanır (Diyanet yöntemi, `adhan_dart`).
- Mimari ve klasör yapısı: [`CLAUDE.md`](CLAUDE.md) · Durum/yapılacaklar: [`docs/DURUM_ANALIZI.md`](docs/DURUM_ANALIZI.md)

## Geliştirme
```bash
flutter pub get
flutter run                     # debug: reklamlar otomatik Google test ID'si
TZ=Europe/Istanbul flutter test # vakit hesaplama testi
```

## Yayın (Play Store)
1. `pubspec.yaml` → `version` build numarasını artır (Play'deki son sürümden büyük olmalı).
2. `android/key.properties` + keystore yerelde olmalı (git'te yok).
3. Derle (anahtarlar koda yazılmaz, build sırasında verilir). `COLLECT_API_KEY` verilmezse zekat ekranında canlı kur
   gelmez; `QURAN_AUDIO_API` (Kur'an dinleme ara sunucusunun adresi, kurulum: `server/quran-audio/README.md`) verilmezse
   dinleme hiç görünmez. Dinlemeyi sadece Quran Foundation üretim erişimi onaylanıp ara sunucu açıkken ekleyin:
```bash
flutter build appbundle --release --dart-define=COLLECT_API_KEY=<anahtar> --dart-define=QURAN_AUDIO_API=<https://…workers.dev>
```
