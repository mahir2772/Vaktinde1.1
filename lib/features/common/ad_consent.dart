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

  static Future<void>? _run;
  static bool _adsStarted = false;
  static final List<VoidCallback> _onAdsStarted = [];

  /// Reklamlar başladığında bir kez çalışır (başlamışsa hemen)
  static void whenAdsStarted(VoidCallback callback) {
    if (_adsStarted) {
      callback();
    } else {
      _onAdsStarted.add(callback);
    }
  }

  /// Uygulama açılışında bir kez çağrılır (ikinci çağrı aynı işi döndürür)
  static Future<void> gatherAndStartAds() => _run ??= _gather();

  static Future<void> _gather() async {
    if (!Platform.isAndroid) return;
    // Önceki oturumda rıza alınmışsa reklamlar beklemeden başlar
    await _startIfAllowed();
    try {
      final updated = Completer<bool>();
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () {
          if (!updated.isCompleted) updated.complete(true);
        },
        (error) {
          debugPrint('UMP güncellenemedi: ${error.message}');
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
    await _startIfAllowed();
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
    canRequestAds.value = true;
    final callbacks = List<VoidCallback>.of(_onAdsStarted);
    _onAdsStarted.clear();
    for (final callback in callbacks) {
      try {
        callback();
      } catch (_) {}
    }
  }
}
