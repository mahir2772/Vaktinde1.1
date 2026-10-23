VAKTİNDE – GİZLİLİK POLİTİKASI
Son güncelleme: Ekim 2026

Bu politika, Vaktinde uygulamasının ("Uygulama") hangi verileri hangi amaçla kullandığını, kimlerle paylaştığını ve haklarınızı açıklar. Uygulama üyelik istemez; adınız, e-posta adresiniz veya telefon numaranız gibi bilgileri toplamaz.

Kur'an dinleme özelliği Quran Foundation API'lerini (Quran.com ve QuranReflect ekosistemi) kullanır. Vaktinde bağımsız bir uygulamadır, Quran Foundation'ın resmî uygulaması değildir; bu API'leri Quran Foundation geliştirici şartlarına uygun olarak kullanır.

1. Telefonunuzda kalan bilgiler
Aşağıdaki bilgiler yalnızca telefonunuzda saklanır, bize gönderilmez:
• Seçtiğiniz konum (il/ilçe adı ve koordinatlar) ve vakit ince ayarları
• Ezan ve hatırlatma ayarları, ses seçimleri, dil, tema ve yazı boyutu tercihleri
• Namaz takibi kayıtları, özel gün (hayız/nifas) işaretleri ve seri hedefleri, Ramazan orucu kayıtları, kaza namazı ve oruç sayıları, zikir sayaçları, Kur'an'da kaldığınız yer ve yer imi, hatim planı ve okunan sayfalar, zekât hesapları
Namaz vakitleri ve kıble yönü telefonunuzda, internet bağlantısı olmadan hesaplanır.
Namaz, oruç, hatim ve özel gün kayıtları gibi dinî inançlarınızla ilgili bilgiler birçok yasada (KVKK, GDPR) özel nitelikli/hassas veri sayılır. Bu kayıtlar yalnızca sizin girdiğiniz anda ve yalnızca telefonunuzda tutulur; bize, Quran Foundation'a veya başka bir hizmete gönderilmez, reklam profili oluşturmak ya da yapay zekâ eğitmek için kullanılmaz.
Ayarlar > Yedekleme > "Verileri Yedekle" bu bilgileri (konumunuz dahil) tek bir dosyaya yazar ve dosyayı yalnızca sizin seçtiğiniz uygulamayla (ör. Google Drive, e-posta) paylaşır; dosya bize ya da başka bir yere kendiliğinden gönderilmez. Yedek dosyası konumunuzu ve namaz kayıtlarınızı içerdiğinden onu güvendiğiniz bir yerde saklayın. "Yedeği Geri Yükle" seçtiğiniz dosyayı yalnızca telefonunuzda okur. İzin durumları gibi cihaza özgü bilgiler ve reklam tercihleriniz yedeğe girmez.

2. Konum
Konum izni verirseniz telefonunuzun konumu (enlem ve boylam) namaz vakitlerini ve kıble yönünü hesaplamak için kullanılır.
• Bulunduğunuz il/ilçe adını göstermek ve elle şehir aramak için koordinatlar ya da aradığınız şehir adı, telefonunuzun adres hizmetine (Android; genellikle Google) iletilir.
• Koordinat bulunamazsa vakitleri getirmek için yalnızca il/ilçe adı Aladhan vakit servisine (aladhan.com) gönderilebilir.
• Konumunuz bizim sunucularımıza gönderilmez; Uygulama konumunuzu analiz ve reklam hizmetlerine iletmez.
• "Yakındaki camiler" özelliği, konumunuzu yalnızca sizin açtığınız harita uygulamasına iletir.
Konum izni vermeden şehrinizi elle seçebilirsiniz.

3. İçerik servisleri
Günün ayeti ve Kur'an okuyucudaki ayet ve mealler (alquran.cloud), günün hadisi (hadeethenc.com), zekât ekranındaki altın/döviz kurları (CollectAPI) ve fitre/fidye ekranındaki Diyanet tutarı (uygulamanın GitHub Pages sayfası, mahir2772.github.io) bu servislerden indirilir. Bu isteklerde kişisel veri gönderilmez; her internet isteğinde olduğu gibi servisler IP adresinizi görebilir.
Kur'an dinleme: "Dinle"ye dokunduğunuzda kârî listesi ve surenin ses adresi, Cloudflare Workers üzerinde çalışan ara sunucumuzdan alınır; ara sunucu bunları Quran Foundation Content API'sinden getirir. Ses, Quran Foundation'ın ses sunucusundan (quranicaudio.com) akışla çalınır ve telefonunuza kaydedilmez. Bu isteklerde yalnızca sure numarası, kârî numarası ve arayüz diliniz gönderilir; IP adresinizi Cloudflare ve Quran Foundation görebilir. Ara sunucumuz kişisel veri ya da istek kaydı tutmaz (Cloudflare'in kendi güvenlik ve işletim kayıtları dışında). Seçtiğiniz kârî yalnızca telefonunuzda saklanır. Cloudflare gizlilik politikası: https://www.cloudflare.com/privacypolicy/ · Quran Foundation ses sunucusu (quranicaudio.com) gizlilik politikası: https://quranicaudio.com/privacy

4. Analiz ve hata raporları (Google Firebase)
Uygulamayı geliştirmek için Google Firebase hizmetleri kullanılır:
• Firebase Analytics: hangi özelliklerin kullanıldığına dair sınırlı olaylar (ör. ilk açılışta bildirim/konum izninin verilip verilmediği), uygulama örnek kimliği, cihaz modeli, işletim sistemi, uygulama sürümü, dil ve IP adresinden çıkarılan yaklaşık ülke/bölge. Konumunuz ve namaz vakitleriniz gönderilmez.
• Avrupa Ekonomik Alanı, Birleşik Krallık ve İsviçre'de Firebase Analytics, reklam izni penceresinde (Google UMP) verdiğiniz tercihe uyar: "cihazda bilgi depolama ve/veya bilgiye erişme" amacını onaylamazsanız Analytics cihazınızda analiz ve reklam tanımlayıcısı saklamaz; kişiselleştirilmiş reklam amaçlarını onaylamazsanız Analytics verileri reklam amacıyla kullanılmaz. Tercihinizi Ayarlar > Destek > Gizlilik ve Reklamlar > "Reklam gizlilik ayarları" bölümünden değiştirebilirsiniz.
• Firebase Crashlytics: Uygulama çöktüğünde ya da bir hata oluştuğunda hata kaydı, cihaz modeli, işletim sistemi, uygulama sürümü ve kurulum kimliği.
Bu veriler sizi doğrudan tanımlamaz, Google tarafından işlenir ve sınırlı süre saklanır (Crashlytics kayıtları 90 gün, Analytics verileri en fazla 14 ay).

5. Reklamlar (Google AdMob)
Uygulama ücretsiz kalabilmek için Google AdMob reklamları gösterir.
• AdMob reklam göstermek, ölçmek ve kötüye kullanımı önlemek için reklam kimliği, cihaz bilgileri, IP adresi (ve bundan çıkarılan yaklaşık konum) ile reklam etkileşimlerini toplayabilir ve iş ortaklarıyla paylaşabilir.
• Uygulama GPS konumunuzu reklam ağına vermez. Reklamlar aile dostu içerikle sınırlandırılmıştır.
• Avrupa Ekonomik Alanı, Birleşik Krallık ve İsviçre'de kişiselleştirilmiş reklam için onayınız istenir; tercihinizi Ayarlar > Destek > Gizlilik ve Reklamlar > "Reklam gizlilik ayarları" bölümünden değiştirebilirsiniz.
• Reklam kimliğinizi telefonunuzun ayarlarından (Google > Reklamlar) sıfırlayabilir veya silebilirsiniz.
Google'ın verileri nasıl kullandığı: https://policies.google.com/technologies/partner-sites

6. Kullanılan izinler
• Konum (isteğe bağlı): vakit ve kıble hesabı
• Bildirimler: ezan ve hatırlatma bildirimleri
• Alarmlar ve hatırlatıcılar: ezanın tam vaktinde çalması
• Telefon açılınca başlatma: alarmların ve (Ayarlar'dan açarsanız) vakte kalan süreyi gösteren kalıcı bildirimin yeniden kurulması
• Ön plan hizmeti (medya oynatma): yalnızca Kur'an dinlerken; ekran kapalıyken de çalması ve kilit ekranındaki oynat/duraklat kontrolleri
• İnternet: içerikler, Kur'an sesi, reklamlar ve hata raporları

7. Paylaşım ve yurt dışına aktarım
Verilerinizi satmayız, reklam profili oluşturmak için kullanmayız. Hizmet sağlayıcılarımız (Google Firebase ve AdMob, Cloudflare, Quran Foundation) verileri Türkiye dışındaki sunucularda işleyebilir. Bu sağlayıcıların sözleşme koşulları verileri korumalarını gerektirir; uluslararası aktarımlarda AB Standart Sözleşme Maddeleri (SCC) veya eşdeğer güvenceler kullanılır. Hizmet sağlayıcılarının Kur'an metnini ve İslami içeriği kötüye kullanmaları yasaktır.

8. Güvenlik
Uygulamanın tüm bağlantıları şifrelidir (TLS/HTTPS). Kişisel kayıtlar yalnızca telefonunuzda, Android'in uygulamaya özel korumalı alanında tutulur. Quran Foundation erişim anahtarı uygulamada değil, ara sunucuda şifreli gizli değişken olarak saklanır, yalnızca geliştirici erişebilir ve en az altı ayda bir yenilenir. Bir güvenlik olayından şüphelenildiğinde 24 saat içinde müdahale edilir ve Quran Foundation'a bildirilir. Güvenlik uygulamalarımız Quran Foundation geliştirici şartlarının güvenlik kurallarıyla (Security Rule 6.9) uyumludur.

9. Saklama ve silme
Telefonunuzdaki verileri Ayarlar > Uygulamalar > Vaktinde > Depolama > "Verileri temizle" ile ya da Uygulamayı kaldırarak silebilirsiniz. Oluşturduğunuz yedek dosyaları bu yolla silinmez; onları kaydettiğiniz yerden kendiniz silebilirsiniz. Google hizmetlerindeki kayıtlar yukarıdaki sürelerin sonunda silinir; silinmesini istediğiniz veriler için bize e-posta gönderebilirsiniz.

10. Çocukların gizliliği
Uygulama genel kitleye yöneliktir; 13 yaşından küçük çocuklardan bilerek kişisel veri toplamayız. Çocuğunuza ait bilgilerin toplandığını düşünüyorsanız bize yazın.

11. Haklarınız
6698 sayılı Kişisel Verilerin Korunması Kanunu'nun 11. maddesi ve AB Genel Veri Koruma Tüzüğü (GDPR) kapsamında verilerinize erişme, düzeltilmesini veya silinmesini isteme ve işlenmesine itiraz etme haklarına sahipsiniz. Uygulama hesap ya da Quran Foundation girişi kullanmadığından iptal edilecek bir erişim izni (OAuth) yoktur; telefonunuzdaki verileri 9. maddedeki gibi siz silebilirsiniz. Talepleriniz için aşağıdaki adrese yazabilirsiniz; en geç 30 gün içinde yanıt verilir.

12. Değişiklikler
Bu politikayı güncelleyebiliriz; güncel sürüm bu sayfada ve Uygulama içindeki bağlantıda yayımlanır, sayfanın başındaki "Son güncelleme" tarihi değişir. Önemli değişiklikler Uygulama içindeki "Yenilikler" bölümünde duyurulur.

13. İletişim
E-posta: mmdigitall.dev@gmail.com
Posta adresi: [Google Play Console'daki geliştirici adresiniz]
