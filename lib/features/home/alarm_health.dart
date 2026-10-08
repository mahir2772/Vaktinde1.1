import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import '../../data/services/notification_service.dart';

/// Ezan uyarısını engelleyen durum (önemlisi önce)
enum AlarmHealthIssue { notificationsOff, exactAlarmsOff }

/// Ezan uyarısının sağlığı: bildirim izni ve tam zamanlı alarm izni (Android 12+).
/// Açılışta ve uygulamaya her dönüşte (ayarlardan dönüş dahil) yeniden okunur.
/// İzin değişince ya da bildirimler açılıp kapanınca [onChanged] (alarmları
/// yeniden kur) çağrılır. Pencere açmaz, kendiliğinden izin istemez; sadece
/// kullanıcı uyarıdaki butona basınca istenir.
class AlarmHealth extends ChangeNotifier {
  AlarmHealth(
    this._notifications, {
    this.onChanged,
    Future<bool> Function()? openSettings,
  }) : _openSettings = openSettings ?? ph.openAppSettings;

  final NotificationService _notifications;
  final Future<void> Function()? onChanged;
  final Future<bool> Function() _openSettings;

  /// Son okunan durumlar; null: bilinmiyor (sorun sayılmaz)
  bool? exactAllowed;
  bool? notificationsEnabled;

  /// Sistem penceresi hiç gösterilmeden dönen ret (kalıcı ret ya da Android 12
  /// ve altı) bu süreden kısadır: insan pencereyi okuyup bu kadar hızlı reddedemez
  static const Duration noDialogThreshold = Duration(milliseconds: 800);

  /// Hiç uyarı açık değilse sorun yok; bildirimler kapalıysa ezan hiç çalmaz
  /// (önce o), tam zamanlı izin yoksa gecikebilir
  static AlarmHealthIssue? issueFor({
    required bool? exactAllowed,
    required bool? notificationsEnabled,
    required bool anyAlarmEnabled,
  }) {
    if (!anyAlarmEnabled) return null;
    if (notificationsEnabled == false) return AlarmHealthIssue.notificationsOff;
    if (exactAllowed == false) return AlarmHealthIssue.exactAlarmsOff;
    return null;
  }

  AlarmHealthIssue? issue({required bool anyAlarmEnabled}) => issueFor(
    exactAllowed: exactAllowed,
    notificationsEnabled: notificationsEnabled,
    anyAlarmEnabled: anyAlarmEnabled,
  );

  Future<void>? _running;
  bool _again = false;
  bool _disposed = false;
  bool _fixing = false;
  // Bu oturumda bildirim izni penceresi denendi: sonraki dokunuş ayarları açar
  bool _askedNotifications = false;

  /// İzinleri yeniden okur; üst üste gelen çağrılar tek koşuda birleşir
  Future<void> refresh() {
    final running = _running;
    if (running != null) {
      _again = true;
      return running;
    }
    return _running = _refreshLoop();
  }

  Future<void> _refreshLoop() async {
    try {
      do {
        _again = false;
        await _check();
      } while (_again && !_disposed);
    } finally {
      _running = null;
    }
  }

  Future<void> _check() async {
    // Canlı okunamazsa son kurulumda görülen izin
    final exact =
        await _notifications.refreshExactAlarmPermission() ??
        await NotificationService.lastKnownExactAllowed();
    final enabled = await _notifications.notificationsEnabled();
    if (_disposed) return;
    final exactChanged =
        exactAllowed != null && exact != null && exact != exactAllowed;
    final notificationsChanged =
        notificationsEnabled != null &&
        enabled != null &&
        enabled != notificationsEnabled;
    final changed = exact != exactAllowed || enabled != notificationsEnabled;
    exactAllowed = exact;
    notificationsEnabled = enabled;
    if (changed) notifyListeners();
    // Kip değişir: izin değişti ya da bildirimler açıldı/kapandı (kapalıyken ezan
    // alarmClock kurulmaz, alarm simgesi kalkar): alarmlar yeniden kurulur
    final callback = onChanged;
    if ((exactChanged || notificationsChanged) && callback != null) {
      unawaited(callback());
    }
  }

  /// "İzin ver": Android 12+ "Alarmlar ve hatırlatıcılar" ekranı; dönünce yeniden
  /// okunur. Ekran açılamazsa uygulama ayarları açılır.
  Future<void> fixExactAlarms() => _fix(() async {
    final result = await _notifications.requestExactAlarmPermission();
    if (result == null) await _openAppSettings();
  });

  /// "Aç": önce sistem izin penceresi. Pencere çıkmadıysa (kalıcı ret ya da
  /// Android 12 ve altı) ya da bu oturumda zaten denendiyse uygulama ayarları açılır.
  Future<void> fixNotifications() => _fix(() async {
    if (_askedNotifications) {
      await _openAppSettings();
      return;
    }
    _askedNotifications = true;
    final watch = Stopwatch()..start();
    final granted = await _notifications.requestNotificationPermission();
    if (granted == false && watch.elapsed < noDialogThreshold) {
      await _openAppSettings();
    }
  });

  Future<void> _fix(Future<void> Function() action) async {
    if (_fixing || _disposed) return;
    _fixing = true;
    try {
      await action();
    } finally {
      _fixing = false;
    }
    if (!_disposed) await refresh();
  }

  Future<void> _openAppSettings() async {
    try {
      await _openSettings();
    } catch (e) {
      debugPrint('Uygulama ayarları açılamadı: $e');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
