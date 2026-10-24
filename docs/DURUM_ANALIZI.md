# Vaktinde — Durum (Play'de 1.3.0+18; 1.4.0+19 bu dalda hazır, yayın bekliyor — 24 Ekim 2026)

## SON DURUM — 1.4.0+19 (23 Ekim 2026)
- Kod işleri bitti (tek güncelleme: 1.3.1 ve 1.4.0 birleşti). İçerik:
  · Kalıcı bildirim ön plan servisinden ayrıldı (flutter_background_service yok; specialUse FGS beyanı kalkar), widget
    yenilemesi güçlendi (alarm saati kipinde ezanla aynı dakika, gecikme Bildirim Kontrolü'nde).
  · Zikirmatik 35 hazır zikir; Dualar 87 (10 kategori, arama); ayrı Hatim ekranı (Okudum, cüz ızgarası, niyet, toplu
    hatim, hatim duası); Kıssalar (49: 25 peygamber, siyer, sahabe, âlimler).
  · Kur'an dinleme ASKIDA (24 Ekim, kullanıcı kararı: QF üretim onayı + Cloudflare + Play mediaPlayback beyanı
    istenmedi; talep gelirse). Uygulamadan çıkarıldı (ses/FGS yok); kod git geçmişinde ve server/quran-audio'da.
  · Günün hadisi: arka planda ağ yokken her gün aynı yedek hadis ("Ameller niyetlere göredir") bildirime giriyordu →
    düzeltildi. Kalıcı bildirimde 6 vakit. Kur'an okuyucuda kaydırarak sonraki/önceki sure; zekâtta binlik ayraç.
- DİNÎ İÇERİK: Arapça metinler kaynakla (Tanzil, sunnah.com verisi) harf harf doğrulandı. 23 Ekim: kullanıcı hoca
  bulamadı → Türkçe anlam/not/kıssalar Diyanet İşleri + Diyanet Vakfı mealleri, Kütüb-i Sitte Türkçe çevirileri ve
  TDV İslâm Ansiklopedisi ile karşılaştırıldı (6 bağımsız kontrol, her bulgu kaynağında yeniden doğrulandı); düzeltmeler
  5 dilde yapıldı (Ebû Bekir hadisi "üçüncüleri", Hatice 620, Esmâ El-Hakem Arapçası — 1.3.0'da da yanlıştı —, Namaz
  Hocası zamm-ı sûre vb.). Güncel inceleme PDF'i kullanıcıda; bir din görevlisinin son bakışı yine tavsiye edilir.
- YAYIN SIRASI (kullanıcı):
  1. (İsteğe bağlı) din görevlisine inceleme PDF'i; gelen düzeltmeler 5 dile işlenir.
  2. docs/gizlilik_politikasi.md → Google Sites'a yapıştır (ses bölümü ve posta adresi satırı çıkarıldı).
  3. CollectAPI anahtarını yenile → `flutter build appbundle --release --dart-define=COLLECT_API_KEY=<yeni>`.
  4. Play Console > Uygulama içeriği > Ön plan hizmetleri: specialUse beyanını kaldır (uygulamada artık ön plan hizmeti
     yok). Veri güvenliği: yeni toplanan/paylaşılan veri yok.
  5. Dahili test, cihazda: kalıcı bildirim (6 vakit sığıyor mu) (FGS yok: aç/kapat, telefon yeniden başlayınca, güncellemeden sonra), widget'lar,
     bildirime dokunma (uygulamadan geri tuşuyla çıktıktan sonra da), Hatim ekranı, dua arama, kıssalar, zikir listesi,
     yedekle/geri yükle, 1.3.0 üstüne kurulumda Yenilikler.
  6. ✅ Sürüm notları docs/surum_notlari_1.4.0.txt (5 dil, ≤500) ve mağaza metni docs/magaza_girisi.md (24 Ekim: tr kısa
     açıklama, Hatim/kaydırma/87 dua/35 zikir/Kıssalar/kalıcı bildirim satırları, 5 dilde kayıtların telefonda kaldığı
     cümlesi; fr 3992/4000). Play'e: ana giriş + çeviriler + Avrupa özel girişinin tam açıklaması; görseller isteğe bağlı → üretim.

## 1.3.0 dönemi (17 Ekim 2026)
- Kod işleri bitti; dal `claude/vaktinde-app-analysis-bocjca` = 1.3.0 adayı (pubspec hâlâ 1.2.0+17). Tüm testler geçiyor
  (919 + 34 ekran görüntüsü), analyze temiz. Kullanıcı telefonda denedi: 0–3 ve önceki işler sorunsuz; 14 Ekim'de son
  hâli debug'da açtı, genel görünüm sorunsuz. Şehir listesi, Namaz Hocası ve yeni widget'lar henüz ayrıntılı denenmedi.
- 16-17 Ekim eklenenler (1.3.0'a girer, cihazda denenecek): Ayarlar sadeleşti (Bildirim Ayarları + Gizlilik ve Reklamlar
  alt sayfaları), uygulama içi yazı boyutu (Normal/Büyük/Çok büyük), Araçlar kutucuk ızgarası, Namaz Takibi + Kaza tek ekran
  (sekmeler), 7/40 gün seri hedefleri, Cuma bildirimi (Cuma 09:00, Kehf düğmesi; bildirime dokununca ilgili ekran açılır),
  Hatim takibi (Kur'an kartı, günlük hedef, okuyucuda otomatik sayfa, Sayfa Gir, isteğe bağlı hatırlatma, "Bugün için"
  satırı), zikirde "Bugün: N". Yenilikler ve Uygulamayı Tanı güncellendi. code-review bulguları düzeltildi.
  Debug'da zekat canlı kuru gelmez (COLLECT_API_KEY derlemede verilir; normal).
- 17 Ekim: sade arka planlar (6) eklendi; tanıtım paketi üretildi ve kullanıcıya gönderildi (Play 5 dil 8 ekran + öne çıkan
  görsel, Instagram 2 üçlü ızgara + karusel + 3 hikâye, 19 sn dikey/yatay video; docs/marketing/make_store_assets.py).
- YAYIN: kullanıcı zamanını kendisi söyleyecek, adım adım yapılacak. Yayın günü sırası:
  1. ✅ pubspec `1.3.0+18` (17 Ekim); 2. ✅ sürüm notları docs/surum_notlari_1.3.0.txt (5 dil, ≤500; gizlilik metni de
  güncel: Gizlilik ve Reklamlar yolu, hatim/yazı boyutu); 3. CollectAPI anahtarını yenile (eskisi git
  geçmişinde açık; önce değil, yayındaki 1.2.0'ın canlı kuru durur) → `flutter build appbundle --release
  --dart-define=COLLECT_API_KEY=<yeni>`; 4. dahili test, cihazda: R8 + kaynak küçültme (release), iki yeni widget
  (takipte uygulama kapalıyken dokunma, halka vakitte sıfırlanma, gece yarısı), ezan "Durdur" (kilit ekranı, sessiz kopya +
  Kıldım), özel gün dönemi + sessiz ezan, şehir listesi (il/ilçe, Avrupa, saat dilimi uyarısı), Namaz Hocası, Kur'an
  kipleri/kart, yedekle/geri yükle, AB rıza formu, kaza hesapla, kalıcı bildirim aç/kapat (yeni kurulumda kapalı, telefon
  yeniden başlayınca), ilk reklam fırsatında "Reklamlar hakkında", 1.2.0 üstüne kurulumda Yenilikler, ipuçları, Uygulamayı
  Tanı + turu tekrar izle, Play'deki indirme boyutu, Ayarlar alt sayfaları, yazı boyutu, Araçlar kutucukları, Takip/Kaza
  sekmeleri ve seri hedefi, Cuma bildirimi (uygulama kapalıyken gövdeye ve "Kehf Suresi"ne dokunma), hatim (Devam Et,
  kaydırınca sayfa sayımı, Sayfa Gir, hatırlatma: hedef tamamlanan gün çalmamalı); 5. docs/gizlilik_politikasi.md → Google Sites'a yapıştır (kalıcı
  bildirim isteğe bağlı, ilk açılış izin sonucu olayları); 6. üretim.
- 1.3.0 içeriği (1.2.0'dan beri): eksi sayaç kalıcı çözümü (setTimeoutAfter + 15 dk onarım işi), widget 12 saat/kontrast,
  Ramazan widget'ı, vakit halkası + namaz takibi widget'ları, yedekle/geri yükle, AB Consent Mode v2, erişilebilirlik
  (%200, TalkBack), Kur'an (alt menü sekmesi, sayfa/ayet/meal, cüzler, kaldığın yer), Dualar + tesbihat, Namaz Hocası,
  fitre/fidye + oruç takibi, özel gün dönemi + sessiz ezan, kaza hesapla, "Bugün için" merkezi, zikirmatik halka/tur/ses
  tuşları, kıble titreşimi, ezan "Durdur", günün ayeti/hadisi gün boyu sabit, internetsiz şehir listesi, paylaşım
  kartları/tebrikler, reklam sıklığı (4 dk, günde 8; ibadet ekranları reklamsız).
- Gizlilik politikası 12 Ekim'de güncellendi (yedek, Kur'an/alquran.cloud, fitre GitHub Pages, AB rıza); 1.3.0'daki yeni
  işler yeni veri akışı eklemiyor. Şehir verisi ODbL/CC BY atfı uygulamanın lisans sayfasında.
- Bekleyen (kullanıcı kararıyla): açılış reklamı (AdMob birimi gerekir), "memleket vakitleri". Kotlin/Robolectric düzeneği scratchpad'de (oturum kapanınca kaybolur; gerekirse yeniden kurulur).
- 14 Ekim 2026 eklenenler (1.3.0'a girer, cihazda denenecek): ses kopyaları kaldırıldı (~12,7 MB; önizleme res/raw'dan),
  Poppins ExtraBold/Black kaldırıldı; kalıcı bildirim isteğe bağlı (yeni kurulumda kapalı); ilk 24 saat geçiş reklamı yok;
  "Reklamlar Hakkında" (ilk fırsatta reklam yerine bir kez + Ayarlar); ilk açılış hunisi olayları; Consent Mode manifest
  varsayılanı kapalı; tur 8 adım, ilk ziyaret ipuçları, Yenilikler, Uygulamayı Tanı. R8 optimizedResourceShrinking EKLENMEDİ
  (AGP 8.11'de belirsiz + Firebase'in adla okuduğu kaynakları silme riski). Gizlilik metni güncellendi → Google Sites'a da.
- Play Console bulguları (14 Ekim 2026) → sıradaki işler (kullanıcı onayıyla):
  · Kilitlenmeler sadece 1.0.0'da (ForegroundServiceDidNotStartInTime + flutter_background_service; sonraki sürümlerde
    düzeltildi) — eski sürümde kalan birkaç cihaz. GEKS/AEKS %28,7 (iyi). Kaldırmalar Ekim'de günde 2–5: yeni gelenlerin
    çoğu siliyor → tahmin: her zaman açık kalıcı bildirim, izin pencereleri, reklam, boyut.
  · Crashlytics (7 gün): kıble _deg NaN (sadece 1.1.0; 1.2.0'da qibla_view `!raw.isFinite` koruması var), arka plan
    resmi yüklenemedi (1.1.0–1.1.2; 1.2.0'da validBackground + errorBuilder), libflutter.so bulunamadı (1.2.0, 1 kişi:
    Play dışı/eksik parçalı kurulum, koddan çözülmez), flutter_background_service BootReceiver açılışta ön plan servisi
    zamanında başlamadı (1.2.0, 1 kişi) → ön plan servisini isteğe bağlı yapma işiyle çözülür.
  · BOYUT 45,8 MB (benzer ortanca 36): ezan/bildirim sesleri iki kez paketleniyor — android/app/src/main/res/raw ve
    assets/sounds aynı 11 dosya (~12,4 MB). Önizleme (home_view_model AssetSource('sounds/..')) res/raw'dan çalınırsa
    (ör. 'vaktinde/device' kanalı MediaPlayer.create(R.raw.x)) assets/sounds'tan sadece click.mp3 kalır → ~33 MB.
  · Ön plan servisini (kalıcı bildirim) isteğe bağlı yapma işi öne alınmalı (kaldırma sebebi adayı).
  · Play önerileri (1.2.0): "uçtan uca ekran tüm kullanıcılara gösterilmeyebilir" (enableEdgeToEdge zaten çağrılıyor;
    1.3.0 sonrası kalıyor mu bakılacak); "desteği sonlandırılmış API'ler" (setStatusBarColor/NavigationBarColor/Divider,
    LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES — Flutter motoru + androidx içinden, Android 15'te etkisiz; dokunulmuyor);
    R8: "optimize edilmiş kaynak küçültme etkin değil" → android/gradle.properties `android.r8.optimizedResourceShrinking=true`
    (AGP 8.11.1 destekliyor; release cihaz testi şart), "AGP 9.0" → Flutter uyumu belirsiz, şimdilik hayır.
  · Mağaza girişi (28 gün, 10 Eki'ye kadar): 99 ziyaretçi, 39 yükleme tıklaması, dönüşüm %39 (iyi).
  · Edinme kaynağı (28 gün): 50 yükleme = doğrudan/dış bağlantı 26 (9 Eki sıçraması; sosyal medya), Play keşfet 15
    (+%200; 90 günde +31), ilişkilendirilmemiş 9. 90 günlük mağaza dönüşümü %28,5. Yer: Kullanıcı sayısını artırın →
    Edinme kartı; "Daha ayrıntılı bilgi" → UTM kırılımı (bio etiketleri 12 Eki'den itibaren).
  · ASO: mağaza görselleri (başlıklı, telefon çerçeveli), "imsakiye/ramazan" anahtar kelimeli özel giriş (Ocak),
    Ocak–Mart kısa açıklama Ramazan odaklı, Promosyon içeriği başvurusu 2–3 hafta önce, yorumlara cevap.
- Sosyal medya: hesaplar ve içerik paketi hazır (docs/BUYUME_PLANI.md, docs/marketing/), takvim 1 Aralık'ta başlıyor.
  Aralık başı: mağaza görselleri + Play Promosyon içeriği (Üç Aylar 10.12, Ramazan 8.2.2027). Avrupa özel mağaza girişi %50
  → birkaç hafta sonra karşılaştır, %100. 2027 fitre tutarı açıklanınca docs/site/fitre.json'a girdi.

## 1.3.0 öncesi sıradakiler (kullanıcı onayıyla; 1.3.0 bunlar bitince yayınlanır)
Kod (önerilen sıra):
0–3 ✅ (13 Ekim 2026, cihazda denenecek): günün ayeti/hadisi gün boyu sabit; ezanda "Durdur"; özel gün dönemi
   (başladı/bitti, en fazla 10 gün) + özel günde sessiz ezan (ayar, varsayılan açık); "Kaza hesapla" sihirbazı.
4. Uygulama açılış reklamı — kullanıcı AdMob'da "Uygulama açılışı" birimi açarsa (dönüşte, günde 1–2).
5. ✅ İnternetsiz il/ilçe + Avrupa/KKTC şehirleri (13 Ekim 2026). "Memleket vakitleri" (başka saat diliminde gösterim) yapılmadı.
6. ✅ Yeni widget'lar: vakit halkası + uygulama açılmadan işaretlenen namaz takibi (13 Ekim 2026; cihazda denenecek,
   Robolectric testleri scratchpad h_widgets2'de).
7. ✅ Namaz Hocası (13 Ekim 2026).
8. Ön plan servisini isteğe bağlı yapma (M).
Kullanıcı işleri ✅ (12 Ekim 2026): Google Sites gizlilik metni güncellendi, fitre.json mahir2772.github.io'da, AdMob
GDPR mesajı yayında ("Vaktinde GDPR"; Reddet düğmesi tüm ülkelerde; eski taslak hiç yayınlanmamıştı) + hassas/kısıtlı
kategoriler engellendi, Play Veri güvenliğinde Crashlytics (kilitlenme günlüğü, teşhis) zaten beyanlı.
Özel mağaza girişi "Avrupa" (DE, AT, BE, FR, NL, CH, DK, SE, GB; kitle %50, kısa açıklamalar "Avrupa'da Diyanet yöntemiyle…"
tr/de/fr/en, ar aynı) incelemeye gitti; birkaç hafta sonra varsayılanla karşılaştır → %100 (yüzde azaltılamaz).
Kalan: CollectAPI anahtarını 1.3.0 derleme günü yenile (önce değil: 1.2.0'ın canlı kuru durur), mağaza görselleri (Aralık
başı Üç Aylar, ~11 Ocak Ramazan 2027 İmsakiye) + aynı anda Play "Promosyon içeriği" etkinlikleri (Üç Aylar,
Ramazan) ve özel mağaza girişleri (sosyal medya URL'li giriş: indirme ölçümü; AB ülkeleri girişi, tüm dil çevirileriyle),
2027 fitre tutarı açıklanınca fitre.json'a girdi. Üç Aylar 10.12.2026 →
1.3.0 en geç Kasım sonu.

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
- AdMob: AB GDPR mesajı 12 Ekim 2026'da yayınlandı (öncesinde sadece taslak vardı).

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
1. ~~Bildirim sağlık ekranı~~ (1.2.0'da yapıldı: Bildirim Kontrolü) (M): bildirim/tam zamanlı alarm izni, pil, ses ve Rahatsız Etmeyin, sıradaki alarmın saati,
   "1 dk sonra test ezanı"; üretici rehberi (Xiaomi otomatik başlatma, Honor/Huawei, Oppo/Realme, Vivo, Samsung; dontkillmyapp);
   WorkManager son koşu kaydı 12–24 sa eskiyse "uygulama öldürülüyor" uyarısı. Ayarlar'daki "Bildirim Gelmiyor mu?" diyaloğunun yerine.
2. ~~Kandil / Üç Aylar bildirimleri~~ (1.2.0'da yapıldı) (S–M): `religious_days.json`'dan — Üç Aylar + Regaib 10.12.2026, Miraç 04.01.2027,
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

## v1.2.0 (17) ✅ (Crashlytics + Android vitals bulguları ve yol haritası 1–2)
| Konu | Çözüm |
|---|---|
| Crashlytics "Unable to load asset: backgrounds/bg…" (%88,9 çökmesiz) | Eski .jpg arka plan kaydı .webp'e taşınır, listede olmayan (bg_quran) silinir; resim açılamazsa tema rengi. Flutter/Dart hataları artık ölümcül değil (çökme sayılmaz) |
| Kandil / dini gün bildirimleri | 10:00, Ramazan bir gün önce, bayramda arefe + 1. gün; ayar anahtarı; json'da 2025 Üç Aylar (1 Ocak) ve 2028 Kadir (22 Şubat, Diyanet'le teyit edilmeli) düzeltildi |
| Bildirim Kontrolü ekranı | İzinler, pil, Rahatsız Etmeyin, ses, açık ezan, sıradaki ezan, arka plan (48 sa), üretici rehberi, 1 dk test ezanı |
| Yakındaki Camiler | Harita uygulamasında arama (global, API anahtarı yok) |
| Uçtan uca ekran (Play önerisi) | FlutterFragmentActivity + enableEdgeToEdge; Android 15+ 3 tuşlu gezinmede alt sayfaların son satırı gezinme çubuğu altında kalıyordu (dil, görünüm, kıble ipuçları, ayet/hadis okuma) → düzeltildi |
| Kaynak küçültme (Play R8 önerisi) | isShrinkResources + res/raw/keep.xml (ezan sesleri, bildirim simgesi) |
| Kaza: "Kılınmayanları kazaya ekle" sonrası vakitler hep kaza kalıyordu (Kaza Takibi'nden düşmek işareti değiştirmiyordu) | Takipte kaza hücresine dokununca kılındı olur ve kaza sayacı bir azalır (sayaç >0 ise onay sorulur, 0'da kalır); Kaza Takibi sayacı borçtur, geçmiş işareti değiştirmez (yoksa aynı vakit yeniden eklenirdi) |
| AdMob app-ads.txt "desteklenmeyen alan adı" | Play'deki web sitesi Google Sites'tı (kökte dosya olamaz). docs/site/ (app-ads.txt + index.html) → mahir2772.github.io; Play "Web sitesi" bu adres. ✅ AdMob'da doğrulandı (10 Ekim 2026) |
| Çeviri | Yeni metinler iki ayrı denetimden geçti (5 dil) |
| Yapılmayan | Play "desteği sonlandırılmış API" (Flutter motorundan) ve AGP 9 (Flutter desteği belirsiz): Flutter güncellemesi beklenir |
| İndirme butonu çıkmayan hesap | Uygulama tarafı değil (178 ülke açık, başka hesaplar indiriyor): okul/iş ya da ebeveyn denetimli hesap |

## Yayın öncesi kontrol (1.2.0, dahili test önerilir: R8 + kaynak küçültme + yeni ana etkinlik)
1. Ezan çalar (eski ve yeni kanallarda ses var), bildirim simgesi görünür, "Kıldım" çalışır; telefonu yeniden başlatınca da çalar.
2. Ayarlar > Bildirim Kontrolü: durumlar doğru, üretici rehberi telefonun markası, "1 dk sonra test ezanı" gelir.
3. Android 11–14: gezinme çubuğu saydam, alt menü/reklam/alt sayfalar çubuğun üstünde; Android 15+ değişmedi.
4. Araçlar > Yakındaki Camiler harita uygulamasını açar.
5. Ayarlar'da "Dini gün ve kandil bildirimleri" anahtarı; (ilk bildirim 10 Aralık 2026 10:00).
6. Eski sürümde arka plan resmi seçmiş cihazda arka plan görünür (ya da düz renk), Crashlytics'te yeni "Unable to load asset" yok.
7. Namaz Takibi: kazaya eklenmiş hücreye dokun → kılındı olur, Kaza Takibi'nde sayı bir azalır.
8. ~~app-ads.txt~~ ✅ yayında ve AdMob'da doğrulandı (10 Ekim 2026).
