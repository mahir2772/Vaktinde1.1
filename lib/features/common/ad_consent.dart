import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob UMP (AB/EEA rıza formu). Reklam SDK'sı ve reklam yüklemeleri ancak
/// `canRequestAds` true olunca başlar. Hiçbir adım uygulamayı bekletmez ya da
/// çökertmez: ağ yoksa/zaman aşımında önceki oturumun rızası geçerli kalır.
class AdConsent {
  AdConsent._();

  /// Reklam istenebilir mi (banner'lar bunu dinler)
  static final ValueNotifier<bool> canRequestAds = ValueNotifier<bool>(false);

  /// AB/EEA'da rızayı sonradan değiştirme girişi zorunlu mu (Ayarlar satırı)
  static final ValueNotifier<bool> privacyOptionsRequired = ValueNotifier<bool>(
    false,
  );

  static Future<void>? _run;
  static bool _adsStarted = false;
  static final List<VoidCallback> _onAdsStarted = [];

  /// Reklam istenebilir olduğunda bir kez çalışır (şu an istenebiliyorsa hemen;
  /// rıza geri çekildiyse yeniden verilene kadar bekler)
  static void whenAdsStarted(VoidCallback callback) {
    if (_adsStarted && canRequestAds.value) {
      callback();
    } else {
      _onAdsStarted.add(callback);
    }
  }

  static void _setCanRequestAds(bool value) {
    canRequestAds.value = value;
    if (!value) return;
    final callbacks = List<VoidCallback>.of(_onAdsStarted);
    _onAdsStarted.clear();
    for (final callback in callbacks) {
      try {
        callback();
      } catch (_) {}
    }
  }

  /// Uygulama açılışında bir kez çağrılır (ikinci çağrı aynı işi döndürür)
  static Future<void> gatherAndStartAds() => _run ??= _gather();

  /// Testte platform kontrolünü aşmak için
  @visibleForTesting
  static bool Function() isSupported = () => Platform.isAndroid;

  @visibleForTesting
  static void debugReset() {
    _run = null;
    _adsStarted = false;
    _onAdsStarted.clear();
    canRequestAds.value = false;
    privacyOptionsRequired.value = false;
  }

  static Future<void> _gather() async {
    if (!isSupported()) return;
    // Önceki oturumda rıza alınmışsa reklamlar beklemeden başlar
    await _startIfAllowed();
    try {
      final updated = Completer<bool>();
      // Eklenti void çağrıda sadece PlatformException yakalar; diğer hatalar
      // (ör. MissingPluginException) bölgeye düşer → burada yakalanır
      runZonedGuarded(
        () => ConsentInformation.instance.requestConsentInfoUpdate(
          ConsentRequestParameters(),
          () {
            if (!updated.isCompleted) updated.complete(true);
          },
          (error) {
            debugPrint('UMP güncellenemedi: ${error.message}');
            if (!updated.isCompleted) updated.complete(false);
          },
        ),
        (error, stack) {
          debugPrint('UMP güncelleme hatası: $error');
          if (!updated.isCompleted) updated.complete(false);
        },
      );
      final ok = await updated.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => false,
      );
      if (ok) {
        // Gerekirse form gösterilir (kullanıcı kapatınca döner)
        await ConsentForm.loadAndShowConsentFormIfRequired((formError) {
          if (formError != null) {
            debugPrint('UMP formu: ${formError.message}');
          }
        });
      }
    } catch (e) {
      debugPrint('UMP hatası: $e');
    }
    await _updatePrivacyOptionsStatus();
    await _startIfAllowed();
  }

  static Future<void> _updatePrivacyOptionsStatus() async {
    try {
      final status = await ConsentInformation.instance
          .getPrivacyOptionsRequirementStatus();
      privacyOptionsRequired.value =
          status == PrivacyOptionsRequirementStatus.required;
    } catch (e) {
      debugPrint('UMP gizlilik durumu okunamadı: $e');
    }
  }

  /// Ayarlardaki "Reklam gizlilik ayarları": rıza formunu yeniden açar;
  /// kapanınca reklam izni yeniden okunur (geri çekildiyse yeni reklam istenmez)
  static Future<void> showPrivacyOptions() async {
    try {
      final closed = Completer<void>();
      await ConsentForm.showPrivacyOptionsForm((formError) {
        if (formError != null) {
          debugPrint('UMP gizlilik formu: ${formError.message}');
        }
        if (!closed.isCompleted) closed.complete();
      });
      await closed.future.timeout(
        const Duration(minutes: 10),
        onTimeout: () {},
      );
    } catch (e) {
      debugPrint('UMP gizlilik formu açılamadı: $e');
    }
    try {
      final allowed = await ConsentInformation.instance.canRequestAds();
      if (!_adsStarted) {
        await _startIfAllowed();
      } else {
        _setCanRequestAds(allowed);
      }
    } catch (e) {
      debugPrint('UMP izin durumu okunamadı: $e');
    }
    await _updatePrivacyOptionsStatus();
  }

  static Future<void> _startIfAllowed() async {
    if (_adsStarted) return;
    bool allowed;
    try {
      allowed = await ConsentInformation.instance.canRequestAds();
    } catch (e) {
      allowed = false;
    }
    if (!allowed || _adsStarted) return;
    _adsStarted = true;
    try {
      await MobileAds.instance.initialize().timeout(
        const Duration(seconds: 10),
      );
    } catch (e) {
      debugPrint('MobileAds başlatılamadı: $e');
    }
    _setCanRequestAds(true);
  }
}
