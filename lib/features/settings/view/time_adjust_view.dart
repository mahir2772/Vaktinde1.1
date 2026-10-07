import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ezan_saati/core/ui/ui.dart';
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

  /// Ayarlayıcı her dokunuşta ±1 ister; art arda hızlı dokunuşlar kaybolmasın
  /// diye fark güncel değere eklenir
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

    return AppScaffold(
      title: loc.timeAdjustTitle,
      showBanner: false,
      body: _loading
          ? const LoadingState()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      InfoBanner(message: loc.timeAdjustInfo),
                      const SizedBox(height: AppSpacing.lg),
                      AbsorbPointer(
                        absorbing: _saving,
                        child: AppCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              for (final key
                                  in PrayerRefreshService.vakitKeys) ...[
                                if (key != PrayerRefreshService.vakitKeys.first)
                                  const Divider(
                                    height: 1,
                                    indent: AppSpacing.lg,
                                    endIndent: AppSpacing.lg,
                                  ),
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
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Center(
                        child: TextButton.icon(
                          onPressed: _saving || _allZero ? null : _reset,
                          icon: const Icon(Icons.restart_alt),
                          label: Text(loc.timeAdjustReset),
                        ),
                      ),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.md,
                    ),
                    child: FilledButton(
                      onPressed: _saving || !_changed ? null : () => _save(loc),
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(loc.save),
                    ),
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final value = _offsets[key]!;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSizes.listTileMinHeight),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.sm,
          AppSpacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.bodyLarge!.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (time != null)
                    Text(
                      formatPrayerTime(time, loc.localeName),
                      style: theme.textTheme.bodyMedium!.copyWith(
                        color: value == 0
                            ? scheme.onSurfaceVariant
                            : scheme.primary,
                      ),
                    ),
                ],
              ),
            ),
            CounterStepper(
              value: value,
              min: -_limit,
              max: _limit,
              semanticLabel: name,
              // İşaret RTL (Arapça) metinde yer değiştirmesin
              format: (v) => loc.timeAdjustMinutes(
                '${Unicode.LRI}${v > 0 ? '+$v' : '$v'}${Unicode.PDI}',
              ),
              onChanged: (v) => _change(key, v - value),
            ),
          ],
        ),
      ),
    );
  }
}
