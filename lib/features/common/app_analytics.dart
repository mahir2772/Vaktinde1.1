import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Reklam rızası (UMP) bu kullanıcı için gerekli mi
enum ConsentRequirement {
  /// Rıza gerekli ama alınmamış (form henüz doldurulmadı ya da yenilenmeli):
  /// TCF kaydı eski olabilir
  pending,

  /// AB/EEA, Birleşik Krallık, İsviçre: rıza gerekli ve alınmış (seçim TCF
  /// kaydında)
  required,

  /// UMP rızanın gerekmediğini belirledi
  notRequired,

  /// Henüz belirlenemedi (ilk açılış, ağ yok, hata)
  unknown,
}

/// Firebase Analytics izinleri (Consent Mode v2)
@immutable
class AnalyticsConsent {
  const AnalyticsConsent({
    required this.analyticsStorage,
    required this.adStorage,
    required this.adUserData,
    required this.adPersonalization,
  });

  static const AnalyticsConsent granted = AnalyticsConsent(
    analyticsStorage: true,
    adStorage: true,
    adUserData: true,
    adPersonalization: true,
  );

  static const AnalyticsConsent denied = AnalyticsConsent(
    analyticsStorage: false,
    adStorage: false,
    adUserData: false,
    adPersonalization: false,
  );

  final bool analyticsStorage;
  final bool adStorage;
  final bool adUserData;
  final bool adPersonalization;

  /// UMP'nin yazdığı IAB TCF v2 kayıtlarından (sade eşleme):
  /// * GDPR geçerli değil ('IABTCF_gdprApplies' 0): hepsi açık.
  /// * Rıza bekleniyor ([ConsentRequirement.pending]): hepsi kapalı.
  /// * GDPR geçerli (1): analytics ve ad storage = amaç 1 ("cihazda bilgi
  ///   saklama/erişim"); ad user data ve ad personalization = amaç 1 + 3 + 4
  ///   (kişiselleştirilmiş reklam profili oluşturma ve kullanma).
  ///   'IABTCF_PurposeConsents' n. karakteri '1' ise n. amaç onaylı; kayıt
  ///   yoksa/kısaysa onay yok.
  /// * Bilinmiyor: UMP bu oturumda ([updated]) rızanın gerekmediğini
  ///   belirlediyse hepsi açık; rıza gerekliyse, bölge belirlenemediyse ya da
  ///   UMP güncellenemediyse (eski bilgi) hepsi kapalı.
  factory AnalyticsConsent.fromTcf({
    required int? gdprApplies,
    required String? purposeConsents,
    required ConsentRequirement requirement,
    required bool updated,
  }) {
    if (gdprApplies == 0) return granted;
    if (requirement == ConsentRequirement.pending) return denied;
    if (gdprApplies == 1) {
      final purposes = purposeConsents ?? '';
      bool purpose(int n) => purposes.length >= n && purposes[n - 1] == '1';
      final storage = purpose(1);
      final personalized = storage && purpose(3) && purpose(4);
      return AnalyticsConsent(
        analyticsStorage: storage,
        adStorage: storage,
        adUserData: personalized,
        adPersonalization: personalized,
      );
    }
    return updated && requirement == ConsentRequirement.notRequired
        ? granted
        : denied;
  }

  @override
  bool operator ==(Object other) =>
      other is AnalyticsConsent &&
      other.analyticsStorage == analyticsStorage &&
      other.adStorage == adStorage &&
      other.adUserData == adUserData &&
      other.adPersonalization == adPersonalization;

  @override
  int get hashCode =>
      Object.hash(analyticsStorage, adStorage, adUserData, adPersonalization);

  @override
  String toString() =>
      'AnalyticsConsent(analyticsStorage: $analyticsStorage, adStorage: '
      '$adStorage, adUserData: $adUserData, adPersonalization: '
      '$adPersonalization)';
}

/// Firebase Analytics olayları tek kapıdan gider. Konum (il, ilçe, koordinat)
/// ve ibadet bilgisi (hangi vakit, kılınan namaz) gönderilmez: sadece
/// [allowedParameters] içindeki parametreler geçer, diğerleri atılır.
/// AB/EEA rızası (Consent Mode v2) [applyConsent] ile verilir (AdConsent).
class AppAnalytics {
  AppAnalytics._();

  /// Kişisel veri içermeyen, gönderilebilir parametreler
  static const Set<String> allowedParameters = {'tip'};

  /// Testte olayları yakalamak için
  @visibleForTesting
  static Future<void> Function(String name, Map<String, Object>? parameters)
  sink = _firebase;

  /// Testte izinleri yakalamak için
  @visibleForTesting
  static Future<void> Function(AnalyticsConsent consent) consentSink =
      _firebaseConsent;

  static Future<void> _firebase(String name, Map<String, Object>? parameters) =>
      FirebaseAnalytics.instance.logEvent(name: name, parameters: parameters);

  static Future<void> _firebaseConsent(AnalyticsConsent consent) =>
      FirebaseAnalytics.instance.setConsent(
        analyticsStorageConsentGranted: consent.analyticsStorage,
        adStorageConsentGranted: consent.adStorage,
        adUserDataConsentGranted: consent.adUserData,
        adPersonalizationSignalsConsentGranted: consent.adPersonalization,
      );

  /// Olayı kaydeder; izinli olmayan parametreler atılır. Hata fırlatmaz.
  static Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    final safe = <String, Object>{
      for (final entry in (parameters ?? const <String, Object>{}).entries)
        if (allowedParameters.contains(entry.key)) entry.key: entry.value,
    };
    try {
      await sink(name, safe.isEmpty ? null : safe);
    } catch (e) {
      debugPrint('Analytics olayı gönderilemedi: $e');
    }
  }

  /// Analytics izinlerini verir; SDK sonraki açılışlar için de saklar. Hata
  /// fırlatmaz, en fazla 5 sn bekler.
  static Future<void> applyConsent(AnalyticsConsent consent) async {
    try {
      await consentSink(consent).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Analytics izni verilemedi: $e');
    }
  }
}
