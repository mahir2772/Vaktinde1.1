# Kur'an sesi ara sunucusu (Cloudflare Worker)

> **ASKIDA (24 Ekim 2026):** Kur'an dinleme uygulamadan çıkarıldı (kullanıcı kararı). Bu klasör ve git geçmişi
> (23cabfc, b5685ac, 52c06f2, 4eed065) geri getirmek içindir; uygulama şu an bu sunucuyu kullanmaz.

Vaktinde'deki "Dinle" özelliği sesleri **Quran Foundation (Quran.com) Content API**'sinden
alır. QF şartlarına göre API'nin gizli anahtarı (`client_secret`) mobil uygulamaya
konamaz; anahtar bu küçük sunucuda durur. Uygulama sadece kârî listesini ve surenin ses
adresi + ayet zamanlarını buradan alır, sesi QF'nin adresinden **akışla** çalar
(indirme/saklama yok; QF içeriği en çok 1 hafta saklanabilir, burada 1 gün önbellek).

Yollar: `GET /v1/reciters?lang=tr|en|de|fr|ar` ve `GET /v1/chapter/{kârî}/{sure}`.
Başka yol, parametre ya da yöntem kabul edilmez; hata ayrıntısı dışarı verilmez.

## Kurulum (bir kez)

1. **Quran Foundation:** [Developer Console](https://dev-console.quran.foundation/projects)'da
   **Backend/server app** türünde bir uygulama oluştur. Pre-live `client_id` ve
   `client_secret` verilir (secret bir kez gösterilir, kaydet; **sohbete ya da repoya yazma**).
   Tam Kur'an için konsoldan **production erişimi** iste (onaya kadar pre-live sadece Fâtiha
   ve Bakara'yı içerir). Başvuruda gizlilik politikası ve kullanım koşulları bağlantısı
   istenir (`docs/gizlilik_politikasi.md`, `docs/kullanim_kosullari.md`).
2. **Cloudflare:** ücretsiz hesap aç (kart gerekmez). Bilgisayarda Node.js kuruluyken bu
   klasörde:
   ```
   npx wrangler login
   npx wrangler secret put QF_CLIENT_ID
   npx wrangler secret put QF_CLIENT_SECRET
   npx wrangler deploy
   ```
   Komut sonunda adres yazar: `https://vaktinde-quran-audio.<hesabın>.workers.dev`.
3. **Dene:** tarayıcıda `<adres>/v1/reciters?lang=tr` kârî listesini,
   `<adres>/v1/chapter/7/1` Fâtiha'nın ses adresini göstermeli.
4. **Uygulamayı derle:** adresi derleme komutuna ekle (gizli değil):
   ```
   flutter build appbundle --release --dart-define=COLLECT_API_KEY=<anahtar> --dart-define=QURAN_AUDIO_API=https://vaktinde-quran-audio.<hesabın>.workers.dev
   ```
   Bu değer verilmezse uygulamada "Dinle" düğmesi görünmez.

## Production onayı gelince

Konsoldaki production `client_id` / `client_secret` ile:
```
npx wrangler secret put QF_CLIENT_ID
npx wrangler secret put QF_CLIENT_SECRET
```
`wrangler.toml`'da `QF_ENV = "production"` yap, `npx wrangler deploy`. Uygulamayı yeniden
derlemek gerekmez.

## Bakım

- **Kapatmak:** `ENABLED = "0"` + deploy → uygulama "Dinleme şu an kullanılamıyor" der.
- **Anahtar yenileme:** 6 ayda bir (ya da sızdığından şüphelenince hemen) konsoldan yeni
  secret al, `wrangler secret put QF_CLIENT_SECRET`. Sızıntı şüphesini 24 saat içinde
  developers@quran.com'a bildir (QF şartı).
- **Sınır:** IP başına dakikada 20 istek (`wrangler.toml` → `ratelimits`).
- **Önbellek:** Cloudflare'in Cache API'si `*.workers.dev` adresinde çalışmaz (sadece özel alan
  adında); Worker bu yüzden yanıtları kendi belleğinde de 1 gün tutar ("bu kârîde bu sure yok"
  yanıtı dahil). Ses adresi sadece Quran Foundation / Quran.com sunucularından kabul edilir.
- **Test:** `node --test` (Node 20+, bu klasörde; ağ çağrıları sahte).
- Cloudflare ücretsiz planı günde 100.000 istek; uygulama kârî listesini ve sure bilgisini
  oturum boyunca tekrar istemez.
