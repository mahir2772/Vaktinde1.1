import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';

import '../../../data/services/quran_service.dart';

/// Görünümün simgesi (okuyucu çubuğundaki düğme de bunu gösterir)
IconData quranViewModeIcon(QuranViewMode mode) => switch (mode) {
  QuranViewMode.page => Icons.menu_book_outlined,
  QuranViewMode.ayah => Icons.view_agenda_outlined,
  QuranViewMode.translation => Icons.translate,
};

/// "Görünüm" alt sayfası: Sayfa / Ayet ayet / Meal (Arapça arayüzde meal
/// yok) ve Arapça / meal yazı boyutu (A- / A+). Seçimler hemen uygulanır;
/// sayfa açık kalır, okuyucu arkada güncellenir.
Future<void> showQuranViewSettings(
  BuildContext context, {
  required QuranViewMode mode,
  required bool translationAvailable,
  required double fontScale,
  required double translationScale,
  required ValueChanged<QuranViewMode> onModeChanged,
  required ValueChanged<double> onFontScaleChanged,
  required ValueChanged<double> onTranslationScaleChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => QuranViewSettings(
      mode: mode,
      translationAvailable: translationAvailable,
      fontScale: fontScale,
      translationScale: translationScale,
      onModeChanged: onModeChanged,
      onFontScaleChanged: onFontScaleChanged,
      onTranslationScaleChanged: onTranslationScaleChanged,
    ),
  );
}

class QuranViewSettings extends StatefulWidget {
  final QuranViewMode mode;
  final bool translationAvailable;
  final double fontScale;
  final double translationScale;
  final ValueChanged<QuranViewMode> onModeChanged;
  final ValueChanged<double> onFontScaleChanged;
  final ValueChanged<double> onTranslationScaleChanged;

  const QuranViewSettings({
    super.key,
    required this.mode,
    required this.translationAvailable,
    required this.fontScale,
    required this.translationScale,
    required this.onModeChanged,
    required this.onFontScaleChanged,
    required this.onTranslationScaleChanged,
  });

  @override
  State<QuranViewSettings> createState() => _QuranViewSettingsState();
}

class _QuranViewSettingsState extends State<QuranViewSettings> {
  late QuranViewMode _mode = widget.mode;
  late double _fontScale = widget.fontScale;
  late double _translationScale = widget.translationScale;

  void _setMode(QuranViewMode? mode) {
    if (mode == null || mode == _mode) return;
    setState(() => _mode = mode);
    widget.onModeChanged(mode);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final modes = [
      QuranViewMode.page,
      QuranViewMode.ayah,
      if (widget.translationAvailable) QuranViewMode.translation,
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Semantics(
              header: true,
              child: Text(
                loc.quranViewSettings,
                style: theme.textTheme.titleLarge,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          RadioGroup<QuranViewMode>(
            groupValue: _mode,
            onChanged: _setMode,
            child: Column(
              children: [
                for (final mode in modes)
                  RadioListTile<QuranViewMode>(
                    value: mode,
                    selected: mode == _mode,
                    controlAffinity: ListTileControlAffinity.trailing,
                    contentPadding: const EdgeInsetsDirectional.only(
                      start: AppSpacing.xl,
                      end: AppSpacing.md,
                    ),
                    secondary: Icon(
                      quranViewModeIcon(mode),
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(switch (mode) {
                      QuranViewMode.page => loc.quranModePage,
                      QuranViewMode.ayah => loc.quranModeAyah,
                      QuranViewMode.translation => loc.quranModeTranslation,
                    }),
                    subtitle: Text(switch (mode) {
                      QuranViewMode.page => loc.quranModePageDesc,
                      QuranViewMode.ayah => loc.quranModeAyahDesc,
                      QuranViewMode.translation => loc.quranModeTranslationDesc,
                    }),
                  ),
              ],
            ),
          ),
          const Divider(
            height: AppSpacing.xl,
            indent: AppSpacing.xl,
            endIndent: AppSpacing.xl,
          ),
          _ScaleRow(
            label: loc.quranArabicSize,
            value: _fontScale,
            smallerTooltip: loc.quranFontSmaller,
            largerTooltip: loc.quranFontLarger,
            onChanged: (value) {
              setState(() => _fontScale = value);
              widget.onFontScaleChanged(value);
            },
          ),
          if (widget.translationAvailable)
            _ScaleRow(
              label: loc.quranTranslationSize,
              value: _translationScale,
              smallerTooltip: loc.quranTranslationSmaller,
              largerTooltip: loc.quranTranslationLarger,
              onChanged: (value) {
                setState(() => _translationScale = value);
                widget.onTranslationScaleChanged(value);
              },
            ),
        ],
      ),
    );
  }
}

/// Yazı boyutu satırı: ad, A-, yüzde, A+ (sınırda düğme kapanır)
class _ScaleRow extends StatelessWidget {
  final String label;
  final double value;
  final String smallerTooltip;
  final String largerTooltip;
  final ValueChanged<double> onChanged;

  const _ScaleRow({
    required this.label,
    required this.value,
    required this.smallerTooltip,
    required this.largerTooltip,
    required this.onChanged,
  });

  void _step(int direction) {
    final next = QuranService.clampFontScale(
      value + direction * QuranService.fontScaleStep,
    );
    if (next != value) onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final percent = NumberFormat.percentPattern(locale).format(value);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
          const SizedBox(width: AppSpacing.sm),
          IconButton.filledTonal(
            tooltip: smallerTooltip,
            onPressed: value > QuranService.minFontScale
                ? () => _step(-1)
                : null,
            icon: const Icon(Icons.text_decrease),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Text(
                percent,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall,
              ),
            ),
          ),
          IconButton.filledTonal(
            tooltip: largerTooltip,
            onPressed: value < QuranService.maxFontScale
                ? () => _step(1)
                : null,
            icon: const Icon(Icons.text_increase),
          ),
        ],
      ),
    );
  }
}
