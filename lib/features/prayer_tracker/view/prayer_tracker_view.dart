// ignore_for_file: empty_catches

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import '../../../data/models/prayer_times_model.dart';
import '../../../data/services/prayer_refresh_service.dart';
import '../../../data/services/prayer_tracker.dart';
import '../../../data/services/prayer_tracker_service.dart';
import '../../common/widgets/ad_banner_widget.dart';
import '../../home/view_model/home_view_model.dart';

/// Takip edilen vakitlerin ekran adları ("İmsak" anahtarı = sabah namazı)
Map<String, String> trackerPrayerNames(AppLocalizations loc) => {
  "İmsak": loc.sabah,
  "Öğle": loc.ogle,
  "İkindi": loc.ikindi,
  "Akşam": loc.aksam,
  "Yatsı": loc.yatsi,
};

/// Namaz takibi: son 7 gün, 30 günlük oran, seri ve kılınmayanları kazaya ekleme
class PrayerTrackerView extends StatefulWidget {
  const PrayerTrackerView({super.key});

  @override
  State<PrayerTrackerView> createState() => _PrayerTrackerViewState();
}

class _PrayerTrackerViewState extends State<PrayerTrackerView>
    with WidgetsBindingObserver {
  static const int _gridDays = 7;
  static const double _labelWidth = 80;

  final PrayerTrackerService _service = PrayerTrackerService();
  Map<String, int> _log = const {};
  Map<String, int> _kazaAdded = const {};
  DateTime? _since;
  bool _isLoading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    PrayerTrackerService.changes.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    PrayerTrackerService.changes.removeListener(_load);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    try {
      final log = await _service.loadLog();
      final added = await _service.loadKazaAdded();
      final since = await _service.loadSince();
      if (!mounted) return;
      setState(() {
        _log = log;
        _kazaAdded = added;
        _since = since;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  DateTime? _todayTime(PrayerTimesModel? times, String key, DateTime now) {
    if (times == null) return null;
    try {
      final parts = PrayerRefreshService.timesMap(times)[key]!.split(':');
      return DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
    } catch (e) {
      return null;
    }
  }

  // Bugünün vakti girmemişse işaretlenemez; vakitler bilinmiyorsa bugün kapalı
  bool _isDue(DateTime date, String key, PrayerTimesModel? times) {
    final now = DateTime.now();
    if (PrayerTracker.daysBetween(now, date) < 0) return true;
    if (PrayerTracker.daysBetween(now, date) > 0) return false;
    final t = _todayTime(times, key, now);
    return t != null && !now.isBefore(t);
  }

  // İmsak girmeden dünün yatsısı henüz kazaya kalmamıştır
  bool _yesterdayYatsiOngoing(PrayerTimesModel? times) {
    final now = DateTime.now();
    final imsak = _todayTime(times, "İmsak", now);
    return imsak == null || now.isBefore(imsak);
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _toggle(
    DateTime date,
    String key,
    PrayerTimesModel? times,
    AppLocalizations loc,
  ) async {
    if (!PrayerTracker.isPrayed(_log, date, key) &&
        PrayerTracker.isPrayed(_kazaAdded, date, key)) {
      _snack(loc.trackerKazaLocked);
      return;
    }
    if (!_isDue(date, key, times)) {
      _snack(loc.trackerNotYet);
      return;
    }
    final prayed = !PrayerTracker.isPrayed(_log, date, key);
    final viewModel = context.read<HomeViewModel>();
    setState(() {
      _log = PrayerTracker.withPrayed(
        _log,
        date,
        key,
        prayed,
        today: DateTime.now(),
      );
    });
    try {
      await _service.setPrayed(date, key, prayed);
      if (!prayed) await viewModel.refreshEndReminders();
    } catch (e) {
      _load();
    }
  }

  Future<void> _addToKaza(
    PrayerTimesModel? times,
    AppLocalizations loc,
  ) async {
    if (_busy) return;
    final ongoing = _yesterdayYatsiOngoing(times);
    final count = PrayerTracker.totalCount(
      PrayerTracker.kazaCandidates(
        _log,
        _kazaAdded,
        DateTime.now(),
        since: _since,
        yesterdayYatsiOngoing: ongoing,
      ),
    );
    if (count == 0) {
      _snack(loc.trackerKazaNone);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.trackerKazaButton),
        content: Text(loc.trackerKazaConfirm(count)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancel, style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            child: Text(loc.trackerKazaAdd),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final added = await _service.addMissedToKaza(
        yesterdayYatsiOngoing: ongoing,
      );
      if (mounted) {
        _snack(added > 0 ? loc.trackerKazaDone(added) : loc.trackerKazaNone);
      }
    } catch (e) {
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final times = context.watch<HomeViewModel>().prayerTimes;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.trackerTitle),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: const SafeArea(child: AdBannerWidget()),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildStats(times, loc),
                const SizedBox(height: 12),
                _buildGrid(times, loc),
                const SizedBox(height: 12),
                _buildKazaSection(times, loc),
              ],
            ),
    );
  }

  Widget _buildStats(PrayerTimesModel? times, AppLocalizations loc) {
    final now = DateTime.now();
    int todayDue = 0;
    for (final key in PrayerTracker.prayerKeys) {
      if (_isDue(now, key, times)) todayDue++;
    }
    final rate = PrayerTracker.completionRate(
      _log,
      now,
      todayDue: todayDue,
      since: _since,
    );
    final streak = PrayerTracker.streak(_log, now);
    final rateText = rate == null
        ? "–"
        : NumberFormat.percentPattern(loc.localeName).format(rate);

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.pie_chart_outline,
            title: loc.trackerCompletion,
            value: rateText,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.local_fire_department_outlined,
            title: loc.trackerStreak,
            value: loc.trackerStreakDays(streak),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Icon(icon, color: Colors.teal, size: 26),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(PrayerTimesModel? times, AppLocalizations loc) {
    final names = trackerPrayerNames(loc);
    final now = DateTime.now();
    final localeCode = Localizations.localeOf(context).toString();
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    String dayLabel(int daysAgo, DateTime date) {
      if (daysAgo == 0) return loc.trackerToday;
      if (daysAgo == 1) return loc.trackerYesterday;
      try {
        return DateFormat('EEE d', localeCode).format(date);
      } catch (e) {
        return PrayerTracker.dateKey(date).substring(5);
      }
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.trackerLast7Days,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const SizedBox(width: _labelWidth),
                for (final key in PrayerTracker.prayerKeys)
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        names[key]!,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            for (int i = 0; i < _gridDays; i++)
              _buildGridRow(
                PrayerTracker.addDays(now, -i),
                dayLabel(i, PrayerTracker.addDays(now, -i)),
                times,
                loc,
                textColor,
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                _legend(Colors.teal, Icons.check, loc.trackerLegendPrayed),
                _legend(Colors.orange, Icons.history, loc.trackerLegendKaza),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridRow(
    DateTime date,
    String label,
    PrayerTimesModel? times,
    AppLocalizations loc,
    Color? textColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: _labelWidth,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
          ),
          for (final key in PrayerTracker.prayerKeys)
            Expanded(
              child: Center(
                child: _buildCell(
                  prayed: PrayerTracker.isPrayed(_log, date, key),
                  kaza: PrayerTracker.isPrayed(_kazaAdded, date, key),
                  due: _isDue(date, key, times),
                  onTap: () => _toggle(date, key, times, loc),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCell({
    required bool prayed,
    required bool kaza,
    required bool due,
    required VoidCallback onTap,
  }) {
    Color fill = Colors.transparent;
    Color border = Colors.grey.shade400;
    Widget? icon;
    if (prayed) {
      fill = Colors.teal;
      border = Colors.teal;
      icon = const Icon(Icons.check, color: Colors.white, size: 18);
    } else if (kaza) {
      fill = Colors.orange;
      border = Colors.orange;
      icon = const Icon(Icons.history, color: Colors.white, size: 16);
    } else if (!due) {
      icon = Icon(Icons.schedule, color: Colors.grey.shade400, size: 14);
    }
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Opacity(
        opacity: due || prayed ? 1 : 0.5,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: Border.all(color: border, width: 2),
          ),
          child: icon,
        ),
      ),
    );
  }

  Widget _legend(Color color, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 12),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildKazaSection(PrayerTimesModel? times, AppLocalizations loc) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: Colors.teal, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    loc.trackerKazaInfo,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? Colors.tealAccent.shade100
                          : Colors.teal.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _busy ? null : () => _addToKaza(times, loc),
              icon: const Icon(Icons.playlist_add),
              label: Text(loc.trackerKazaButton, textAlign: TextAlign.center),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
