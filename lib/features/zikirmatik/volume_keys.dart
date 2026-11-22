import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Zikirmatik "Ses tuşlarıyla say" (Dart tarafı).
///
/// MainActivity ses tuşlarını sadece iki koşul birden sağlanınca tüketir
/// (sistem ses düzeyi değişmez): 'vaktinde/device' `setVolumeKeyCounting(true)`
/// ve 'vaktinde/volume_keys' dinleniyor. Zikir ekranı [update] ile sadece sekme
/// görünür, ayar açık ve uygulama ön plandayken açar; aksi halde ikisini de
/// bırakır (ses tuşları sisteme döner). Yerel taraf onStop'ta ve motor
/// değişince bayrağı kendisi de kapatır. Olay: ses açma +1, ses kısma -1.
class ZikirVolumeKeys {
  static const MethodChannel _device = MethodChannel('vaktinde/device');
  static const EventChannel _events = EventChannel('vaktinde/volume_keys');

  /// Basış başına +1 (ses açma) ya da -1 (ses kısma)
  final ValueChanged<int> onKey;

  ZikirVolumeKeys({required this.onKey});

  StreamSubscription<Object?>? _subscription;

  // Yerelde de başlangıç kapalı: özellik açılmadıkça kanal çağrılmaz
  bool _active = false;

  /// Ses tuşları şu an sayaca gidiyor mu (Dart tarafının isteği)
  bool get active => _active;

  /// [active]: Zikir sekmesi görünür + ayar açık + ön planda. Sadece değişince
  /// yerel tarafa bildirilir.
  void update(bool active) {
    if (active == _active) return;
    _active = active;
    if (active) {
      // Önce dinlenir, sonra bayrak açılır (yerel taraf ikisini birden ister)
      _subscription = _events.receiveBroadcastStream().listen(
        _onEvent,
        onError: (Object _) {},
      );
    } else {
      _subscription?.cancel();
      _subscription = null;
    }
    _device.invokeMethod<void>('setVolumeKeyCounting', active).catchError((
      Object e,
    ) {
      // Kanal yoksa (eski sürüm, test) tuşlar zaten sisteme gider
      debugPrint('Ses tuşu sayımı ayarlanamadı: $e');
    });
  }

  void _onEvent(Object? event) {
    // Kapatıldıktan sonra yoldaki olay sayılmaz
    if (!_active || event is! int || event == 0) return;
    onKey(event > 0 ? 1 : -1);
  }

  /// Ekran kapanırken: ses tuşları sisteme döner
  void dispose() => update(false);
}
