// ignore_for_file: deprecated_member_use

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ezan_saati/l10n/app_localizations.dart';
import '../../../data/services/prayer_refresh_service.dart';
import '../../../data/services/prayer_time_service.dart';
import '../../../data/services/storage_service.dart';
import '../../home/view_model/home_view_model.dart';

/// Vakit ince ayarı: her vakit -30..+30 dk (bölgedeki caminin vakitlerine uydurmak için)
class TimeAdjustView extends StatefulWidget {
  const TimeAdjustView({super.key});

  @override
  State<TimeAdjustView> createState() => _TimeAdjustViewState();
}

class _TimeAdjustViewState extends State<TimeAdjustView> {
  static const int _limit = 30;

  final StorageService _storage = StorageService();
  final Map<String, int> _offsets = {
    for (final key in PrayerRefreshService.vakitKeys) key: 0,
  };
  Map<String, int> _savedOffsets = {};
  ({double lat, double lng})? _coords;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final saved = await _storage.loadTimeOffsets();
    final coords = await _storage.loadCoordinates();
    if (!mounted) return;
    setState(() {
      for (final key in PrayerRefreshService.vakitKeys) {
        _offsets[key] = (saved[key] ?? 0).clamp(-_limit, _limit);
      }
      _savedOffsets = Map.of(_offsets);
      _coords = coords;
      _loading = false;
    });
  }

  bool get _changed => PrayerRefreshService.vakitKeys.any(
    (key) => _offsets[key] != _savedOffsets[key],
  );

  bool get _allZero => _offsets.values.every((v) => v == 0);

  void _change(String key, int delta) {
    setState(() {
      _offsets[key] = (_offsets[key]! + delta).clamp(-_limit, _limit);
    });
  }

  void _reset() {
    setState(() {
      for (final key in PrayerRefreshService.vakitKeys) {
        _offsets[key] = 0;
      }
    });
  }

  Future<void> _save(AppLocalizations loc) async {
    final viewModel = context.read<HomeViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    try {
      // Sıfır olan vakitler kaydedilmez
      await _storage.saveTimeOffsets({
        for (final entry in _offsets.entries)
          if (entry.value != 0) entry.key: entry.value,
      });
      // Bugünün vakitleri, widget'lar, kalıcı bildirim ve alarmlar yenilenir
      await viewModel.applyTimeOffsets();
    } catch (e) {
      debugPrint("Vakit ince ayarı kaydedilemedi: $e");
    }
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(loc.timeAdjustSaved)));
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final names = PrayerRefreshService.vakitNames(loc);

    // Ayarlı vakitlerin önizlemesi (koordinat yoksa gösterilmez)
    Map<String, String>? preview;
    if (_coords != null) {
      try {
        preview = PrayerRefreshService.timesMap(
          PrayerTimeService().calculate(
            _coords!.lat,
            _coords!.lng,
            offsets: _offsets,
          ),
        );
      } catch (e) {
        preview = null;
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text(loc.timeAdjustTitle), centerTitle: true),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _loading || _saving || !_changed
                  ? null
                  : () => _save(loc),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(loc.save),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: Colors.teal),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          loc.timeAdjustInfo,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      for (final key in PrayerRefreshService.vakitKeys) ...[
                        if (key != PrayerRefreshService.vakitKeys.first)
                          const Divider(height: 1),
                        _buildRow(
                          context,
                          loc,
                          key,
                          names[key]!,
                          preview?[key],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton.icon(
                    onPressed: _saving || _allZero ? null : _reset,
                    icon: const Icon(Icons.restart_alt),
                    label: Text(loc.timeAdjustReset),
                    style: TextButton.styleFrom(foregroundColor: Colors.teal),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    AppLocalizations loc,
    String key,
    String name,
    String? time,
  ) {
    final value = _offsets[key]!;
    final valueText = value > 0 ? "+$value" : "$value";
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (time != null)
                  Text(
                    time,
                    style: TextStyle(color: Theme.of(context).hintColor),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            color: Colors.teal,
            onPressed: _saving || value <= -_limit
                ? null
                : () => _change(key, -1),
          ),
          SizedBox(
            width: 80,
            child: Text(
              // İşaret RTL (Arapça) metinde yer değiştirmesin
              loc.timeAdjustMinutes('${Unicode.LRI}$valueText${Unicode.PDI}'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: value == 0 ? Theme.of(context).hintColor : Colors.teal,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            color: Colors.teal,
            onPressed: _saving || value >= _limit
                ? null
                : () => _change(key, 1),
          ),
        ],
      ),
    );
  }
}
