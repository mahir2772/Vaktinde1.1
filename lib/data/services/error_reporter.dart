import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Flutter çerçeve hataları ve yakalanmamış Dart hataları ölümcül olmayan
/// kayıt olarak gider: uygulamayı kapatmayan hata çökme sayılmaz. Gerçek
/// (yerel) çökmeleri Crashlytics SDK'sı kendisi kaydeder.
void installCrashlyticsHandlers(FirebaseCrashlytics crashlytics) {
  FlutterError.onError = crashlytics.recordFlutterError;
  PlatformDispatcher.instance.onError = (error, stack) {
    crashlytics.recordError(error, stack);
    return true;
  };
}

/// Ölümcül olmayan hatayı Crashlytics'e bildirir (ör. kurulamayan ezan alarmı).
/// WorkManager isolate'inde Firebase başlatılmamış olabilir: önce başlatılmaya
/// çalışılır. Hiçbir durumda hata fırlatmaz; Crashlytics toplama ayarı (debug'da
/// kapalı) geçerlidir.
Future<void> reportNonFatal(
  Object error,
  StackTrace? stack, {
  required String reason,
}) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp().timeout(const Duration(seconds: 5));
    }
    await FirebaseCrashlytics.instance
        .recordError(error, stack, reason: reason, fatal: false)
        .timeout(const Duration(seconds: 5));
  } catch (e) {
    debugPrint('Crashlytics bildirilemedi ($reason): $e');
  }
}
