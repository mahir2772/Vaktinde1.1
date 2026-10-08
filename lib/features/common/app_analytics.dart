import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Firebase Analytics olayları tek kapıdan gider. Konum (il, ilçe, koordinat)
/// ve ibadet bilgisi (hangi vakit, kılınan namaz) gönderilmez: sadece
/// [allowedParameters] içindeki parametreler geçer, diğerleri atılır.
class AppAnalytics {
  AppAnalytics._();

  /// Kişisel veri içermeyen, gönderilebilir parametreler
  static const Set<String> allowedParameters = {'tip'};

  /// Testte olayları yakalamak için
  @visibleForTesting
  static Future<void> Function(String name, Map<String, Object>? parameters)
  sink = _firebase;

  static Future<void> _firebase(String name, Map<String, Object>? parameters) =>
      FirebaseAnalytics.instance.logEvent(name: name, parameters: parameters);

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
}
