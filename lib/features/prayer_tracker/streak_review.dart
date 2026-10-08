import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/prayer_times_model.dart';
import '../../data/services/prayer_tracker.dart';
import '../../data/services/prayer_tracker_service.dart';

/// Namaz takibinde 7 günlük tam seri uygulama içinde tamamlanınca Play'in
/// uygulama içi değerlendirme penceresi istenir: ömür boyu en fazla bir kez,
/// sadece [InAppReview.isAvailable] ise. MainWrapper açılış pencerelerinden
/// sonra başlatır (ön plan, ana isolate); bildirimdeki "Kıldım" ayrı isolate'te
/// çalıştığından bunu tetiklemez.
class StreakReviewPrompt {
  StreakReviewPrompt({
    required this.todayTimes,
    this.canPrompt,
    this.delay = const Duration(seconds: 1),
  });

  /// Değerlendirme istendi mi (bir daha istenmez)
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

  // Süreçte tek istek: aynı anda iki örnek (ör. yeniden kurulan ekran) istemesin
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
        await _request(prefs);
      }
    } catch (e) {
      debugPrint('Değerlendirme isteği yapılamadı: $e');
    }
  }

  Future<void> _request(SharedPreferences prefs) async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (!_canShowNow()) return;
    final review = InAppReview.instance;
    if (!await review.isAvailable()) return;
    if (!_canShowNow() || _requestedThisRun) return;
    // Önce kayıt: istek hata verse de bir daha sorulmaz
    _requestedThisRun = true;
    _done = true;
    await prefs.setBool(requestedKey, true);
    await review.requestReview();
  }

  bool _canShowNow() {
    if (!_active) return false;
    final state = WidgetsBinding.instance.lifecycleState;
    if (state != null && state != AppLifecycleState.resumed) return false;
    return canPrompt?.call() ?? true;
  }
}
