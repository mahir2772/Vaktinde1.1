import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/prayer_times_model.dart';
import '../../data/services/prayer_tracker.dart';
import '../../data/services/prayer_tracker_service.dart';

/// Namaz takibinde 7 günlük tam seri uygulama içinde tamamlanınca Play'in
/// uygulama içi değerlendirme penceresi istenir: ömür boyu en fazla bir kez
/// ([UsageReviewPrompt] ile ortak), sadece [InAppReview.isAvailable] ise.
/// MainWrapper açılış pencerelerinden sonra başlatır (ön plan, ana isolate);
/// bildirimdeki "Kıldım" ayrı isolate'te çalıştığından bunu tetiklemez.
class StreakReviewPrompt {
  StreakReviewPrompt({
    required this.todayTimes,
    this.canPrompt,
    this.delay = const Duration(seconds: 1),
  });

  /// Değerlendirme istendi mi (bir daha istenmez; iki tetik için ortak)
  static const String requestedKey = 'review_requested';
  static const int goalDays = 7;

  /// Bugünün vakitleri (imsak girmeden dünün yatsısı seriyi bozmaz)
  final PrayerTimesModel? Function() todayTimes;

  /// Başka bir pencere (izin, rıza formu, tanıtım turu) açıksa false
  final bool Function()? canPrompt;

  /// İşaret ve seri ekranda görünsün diye kısa bekleme
  final Duration delay;

  int? _baseline;
  bool _active = false;
  bool _done = false;
  Future<void> _chain = Future<void>.value();

  // Süreçte tek istek: aynı anda iki örnek (ör. yeniden kurulan ekran) ya da
  // iki tetik (seri, kullanım günü) istemesin
  static bool _requestedThisRun = false;

  @visibleForTesting
  static void debugReset() => _requestedThisRun = false;

  /// Seri bu değişiklikle hedefe ulaştı ya da hedefin üstünde arttı mı
  /// (zaman geçince seri sadece azalır; artış kullanıcının işaretidir)
  static bool reachedGoal({required int? before, required int after}) =>
      before != null && after > before && after >= goalDays;

  /// İmsak girmeden dünün yatsısı henüz kaçmış sayılmaz (takip ekranıyla aynı)
  static bool yesterdayYatsiOngoing(PrayerTimesModel? times, DateTime now) {
    try {
      final parts = times!.imsak!.split(':');
      final imsak = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
      return now.isBefore(imsak);
    } catch (e) {
      return true;
    }
  }

  /// Takip kaydındaki değişiklikleri dinlemeye başlar (tekrar çağrı etkisiz)
  void start() {
    if (_active) return;
    _active = true;
    PrayerTrackerService.changes.addListener(_onChanged);
    _enqueue();
  }

  void dispose() {
    if (!_active) return;
    _active = false;
    PrayerTrackerService.changes.removeListener(_onChanged);
  }

  /// Sıradaki denetimler bitince tamamlanır
  @visibleForTesting
  Future<void> get settled => _chain;

  void _onChanged() => _enqueue();

  void _enqueue() {
    _chain = _chain.then((_) => _evaluate());
  }

  Future<void> _evaluate() async {
    if (!_active || _done || _requestedThisRun) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(requestedKey) ?? false) {
        _done = true;
        return;
      }
      final now = DateTime.now();
      final log = await PrayerTrackerService().loadLog();
      final streak = PrayerTracker.streak(
        log,
        now,
        yesterdayYatsiOngoing: yesterdayYatsiOngoing(todayTimes(), now),
      );
      final before = _baseline;
      _baseline = streak;
      if (reachedGoal(before: before, after: streak)) {
        _done = await _requestReview(
          prefs,
          delay: delay,
          canShow: () => _active && _calmForeground(canPrompt),
        );
      }
    } catch (e) {
      debugPrint('Değerlendirme isteği yapılamadı: $e');
    }
  }
}

/// Uygulama 5 farklı günde ön planda açılınca (seriden bağımsız) aynı ömür boyu
/// tek değerlendirme isteği ([StreakReviewPrompt.requestedKey]). Kayıt küçük:
/// sayılan gün sayısı + son sayılan gün. MainWrapper açılış pencerelerinden
/// sonra başlatır; istek açılışta ya da yeni günün ilk ön plana gelişinde
/// (reklamdan/ayarlardan dönüşte değil), birkaç saniye sonra ve başka pencere
/// yokken denenir.
class UsageReviewPrompt {
  UsageReviewPrompt({
    this.canPrompt,
    this.delay = const Duration(seconds: 3),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// Uygulamanın ön planda açıldığı farklı gün sayısı
  static const String countKey = 'usage_days_count';

  /// Son sayılan gün ([PrayerTracker.epochDay])
  static const String lastDayKey = 'usage_last_day';
  static const int goalDays = 5;

  /// Başka bir pencere (izin, rıza formu, tanıtım turu) açıksa false
  final bool Function()? canPrompt;

  /// Açılışta vakitler görünsün diye bekleme
  final Duration delay;

  final DateTime Function() _clock;

  AppLifecycleListener? _lifecycle;
  bool _done = false;
  Future<void> _chain = Future<void>.value();

  /// Ön planda açılış: bugün sayılmadıysa bir gün eklenir (aynı gün ikinci
  /// açılış sayılmaz). İstek açılışta ([launch]) ya da yeni günün ilk ön plana
  /// gelişinde, gün sayısı hedefteyse istenir.
  static ({int count, bool ask}) onOpen({
    required int count,
    required int? lastDay,
    required int today,
    required bool launch,
  }) {
    final newDay = lastDay != today;
    final next = newDay ? count + 1 : count;
    return (count: next, ask: (launch || newDay) && next >= goalDays);
  }

  /// Açılışı sayar ve ön plana her dönüşü dinler (tekrar çağrı etkisiz)
  void start() {
    if (_lifecycle != null) return;
    _lifecycle = AppLifecycleListener(onResume: () => _enqueue(launch: false));
    _enqueue(launch: true);
  }

  void dispose() {
    _lifecycle?.dispose();
    _lifecycle = null;
  }

  /// Sıradaki denetimler bitince tamamlanır
  @visibleForTesting
  Future<void> get settled => _chain;

  void _enqueue({required bool launch}) {
    _chain = _chain.then((_) => _evaluate(launch: launch));
  }

  Future<void> _evaluate({required bool launch}) async {
    if (_lifecycle == null || _done || StreakReviewPrompt._requestedThisRun) {
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(StreakReviewPrompt.requestedKey) ?? false) {
        _done = true;
        return;
      }
      // Arka planda sayılmaz: ön plana dönüşte (onResume) sayılır
      if (!_inForeground()) return;
      final today = PrayerTracker.epochDay(_clock());
      final before = prefs.getInt(countKey) ?? 0;
      final open = onOpen(
        count: before,
        lastDay: prefs.getInt(lastDayKey),
        today: today,
        launch: launch,
      );
      if (open.count != before) {
        await prefs.setInt(countKey, open.count);
        await prefs.setInt(lastDayKey, today);
      }
      if (open.ask) {
        _done = await _requestReview(
          prefs,
          delay: delay,
          canShow: () => _lifecycle != null && _calmForeground(canPrompt),
        );
      }
    } catch (e) {
      debugPrint('Değerlendirme isteği yapılamadı: $e');
    }
  }
}

bool _inForeground() {
  final state = WidgetsBinding.instance.lifecycleState;
  return state == null || state == AppLifecycleState.resumed;
}

/// Uygulama ön planda ve başka pencere (izin, rıza formu, tur) açık değil
bool _calmForeground(bool Function()? canPrompt) =>
    _inForeground() && (canPrompt?.call() ?? true);

/// [delay] sonra hâlâ uygunsa ([canShow]) ve Play değerlendirmesi varsa ister;
/// istendiyse true. Önce kayıt: istek hata verse de bir daha sorulmaz.
Future<bool> _requestReview(
  SharedPreferences prefs, {
  required Duration delay,
  required bool Function() canShow,
}) async {
  if (delay > Duration.zero) await Future<void>.delayed(delay);
  if (!canShow() || StreakReviewPrompt._requestedThisRun) return false;
  final review = InAppReview.instance;
  if (!await review.isAvailable()) return false;
  if (!canShow() || StreakReviewPrompt._requestedThisRun) return false;
  StreakReviewPrompt._requestedThisRun = true;
  await prefs.setBool(StreakReviewPrompt.requestedKey, true);
  await review.requestReview();
  return true;
}
