/// Uygulama dışı bağlantılar (tek yer)
class AppLinks {
  AppLinks._();

  /// Gizlilik politikası (Google Sites). Boşken Ayarlar'daki satır gizlenir.
  static const String privacyPolicy =
      'https://sites.google.com/view/vaktinde-privacy/ana-sayfa';

  /// Kullanım koşulları (GitHub Pages: docs/site/terms.html, Türkçe +
  /// İngilizce); Quran Foundation API şartı
  static const String termsOfUse = 'https://mahir2772.github.io/terms.html';

  /// Play Store sayfası
  static const String playStore =
      'https://play.google.com/store/apps/details?id=com.mmdigital.vaktinde';

  /// Uygulama içinden paylaşılan Play bağlantısı: kurulum, Play Console >
  /// Edinme raporlarında kaynak (app_share) ve kampanyaya göre görünür.
  static String playStoreLink(String campaign) =>
      '$playStore&referrer=${Uri.encodeComponent('utm_source=app_share&utm_campaign=$campaign')}';
}
