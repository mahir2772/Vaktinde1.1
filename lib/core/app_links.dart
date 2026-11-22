/// Uygulama dışı bağlantılar (tek yer)
class AppLinks {
  AppLinks._();

  /// Gizlilik politikası (Google Sites). Boşken Ayarlar'daki satır gizlenir.
  static const String privacyPolicy =
      'https://sites.google.com/view/vaktinde-privacy/ana-sayfa';

  /// Play Store sayfası
  static const String playStore =
      'https://play.google.com/store/apps/details?id=com.mmdigital.vaktinde';

  /// Uygulama içinden paylaşılan Play bağlantısı: kurulum, Play Console >
  /// Edinme raporlarında kaynak (app_share) ve kampanyaya göre görünür.
  static String playStoreLink(String campaign) =>
      '$playStore&referrer=${Uri.encodeComponent('utm_source=app_share&utm_campaign=$campaign')}';
}
