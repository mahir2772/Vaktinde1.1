# Vaktinde sosyal medya içerik takvimi (Aralık 2026 – Mart 2027)

Hesaplar: Instagram ve TikTok **@vaktinde.app**, YouTube **@vaktindeapp**, Facebook sayfası. Saatler Türkiye saatidir.

## Nasıl paylaşılır

1. **Facebook + Instagram:** Meta Business Suite'ten ikisine birlikte planla. `post.png` gönderi, `video.mp4` Reels olarak paylaşılır; aynı gün `story.png` hikâyeye konabilir.
2. **TikTok ve YouTube Shorts:** `video.mp4`'ü telefondan yükle. TikTok'ta `post.png` fotoğraf gönderisi olarak da kullanılabilir.
3. **Müzik:** Videolar sessiz. Müziği her uygulamanın kendi telifsiz müzik kütüphanesinden ekle (Instagram/Facebook "Ses", TikTok "Ses ekle", YouTube "Ses").
4. **Kapak:** Videonun ilk 0,6 saniyesi yumuşak girişle başlar. Reels'te kapak olarak `post.png`'yi seç, TikTok ve Shorts'ta 1. saniyeden sonraki bir kareyi seç.

Facebook'ta bağlantılar tıklanabilir. İstersen "profildeki bağlantı" satırının altına şu bağlantıyı ekle:
`https://play.google.com/store/apps/details?id=com.mmdigital.vaktinde&referrer=utm_source%3Dfacebook%26utm_medium%3Dsocial`

## Dosyalar

Her içerik kendi klasöründe üç dosyadan oluşur:

- `post.png` (1080×1350): Instagram/Facebook gönderisi, TikTok fotoğraf gönderisi
- `story.png` (1080×1920): hikâye
- `video.mp4` (1080×1920, 8 sn, sessiz): Reels, TikTok ve Shorts

Dikey dosyalarda yazılar ve logo platform düğmelerinin altında kalmaz (x 90–990, y 260–1450).

Görseller şu komutla yeniden üretilir: `python3 docs/marketing/make_content.py <çıkış_klasörü> --zip <paket.zip>`.
Tanıtımlardaki ekran görüntüleri `docs/marketing/ekran/` klasöründedir ve uygulamanın ekran görüntüsü testinden (tr, açık tema, İstanbul/Kadıköy) alınmıştır.

| İçerik | Ekran görüntüsü |
|---|---|
| 08_tanitim_ezan | `ekran/tr_10_home.png`: ana sayfa, Vakitler sekmesi |
| 09_tanitim_kible | `ekran/tr_20_qibla.png`: Kıble Pusulası |
| 10_tanitim_zikirmatik | `ekran/tr_30_zikirmatik.png`: Zikirmatik |
| 11_tanitim_imsakiye | `ekran/tr_41_imsakiye_ramazan.png`: İmsakiye, Ramazan sekmesi (Ramazan 1448, 8 Şubat – 8 Mart 2027) |
| 12_tanitim_takip_kaza | `ekran/tr_47_prayer_tracker.png`: Namaz Takibi ve `ekran/tr_46_kaza_calc.png`: Kaza hesapla |
| 13_tanitim_kuran | `ekran/tr_70_quran_list.png`: Kur'an-ı Kerim, "Kaldığın yerden devam et" |

`tr_41_imsakiye_ramazan.png` ve `tr_47_prayer_tracker.png` aynı testin geçici bir kopyasıyla alındı. İlkinde Ramazan sekmesi seçili, ikincisinde 30 günlük örnek takip verisi var (%96, 12 gün seri). Depodaki test dosyası değişmedi. Ekran görüntüleri 13 Ekim 2026'da alındığı için ana sayfa görüntüsünde bu tarih görünür.

## Takvim özeti

| Tarih | Saat | İçerik | Not |
|---|---|---|---|
| 1 Aralık 2026 Salı | 20:30 | 08_tanitim_ezan | 1. tanıtım |
| 4 Aralık 2026 Cuma | 10:00 | 07_cuma | Cuma (A) |
| 7 Aralık 2026 Pazartesi | 20:30 | 09_tanitim_kible | |
| **10 Aralık 2026 Perşembe** | **19:30** | **01_regaib_uc_aylar** | Üç Aylar başlıyor, Regaib Kandili |
| 11 Aralık 2026 Cuma | 10:00 | 07_cuma | Cuma (B) |
| 15 Aralık 2026 Salı | 20:30 | 10_tanitim_zikirmatik | |
| 18 Aralık 2026 Cuma | 10:00 | 07_cuma | Cuma (C) |
| 22 Aralık 2026 Salı | 20:30 | 12_tanitim_takip_kaza | |
| 25 Aralık 2026 Cuma | 10:00 | 07_cuma | Cuma (D) |
| 29 Aralık 2026 Salı | 20:30 | 13_tanitim_kuran | |
| 1 Ocak 2027 Cuma | 10:00 | 07_cuma | Cuma (A) |
| **4 Ocak 2027 Pazartesi** | **19:30** | **02_mirac** | Miraç Kandili |
| 7 Ocak 2027 Perşembe | 20:30 | 08_tanitim_ezan | 2. tur: ezan bildirimi |
| 8 Ocak 2027 Cuma | 10:00 | 07_cuma | Cuma (B) |
| 11 Ocak 2027 Pazartesi | 20:30 | 11_tanitim_imsakiye | Ramazan 2027 imsakiyesi |
| 15 Ocak 2027 Cuma | 10:00 | 07_cuma | Cuma (C) |
| 19 Ocak 2027 Salı | 20:30 | 12_tanitim_takip_kaza | 2. tur: kaza |
| **22 Ocak 2027 Cuma** | **19:30** | **03_berat** | Berat Kandili (bu Cuma 07_cuma yok) |
| 26 Ocak 2027 Salı | 20:30 | 13_tanitim_kuran | 2. tur |
| 29 Ocak 2027 Cuma | 10:00 | 07_cuma | Cuma (D) |
| 1 Şubat 2027 Pazartesi | 20:30 | 11_tanitim_imsakiye | 2. tur: Ramazan'a 1 hafta |
| 5 Şubat 2027 Cuma | 10:00 | 07_cuma | Cuma (A) |
| **7 Şubat 2027 Pazar** | **19:00** | **04_ramazan** | İlk teravih akşamı, ilk oruç 8 Şubat |
| 10 Şubat 2027 Çarşamba | 21:30 | 08_tanitim_ezan | 3. tur: sahur ve iftar |
| 12 Şubat 2027 Cuma | 10:00 | 07_cuma | Cuma (B) |
| 16 Şubat 2027 Salı | 21:30 | 10_tanitim_zikirmatik | 2. tur |
| 19 Şubat 2027 Cuma | 10:00 | 07_cuma | Cuma (C) |
| 23 Şubat 2027 Salı | 21:30 | 13_tanitim_kuran | 3. tur: Ramazan |
| 26 Şubat 2027 Cuma | 10:00 | 07_cuma | Cuma (D) |
| 1 Mart 2027 Pazartesi | 21:30 | 09_tanitim_kible | 2. tur: iftar davetinde |
| **5 Mart 2027 Cuma** | **20:30** | **05_kadir** | Kadir Gecesi (bu Cuma 07_cuma yok) |
| **9 Mart 2027 Salı** | **09:00** | **06_ramazan_bayrami** | Bayram sabahı, namazdan sonra |
| 12 Mart 2027 Cuma | 10:00 | 07_cuma | Cuma (A) |
| 14 Mart 2027 Pazar | 20:30 | 12_tanitim_takip_kaza | 3. tur: kaza orucu |
| 18 Mart 2027 Perşembe | 20:30 | 10_tanitim_zikirmatik | 3. tur |
| 19 Mart 2027 Cuma | 10:00 | 07_cuma | Cuma (B) |
| 23 Mart 2027 Salı | 20:30 | 09_tanitim_kible | 3. tur |
| 26 Mart 2027 Cuma | 10:00 | 07_cuma | Cuma (C) |

Ramazan boyunca tanıtımlar iftar ve teravihten sonra, 21:30'da paylaşılır. Kandil ve bayram görsellerinin hikâyesi (`story.png`) gün içinde ayrıca paylaşılabilir. Cuma için her hafta hikâye yeterlidir. Gönderi ve Reels ayda bir kez paylaşılabilir (ör. 4 Aralık, 8 Ocak, 5 Şubat, 12 Mart).

Tanıtımlar 2. ve 3. turda aynı görselle, farklı metinle paylaşılır.

---

## Özel günler

### 10 Aralık 2026 Perşembe · 19:30 · 01_regaib_uc_aylar

Dosyalar: `01_regaib_uc_aylar/post.png`, `story.png`, `video.mp4`

**Instagram / Facebook**
```
Üç Aylar bugün başlıyor, bu gece Regaib Kandili.
"Allah'ım! Recep ve Şaban'ı bizim için mübarek kıl ve bizi Ramazan'a ulaştır."
Üç Aylarınız ve Regaib Kandiliniz mübarek olsun.

Ezan vakti, kıble ve imsakiye için Vaktinde: profildeki bağlantı

#üçaylar #regaibkandili #kandil #hayırlıkandiller #recep #dua #vaktinde
```

**TikTok**
```
Üç Aylarınız ve Regaib Kandiliniz mübarek olsun. Play Store'da Vaktinde ara.
#üçaylar #regaibkandili #kandil #dua #vaktinde
```

**YouTube Shorts**
- Başlık: `Üç Aylarınız ve Regaib Kandiliniz mübarek olsun #Shorts`
- Açıklama:
```
Üç Aylar 10 Aralık 2026'da başlıyor, aynı gece Regaib Kandili. Üç Aylarınız ve Regaib Kandiliniz mübarek olsun.
Namaz vakitleri, kıble ve imsakiye için Vaktinde'yi Google Play'den ücretsiz indir:
https://play.google.com/store/apps/details?id=com.mmdigital.vaktinde&referrer=utm_source%3Dyoutube%26utm_medium%3Dshorts
```

### 4 Ocak 2027 Pazartesi · 19:30 · 02_mirac

Dosyalar: `02_mirac/post.png`, `story.png`, `video.mp4`

**Instagram / Facebook**
```
Bu gece Miraç Kandili.
Miraç Kandiliniz mübarek olsun.

Ezan vakti, kıble ve imsakiye için Vaktinde: profildeki bağlantı

#miraçkandili #kandil #hayırlıkandiller #üçaylar #recep #vaktinde
```

**TikTok**
```
Miraç Kandiliniz mübarek olsun. Play Store'da Vaktinde ara.
#miraçkandili #kandil #üçaylar #vaktinde
```

**YouTube Shorts**
- Başlık: `Miraç Kandiliniz mübarek olsun #Shorts`
- Açıklama:
```
4 Ocak 2027 Pazartesi gecesi Miraç Kandili. Miraç Kandiliniz mübarek olsun.
Namaz vakitleri, kıble ve imsakiye için Vaktinde'yi Google Play'den ücretsiz indir:
https://play.google.com/store/apps/details?id=com.mmdigital.vaktinde&referrer=utm_source%3Dyoutube%26utm_medium%3Dshorts
```

### 22 Ocak 2027 Cuma · 19:30 · 03_berat

Dosyalar: `03_berat/post.png`, `story.png`, `video.mp4`. Bu Cuma `07_cuma` paylaşılmaz.

**Instagram / Facebook**
```
Bu gece Berat Kandili.
Rabbim bu gecenin hürmetine tövbelerimizi ve dualarımızı kabul eylesin.
Berat Kandiliniz mübarek olsun.

Ezan vakti, kıble ve imsakiye için Vaktinde: profildeki bağlantı

#beratkandili #kandil #hayırlıkandiller #şaban #üçaylar #vaktinde
```

**TikTok**
```
Berat Kandiliniz mübarek olsun. Play Store'da Vaktinde ara.
#beratkandili #kandil #üçaylar #vaktinde
```

**YouTube Shorts**
- Başlık: `Berat Kandiliniz mübarek olsun #Shorts`
- Açıklama:
```
22 Ocak 2027 Cuma gecesi Berat Kandili. Rabbim bu gecenin hürmetine tövbelerimizi ve dualarımızı kabul eylesin.
Namaz vakitleri, kıble ve imsakiye için Vaktinde'yi Google Play'den ücretsiz indir:
https://play.google.com/store/apps/details?id=com.mmdigital.vaktinde&referrer=utm_source%3Dyoutube%26utm_medium%3Dshorts
```

### 7 Şubat 2027 Pazar · 19:00 · 04_ramazan

Dosyalar: `04_ramazan/post.png`, `story.png`, `video.mp4`

**Instagram / Facebook**
```
Hoş geldin Ya Şehr-i Ramazan.
Bu akşam ilk teravih, yarın (8 Şubat Pazartesi) ilk oruç.
Sahur ve iftar vakitleri, Ramazan imsakiyesi ve geri sayım Vaktinde'de.

Ezan vakti, kıble ve imsakiye için Vaktinde: profildeki bağlantı

#ramazan #hoşgeldinramazan #ramazan2027 #oruç #teravih #imsakiye #iftar #vaktinde
```

**TikTok**
```
Hoş geldin Ya Şehr-i Ramazan. İlk oruç 8 Şubat Pazartesi. Sahur ve iftar vakitleri için Play Store'da Vaktinde ara.
#ramazan #hoşgeldinramazan #oruç #iftar #vaktinde
```

**YouTube Shorts**
- Başlık: `Hoş geldin Ya Şehr-i Ramazan: ilk oruç 8 Şubat 2027 #Shorts`
- Açıklama:
```
Ramazan 8 Şubat 2027 Pazartesi başlıyor; ilk teravih 7 Şubat akşamı. Hoş geldin Ya Şehr-i Ramazan.
Sahur ve iftar vakitleri, Ramazan imsakiyesi ve geri sayım için Vaktinde'yi Google Play'den ücretsiz indir:
https://play.google.com/store/apps/details?id=com.mmdigital.vaktinde&referrer=utm_source%3Dyoutube%26utm_medium%3Dshorts
```

### 5 Mart 2027 Cuma · 20:30 · 05_kadir

Dosyalar: `05_kadir/post.png`, `story.png`, `video.mp4`. Bu Cuma `07_cuma` paylaşılmaz.

**Instagram / Facebook**
```
Bu gece Kadir Gecesi.
"Kadir gecesi bin aydan daha hayırlıdır." (Kadr, 97/3)
Kadir Geceniz mübarek olsun.

Ezan vakti, kıble ve imsakiye için Vaktinde: profildeki bağlantı

#kadirgecesi #ramazan #kandil #dua #ramazan2027 #vaktinde
```

**TikTok**
```
Kadir Geceniz mübarek olsun. Play Store'da Vaktinde ara.
#kadirgecesi #ramazan #dua #vaktinde
```

**YouTube Shorts**
- Başlık: `Kadir Geceniz mübarek olsun #Shorts`
- Açıklama:
```
5 Mart 2027 Cuma gecesi Kadir Gecesi. "Kadir gecesi bin aydan daha hayırlıdır." (Kadr, 97/3)
Namaz vakitleri, kıble ve imsakiye için Vaktinde'yi Google Play'den ücretsiz indir:
https://play.google.com/store/apps/details?id=com.mmdigital.vaktinde&referrer=utm_source%3Dyoutube%26utm_medium%3Dshorts
```

### 9 Mart 2027 Salı · 09:00 · 06_ramazan_bayrami

Dosyalar: `06_ramazan_bayrami/post.png`, `story.png`, `video.mp4`. Hikâye arefe akşamı (8 Mart, 21:00) da paylaşılabilir.

**Instagram / Facebook**
```
Ramazan Bayramınız mübarek olsun.
Rabbim tuttuğumuz oruçları ve ibadetlerimizi kabul eylesin.

Ezan vakti, kıble ve imsakiye için Vaktinde: profildeki bağlantı

#ramazanbayramı #bayram #iyibayramlar #bayramınızmübarekolsun #ramazan #vaktinde
```

**TikTok**
```
Ramazan Bayramınız mübarek olsun. Play Store'da Vaktinde ara.
#ramazanbayramı #bayram #iyibayramlar #vaktinde
```

**YouTube Shorts**
- Başlık: `Ramazan Bayramınız mübarek olsun #Shorts`
- Açıklama:
```
Ramazan Bayramınız mübarek olsun. Rabbim tuttuğumuz oruçları ve ibadetlerimizi kabul eylesin.
Namaz vakitleri, kıble ve imsakiye için Vaktinde'yi Google Play'den ücretsiz indir:
https://play.google.com/store/apps/details?id=com.mmdigital.vaktinde&referrer=utm_source%3Dyoutube%26utm_medium%3Dshorts
```

### Her Cuma · 10:00 · 07_cuma

Dosyalar: `07_cuma/post.png`, `story.png`, `video.mp4`. Tarihsizdir. Tarihler: 4, 11, 18, 25 Aralık; 1, 8, 15, 29 Ocak; 5, 12, 19, 26 Şubat; 12, 19, 26 Mart. 22 Ocak (Berat) ve 5 Mart (Kadir) Cumaları atlanır. Metinler sırayla (A, B, C, D) kullanılır.

**Instagram / Facebook**
```
(A)
Hayırlı Cumalar.
Rabbim dualarımızı kabul eylesin.

Ezan vakti, kıble ve imsakiye için Vaktinde: profildeki bağlantı

#hayırlıcumalar #cuma #cumamesajları #dua #vaktinde
```
```
(B)
Hayırlı Cumalar.
Bugünün öğle vaktini Vaktinde'den kontrol edebilirsin.

Ezan vakti, kıble ve imsakiye için Vaktinde: profildeki bağlantı

#hayırlıcumalar #cuma #namazvakti #ezanvakti #vaktinde
```
```
(C)
Hayırlı Cumalar.
Vaktinde'deki Cuma mesajlarını sevdiklerinle paylaşabilirsin.

Ezan vakti, kıble ve imsakiye için Vaktinde: profildeki bağlantı

#hayırlıcumalar #cuma #cumamesajları #dua #vaktinde
```
```
(D)
Hayırlı Cumalar.
Rabbim dualarımızı kabul eylesin. Bu görseli sevdiklerinle paylaşabilirsin.

Ezan vakti, kıble ve imsakiye için Vaktinde: profildeki bağlantı

#hayırlıcumalar #cuma #dua #cumamesajları #vaktinde
```

**TikTok**
```
Hayırlı Cumalar. Rabbim dualarımızı kabul eylesin. Play Store'da Vaktinde ara.
#hayırlıcumalar #cuma #dua #vaktinde
```

**YouTube Shorts**
- Başlık: `Hayırlı Cumalar #Shorts`
- Açıklama:
```
Hayırlı Cumalar. Rabbim dualarımızı kabul eylesin.
Namaz vakitleri, kıble ve imsakiye için Vaktinde'yi Google Play'den ücretsiz indir:
https://play.google.com/store/apps/details?id=com.mmdigital.vaktinde&referrer=utm_source%3Dyoutube%26utm_medium%3Dshorts
```

---

## Uygulama tanıtımları

### 1 Aralık 2026 Salı · 20:30 · 08_tanitim_ezan (1. tur)

Dosyalar: `08_tanitim_ezan/post.png`, `story.png`, `video.mp4`. Ekran görüntüsü: `ekran/tr_10_home.png`

**Instagram / Facebook**
```
Ezan vakti, saniyesi saniyesine.
Vakitler Diyanet yöntemiyle telefonunda hesaplanır, internet gerekmez.
Ana ekran widget'ıyla sıradaki vakit hep gözünün önünde.

Ezan vakti, kıble ve imsakiye için Vaktinde: profildeki bağlantı

#ezanvakti #namazvakti #ezan #namaz #widget #vaktinde
```

**TikTok**
```
Sıradaki ezana ne kadar kaldı? Saniyesi saniyesine, internetsiz. Play Store'da Vaktinde ara.
#ezanvakti #namazvakti #namaz #vaktinde #keşfet
```

**YouTube Shorts**
- Başlık: `Ezan vakti saniyesi saniyesine: internetsiz namaz vakitleri #Shorts`
- Açıklama:
```
Vaktinde: Diyanet yöntemiyle internetsiz namaz vakitleri, ezan bildirimi, ana ekran widget'ı, kıble pusulası ve imsakiye.
Google Play'den ücretsiz indir:
https://play.google.com/store/apps/details?id=com.mmdigital.vaktinde&referrer=utm_source%3Dyoutube%26utm_medium%3Dshorts
```

### 7 Aralık 2026 Pazartesi · 20:30 · 09_tanitim_kible (1. tur)

Dosyalar: `09_tanitim_kible/post.png`, `story.png`, `video.mp4`. Ekran görüntüsü: `ekran/tr_20_qibla.png`

**Instagram / Facebook**
```
Kıble pusulası cebinde.
Kâbe yönünü, kıble açısını ve hangi yöne döneceğini tek ekranda gösterir.
Doğru sonuç için telefonu metal eşyalardan uzak tut.

Ezan vakti, kıble ve imsakiye için Vaktinde: profildeki bağlantı

#kıble #kıblepusulası #namaz #seyahat #vaktinde
```

**TikTok**
```
Kıble ne tarafta? Telefonunu çevir, pusula göstersin. Play Store'da Vaktinde ara.
#kıble #kıblepusulası #namaz #vaktinde #keşfet
```

**YouTube Shorts**
- Başlık: `Kıble pusulası cebinde: Kâbe yönünü bul #Shorts`
- Açıklama:
```
Vaktinde'nin kıble pusulası Kâbe yönünü, kıble açısını ve dönüş yönünü gösterir; manyetik sapmayı düzeltir, parazitte uyarır.
Google Play'den ücretsiz indir:
https://play.google.com/store/apps/details?id=com.mmdigital.vaktinde&referrer=utm_source%3Dyoutube%26utm_medium%3Dshorts
```

### 15 Aralık 2026 Salı · 20:30 · 10_tanitim_zikirmatik (1. tur)

Dosyalar: `10_tanitim_zikirmatik/post.png`, `story.png`, `video.mp4`. Ekran görüntüsü: `ekran/tr_30_zikirmatik.png`

**Instagram / Facebook**
```
Zikirmatik: tesbih her an yanında.
Zikrini seç, hedefini belirle, ekrana dokunarak say.
Üç Aylar boyunca zikirlerini Vaktinde ile takip et.

Ezan vakti, kıble ve imsakiye için Vaktinde: profildeki bağlantı

#zikirmatik #tesbih #zikir #üçaylar #vaktinde
```

**TikTok**
```
Tesbihin yanında değilse telefonun yanında. Play Store'da Vaktinde ara.
#zikirmatik #tesbih #zikir #vaktinde #keşfet
```

**YouTube Shorts**
- Başlık: `Zikirmatik: tesbih her an yanında #Shorts`
- Açıklama:
```
Vaktinde Zikirmatik: hazır zikirler, hedef sayısı, tur ve istatistik. Ekrana dokun, say.
Google Play'den ücretsiz indir:
https://play.google.com/store/apps/details?id=com.mmdigital.vaktinde&referrer=utm_source%3Dyoutube%26utm_medium%3Dshorts
```

### 22 Aralık 2026 Salı · 20:30 · 12_tanitim_takip_kaza (1. tur)

Dosyalar: `12_tanitim_takip_kaza/post.png`, `story.png`, `video.mp4`. Ekran görüntüleri: `ekran/tr_47_prayer_tracker.png`, `ekran/tr_46_kaza_calc.png`

**Instagram / Facebook**
```
Namaz takibi ve kaza hesaplama.
Kıldığın vakitleri işaretle, serini ve 30 günlük oranını gör.
Kılınmayan yılları gir, tahmini kaza sayını hesapla ve kaza takibine ekle.

Ezan vakti, kıble ve imsakiye için Vaktinde: profildeki bağlantı

#namaztakibi #kazanamazı #namaz #kaza #vaktinde
```

**TikTok**
```
Kaç vakit kaza namazın var? Hesapla, kıldıkça düş. Play Store'da Vaktinde ara.
#kazanamazı #namaztakibi #namaz #vaktinde #keşfet
```

**YouTube Shorts**
- Başlık: `Namaz takibi ve kaza namazı hesaplama #Shorts`
- Açıklama:
```
Vaktinde ile günlük namaz takibi, seri ve 30 günlük oran; kaza hesaplama ve kaza namazı/oruç sayacı.
Google Play'den ücretsiz indir:
https://play.google.com/store/apps/details?id=com.mmdigital.vaktinde&referrer=utm_source%3Dyoutube%26utm_medium%3Dshorts
```

### 29 Aralık 2026 Salı · 20:30 · 13_tanitim_kuran (1. tur)

Dosyalar: `13_tanitim_kuran/post.png`, `story.png`, `video.mp4`. Ekran görüntüsü: `ekran/tr_70_quran_list.png`

**Instagram / Facebook**
```
Kur'an-ı Kerim: kaldığın yerden devam.
Mushaf sayfası, Türkçe meal ve yer imi.
Uygulama nerede kaldığını hatırlar, tek dokunuşla devam edersin.

Ezan vakti, kıble ve imsakiye için Vaktinde: profildeki bağlantı

#kuranıkerim #kuran #meal #hatim #vaktinde
```

**TikTok**
```
Kur'an okurken nerede kaldığını unutma. Play Store'da Vaktinde ara.
#kuranıkerim #kuran #meal #vaktinde #keşfet
```

**YouTube Shorts**
- Başlık: `Kur'an-ı Kerim: kaldığın yerden devam et #Shorts`
- Açıklama:
```
Vaktinde'de Kur'an-ı Kerim: mushaf sayfası, Türkçe meal, yer imi ve kaldığın yerden devam.
Google Play'den ücretsiz indir:
https://play.google.com/store/apps/details?id=com.mmdigital.vaktinde&referrer=utm_source%3Dyoutube%26utm_medium%3Dshorts
```

### 7 Ocak 2027 Perşembe · 20:30 · 08_tanitim_ezan (2. tur)

**Instagram / Facebook**
```
Ezanı kaçırma.
Her vakit için ezan sesi ya da sessiz bildirim seç; vakitten önce hatırlatma kur.
"Sessiz modda da çal" ile telefon sessizdeyken de ezanı duy.

Ezan vakti, kıble ve imsakiye için Vaktinde: profildeki bağlantı

#ezan #ezanvakti #namazvakti #bildirim #vaktinde
```

**TikTok**
```
Telefon sessizde olsa da ezanı duy. Play Store'da Vaktinde ara.
#ezan #ezanvakti #namazvakti #vaktinde
```

**YouTube Shorts**
- Başlık: `Ezan vaktini kaçırma: ezan bildirimi ve hatırlatma #Shorts`
- Açıklama:
```
Vaktinde: her vakit için ayrı ezan sesi, vakitten önce hatırlatma, "Sessiz modda da çal" ve ana ekran widget'ı.
Google Play'den ücretsiz indir:
https://play.google.com/store/apps/details?id=com.mmdigital.vaktinde&referrer=utm_source%3Dyoutube%26utm_medium%3Dshorts
```

### 11 Ocak 2027 Pazartesi · 20:30 · 11_tanitim_imsakiye (1. tur)

Dosyalar: `11_tanitim_imsakiye/post.png`, `story.png`, `video.mp4`. Ekran görüntüsü: `ekran/tr_41_imsakiye_ramazan.png`

**Instagram / Facebook**
```
Ramazan 2027 imsakiyesi hazır.
8 Şubat – 8 Mart 2027: bulunduğun yerin imsak ve iftar vakitleri gün gün.
İmsakiyeyi resim olarak paylaş; Ramazan'da sahur ve iftar geri sayımı ana ekranda.

Ezan vakti, kıble ve imsakiye için Vaktinde: profildeki bağlantı

#imsakiye #ramazan2027 #ramazan #iftar #sahur #vaktinde
```

**TikTok**
```
Ramazan 2027 imsakiyesi hazır: 8 Şubat – 8 Mart. Play Store'da Vaktinde ara.
#imsakiye #ramazan2027 #ramazan #iftar #vaktinde
```

**YouTube Shorts**
- Başlık: `Ramazan 2027 imsakiyesi hazır: sahur ve iftar vakitleri #Shorts`
- Açıklama:
```
Vaktinde'de Ramazan 2027 (8 Şubat – 8 Mart) imsakiyesi: il ve ilçene göre imsak ve iftar vakitleri, sahur ve iftar geri sayımı.
Google Play'den ücretsiz indir:
https://play.google.com/store/apps/details?id=com.mmdigital.vaktinde&referrer=utm_source%3Dyoutube%26utm_medium%3Dshorts
```

### 19 Ocak 2027 Salı · 20:30 · 12_tanitim_takip_kaza (2. tur)

**Instagram / Facebook**
```
Ramazan yaklaşırken kaza namazlarını planlamaya ne dersin?
Kaza hesapla: kılınmayan süreyi gir, tahmini sayıyı gör.
Kıldıkça sayaçtan düş, kaç vakit kaldığını hep bil.

Ezan vakti, kıble ve imsakiye için Vaktinde: profildeki bağlantı

#kazanamazı #kaza #namaz #üçaylar #vaktinde
```

**TikTok**
```
Kaza namazlarını say, kıldıkça düş. Play Store'da Vaktinde ara.
#kazanamazı #namaz #üçaylar #vaktinde
```

**YouTube Shorts**
- Başlık: `Kaza namazı hesaplama ve takibi #Shorts`
- Açıklama:
```
Vaktinde'de kaza hesapla: kılınmayan süreden tahmini kaza sayısı, her vakit için ayrı sayaç ve oruç kazası.
Google Play'den ücretsiz indir:
https://play.google.com/store/apps/details?id=com.mmdigital.vaktinde&referrer=utm_source%3Dyoutube%26utm_medium%3Dshorts
```

### 26 Ocak 2027 Salı · 20:30 · 13_tanitim_kuran (2. tur)

**Instagram / Facebook**
```
Ramazan'dan önce Kur'an'la bağını güçlendir.
Her gün birkaç sayfa oku; Vaktinde kaldığın yeri hatırlar.
Sureler ve cüzler listesi, yer imi, Türkçe meal.

Ezan vakti, kıble ve imsakiye için Vaktinde: profildeki bağlantı

#kuranıkerim #kuran #ramazan #meal #vaktinde
```

**TikTok**
```
Her gün birkaç sayfa: kaldığın yerden devam. Play Store'da Vaktinde ara.
#kuranıkerim #kuran #ramazan #vaktinde
```

**YouTube Shorts**
- Başlık: `Her gün Kur'an: kaldığın yerden devam #Shorts`
- Açıklama:
```
Vaktinde'de Kur'an-ı Kerim: sureler ve cüzler, mushaf sayfası, Türkçe meal, yer imi ve kaldığın yerden devam.
Google Play'den ücretsiz indir:
https://play.google.com/store/apps/details?id=com.mmdigital.vaktinde&referrer=utm_source%3Dyoutube%26utm_medium%3Dshorts
```

### 1 Şubat 2027 Pazartesi · 20:30 · 11_tanitim_imsakiye (2. tur)

**Instagram / Facebook**
```
Ramazan'a 1 hafta kaldı.
İlk oruç 8 Şubat Pazartesi. İmsakiyen hazır mı?
Bulunduğun yerin sahur ve iftar vakitleri Vaktinde'de.

Ezan vakti, kıble ve imsakiye için Vaktinde: profildeki bağlantı

#ramazan #ramazan2027 #imsakiye #oruç #iftar #sahur #vaktinde
```

**TikTok**
```
Ramazan'a 1 hafta: imsakiyen hazır mı? Play Store'da Vaktinde ara.
#ramazan #imsakiye #iftar #sahur #vaktinde
```

**YouTube Shorts**
- Başlık: `Ramazan'a 1 hafta: 2027 imsakiyesi #Shorts`
- Açıklama:
```
Ramazan 8 Şubat 2027 Pazartesi başlıyor. Vaktinde'de bulunduğun yerin imsakiyesi, sahur ve iftar geri sayımı.
Google Play'den ücretsiz indir:
https://play.google.com/store/apps/details?id=com.mmdigital.vaktinde&referrer=utm_source%3Dyoutube%26utm_medium%3Dshorts
```

### 10 Şubat 2027 Çarşamba · 21:30 · 08_tanitim_ezan (3. tur)

**Instagram / Facebook**
```
Sahura kaç dakika kaldı?
Sıradaki vakte geri sayım hem uygulamada hem ana ekran widget'ında.
Vakitler internetsiz hesaplanır; telefonun çekmediği yerde de çalışır.

Ezan vakti, kıble ve imsakiye için Vaktinde: profildeki bağlantı

#ramazan #sahur #iftar #ezanvakti #vaktinde
```

**TikTok**
```
Sahura ve iftara geri sayım, internetsiz. Play Store'da Vaktinde ara.
#ramazan #sahur #iftar #ezanvakti #vaktinde
```

**YouTube Shorts**
- Başlık: `Sahur ve iftar vakti: internetsiz geri sayım #Shorts`
- Açıklama:
```
Vaktinde: Diyanet yöntemiyle internetsiz namaz vakitleri, sıradaki vakte geri sayım ve ana ekran widget'ı.
Google Play'den ücretsiz indir:
https://play.google.com/store/apps/details?id=com.mmdigital.vaktinde&referrer=utm_source%3Dyoutube%26utm_medium%3Dshorts
```

### 16 Şubat 2027 Salı · 21:30 · 10_tanitim_zikirmatik (2. tur)

**Instagram / Facebook**
```
Teravihten sonra tesbihatını Zikirmatik ile yap.
Zikrini seç, hedefini belirle, ekrana dokunarak say.
Günlük istatistikle Ramazan boyunca zikirlerini takip et.

Ezan vakti, kıble ve imsakiye için Vaktinde: profildeki bağlantı

#zikirmatik #tesbih #zikir #ramazan #vaktinde
```

**TikTok**
```
Teravih sonrası tesbihat için zikirmatik. Play Store'da Vaktinde ara.
#zikirmatik #tesbih #ramazan #vaktinde
```

**YouTube Shorts**
- Başlık: `Ramazan'da zikirmatik: hedef, tur, istatistik #Shorts`
- Açıklama:
```
Vaktinde Zikirmatik: hazır zikirler, hedef sayısı, tur ve günlük istatistik.
Google Play'den ücretsiz indir:
https://play.google.com/store/apps/details?id=com.mmdigital.vaktinde&referrer=utm_source%3Dyoutube%26utm_medium%3Dshorts
```

### 23 Şubat 2027 Salı · 21:30 · 13_tanitim_kuran (3. tur)

**Instagram / Facebook**
```
Ramazan'da Kur'an okumaya ara verdiysen sorun değil, kaldığın yerden devam et.
Mushaf sayfası, Türkçe meal ve yer imi Vaktinde'de.

Ezan vakti, kıble ve imsakiye için Vaktinde: profildeki bağlantı

#kuranıkerim #ramazan #mukabele #hatim #vaktinde
```

**TikTok**
```
Ramazan'da Kur'an: kaldığın yerden devam. Play Store'da Vaktinde ara.
#kuranıkerim #ramazan #mukabele #vaktinde
```

**YouTube Shorts**
- Başlık: `Ramazan'da Kur'an: kaldığın yerden devam #Shorts`
- Açıklama:
```
Vaktinde'de Kur'an-ı Kerim: mushaf sayfası, Türkçe meal, yer imi ve kaldığın yerden devam.
Google Play'den ücretsiz indir:
https://play.google.com/store/apps/details?id=com.mmdigital.vaktinde&referrer=utm_source%3Dyoutube%26utm_medium%3Dshorts
```

### 1 Mart 2027 Pazartesi · 21:30 · 09_tanitim_kible (2. tur)

**Instagram / Facebook**
```
İftar davetinde ya da yolculukta kıble ne tarafta?
Vaktinde'nin kıble pusulası Kâbe yönünü ve dönüş yönünü gösterir.

Ezan vakti, kıble ve imsakiye için Vaktinde: profildeki bağlantı

#kıble #kıblepusulası #ramazan #namaz #vaktinde
```

**TikTok**
```
Misafirlikte kıbleyi bulmanın kolay yolu. Play Store'da Vaktinde ara.
#kıble #kıblepusulası #ramazan #vaktinde
```

**YouTube Shorts**
- Başlık: `Misafirlikte kıble nerede? Kıble pusulası #Shorts`
- Açıklama:
```
Vaktinde'nin kıble pusulası Kâbe yönünü, kıble açısını ve dönüş yönünü gösterir; manyetik sapmayı düzeltir.
Google Play'den ücretsiz indir:
https://play.google.com/store/apps/details?id=com.mmdigital.vaktinde&referrer=utm_source%3Dyoutube%26utm_medium%3Dshorts
```

### 14 Mart 2027 Pazar · 20:30 · 12_tanitim_takip_kaza (3. tur)

**Instagram / Facebook**
```
Ramazan bitti, namaz takibi sürsün.
Kıldığın vakitleri işaretle, seriyi koru.
Tutamadığın oruçları kaza sayacına ekle, tuttukça düş.

Ezan vakti, kıble ve imsakiye için Vaktinde: profildeki bağlantı

#namaztakibi #kazaorucu #kazanamazı #namaz #vaktinde
```

**TikTok**
```
Ramazan bitti, seri devam. Play Store'da Vaktinde ara.
#namaztakibi #kazaorucu #namaz #vaktinde
```

**YouTube Shorts**
- Başlık: `Ramazan sonrası namaz takibi ve kaza orucu #Shorts`
- Açıklama:
```
Vaktinde ile günlük namaz takibi, seri ve 30 günlük oran; kaza namazı ve oruç sayacı.
Google Play'den ücretsiz indir:
https://play.google.com/store/apps/details?id=com.mmdigital.vaktinde&referrer=utm_source%3Dyoutube%26utm_medium%3Dshorts
```

### 18 Mart 2027 Perşembe · 20:30 · 10_tanitim_zikirmatik (3. tur)

**Instagram / Facebook**
```
Zikirmatik: tesbih her an yanında.
Yolda, işte, evde; telefonun yanındaysa tesbihin de yanında.

Ezan vakti, kıble ve imsakiye için Vaktinde: profildeki bağlantı

#zikirmatik #tesbih #zikir #namaz #vaktinde
```

**TikTok**
```
Tesbih her an yanında. Play Store'da Vaktinde ara.
#zikirmatik #tesbih #zikir #vaktinde
```

**YouTube Shorts**
- Başlık: `Zikirmatik: tesbih her an yanında #Shorts`
- Açıklama:
```
Vaktinde Zikirmatik: hazır zikirler, hedef sayısı, tur ve istatistik.
Google Play'den ücretsiz indir:
https://play.google.com/store/apps/details?id=com.mmdigital.vaktinde&referrer=utm_source%3Dyoutube%26utm_medium%3Dshorts
```

### 23 Mart 2027 Salı · 20:30 · 09_tanitim_kible (3. tur)

**Instagram / Facebook**
```
Kıble pusulası cebinde.
Yeni bir şehirde, otelde ya da iş yerinde Kâbe yönünü kolayca bul.

Ezan vakti, kıble ve imsakiye için Vaktinde: profildeki bağlantı

#kıble #kıblepusulası #seyahat #namaz #vaktinde
```

**TikTok**
```
Otelde kıble ne tarafta? Play Store'da Vaktinde ara.
#kıble #kıblepusulası #seyahat #vaktinde
```

**YouTube Shorts**
- Başlık: `Seyahatte kıble yönü: kıble pusulası #Shorts`
- Açıklama:
```
Vaktinde'nin kıble pusulası Kâbe yönünü, kıble açısını ve dönüş yönünü gösterir.
Google Play'den ücretsiz indir:
https://play.google.com/store/apps/details?id=com.mmdigital.vaktinde&referrer=utm_source%3Dyoutube%26utm_medium%3Dshorts
```
