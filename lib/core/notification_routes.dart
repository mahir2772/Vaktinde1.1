import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Bildirimden uygulama içi yönlendirme (tek yer). Hedef 'open|<hedef>'
/// biçiminde bildirimin yükünde (gövdeye dokunma) ya da uygulamayı açan eylem
/// düğmesinin kimliğinde (showsUserInterface: true) taşınır. Diğer yükler
/// ('prayed|…') ve eylemler ("Kıldım", 'stop_ezan|…') yönlendirme değildir.
/// Hedefi MainWrapper açar (açılış akışından sonra; geçiş reklamı yok).
class NotificationRoutes {
  NotificationRoutes._();

  static const String _prefix = 'open|';

  /// Cuma mesajları
  static const String friday = 'friday';

  /// Kur'an okuyucusunda sure: 'surah:<numara>'
  static const String surah = 'surah';

  /// Hatim okuması (hatim sayfasında okuyucu)
  static const String hatim = 'hatim';

  /// Yükte ya da eylem kimliğinde taşınan biçim
  static String route(String target) => '$_prefix$target';

  /// Dokunuşun hedefi: eylem düğmesiyse kimliğinden, gövdeyse yükten;
  /// yönlendirme değilse null
  static String? targetOf(NotificationResponse response) {
    final value = response.actionId ?? response.payload;
    if (value == null || !value.startsWith(_prefix)) return null;
    final target = value.substring(_prefix.length);
    return target.isEmpty ? null : target;
  }

  /// Açılmayı bekleyen hedef: dokunuş (uygulama açıkken ya da uygulamayı
  /// açan) yazar, MainWrapper açınca siler
  static final ValueNotifier<String?> pending = ValueNotifier(null);

  /// Bildirime dokunuldu (NotificationService)
  static void handle(NotificationResponse response) {
    final target = targetOf(response);
    if (target != null) pending.value = target;
  }
}
