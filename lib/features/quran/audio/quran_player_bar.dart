import 'package:flutter/material.dart';
import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';

import '../../../data/services/quran_audio_service.dart';
import 'quran_player.dart';

/// [surah]'ı [fromAyah]'tan dinlemeye başlar (bildirim kanalı ve albüm adı
/// arayüz dilinde)
Future<void> startQuranListening(
  BuildContext context, {
  required int surah,
  required String title,
  int fromAyah = 1,
  QuranPlayer? player,
}) {
  final loc = AppLocalizations.of(context)!;
  return (player ?? QuranPlayer.instance).start(
    surah: surah,
    title: title,
    album: loc.quranTitle,
    language: Localizations.localeOf(context).languageCode,
    channelName: loc.quranAudioChannel,
    fromAyah: fromAyah,
  );
}

/// Dinleme çubuğu (okuyucunun ve sure listesinin altında, dinleme açıkken):
/// sure · ayet, kârî (dokununca seçim), önceki / sonraki ayet, oynat /
/// duraklat, tekrar (kapalı → ayet → sure) ve kapat. Hata olursa açıklama ve
/// "Tekrar Dene".
class QuranPlayerBar extends StatelessWidget {
  final QuranPlayer? player;

  const QuranPlayerBar({super.key, this.player});

  @override
  Widget build(BuildContext context) {
    final player = this.player ?? QuranPlayer.instance;
    return ListenableBuilder(
      listenable: player,
      builder: (context, _) =>
          player.active ? _bar(context, player) : const SizedBox.shrink(),
    );
  }

  Widget _bar(BuildContext context, QuranPlayer player) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final audio = player.audio;
    final ayah = player.ayah;
    final failure = player.failure;
    final timed = audio?.hasTimings ?? false;
    final (repeatIcon, repeatLabel) = switch (player.repeat) {
      QuranRepeat.off => (Icons.repeat, loc.quranAudioRepeatOff),
      QuranRepeat.ayah => (Icons.repeat_one_on, loc.quranAudioRepeatAyah),
      QuranRepeat.surah => (Icons.repeat_on, loc.quranAudioRepeatSurah),
    };
    return Material(
      color: scheme.surfaceContainerHigh,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (timed)
            ExcludeSemantics(
              child: ValueListenableBuilder<Duration>(
                valueListenable: player.position,
                builder: (context, position, _) => LinearProgressIndicator(
                  value: (position.inMilliseconds / audio!.verses.last.to)
                      .clamp(0.0, 1.0),
                  minHeight: 3,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.lg,
              AppSpacing.xs,
              AppSpacing.xs,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: player.reciters.isEmpty
                        ? null
                        : () => showReciterSheet(context, player: player),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ayah == null
                                ? player.title
                                : loc.quranAyahRef(player.title, ayah),
                            style: theme.textTheme.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (player.reciter case final reciter?)
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    reciter.name,
                                    style: theme.textTheme.bodySmall!.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_drop_down,
                                  size: 20,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: loc.quranAudioClose,
                  onPressed: player.stop,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          if (failure != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(switch (failure) {
                    QuranAudioFailure.offline => loc.quranAudioOffline,
                    QuranAudioFailure.unavailable => loc.quranAudioUnavailable,
                    QuranAudioFailure.notFound => loc.quranAudioNotFound,
                  }, style: theme.textTheme.bodyMedium),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton(
                      onPressed: () => startQuranListening(
                        context,
                        surah: player.surah!,
                        title: player.title,
                        fromAyah: ayah ?? 1,
                        player: player,
                      ),
                      child: Text(loc.retry),
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: repeatLabel,
                    onPressed: player.cycleRepeat,
                    icon: Icon(repeatIcon),
                    color: player.repeat == QuranRepeat.off
                        ? null
                        : scheme.primary,
                  ),
                  IconButton(
                    tooltip: loc.quranAudioPrevious,
                    onPressed: timed && ayah != null ? player.previous : null,
                    icon: Icon(
                      Directionality.of(context) == TextDirection.rtl
                          ? Icons.skip_next
                          : Icons.skip_previous,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  if (player.loading)
                    const SizedBox.square(
                      dimension: AppSizes.minTouch,
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
                    )
                  else
                    IconButton.filled(
                      tooltip: player.playing
                          ? loc.quranAudioPause
                          : loc.quranAudioPlay,
                      onPressed: player.toggle,
                      icon: Icon(
                        player.playing ? Icons.pause : Icons.play_arrow,
                      ),
                    ),
                  const SizedBox(width: AppSpacing.xs),
                  IconButton(
                    tooltip: loc.quranAudioNext,
                    onPressed:
                        timed && ayah != null && ayah < audio!.verses.length
                        ? player.next
                        : null,
                    icon: Icon(
                      Directionality.of(context) == TextDirection.rtl
                          ? Icons.skip_previous
                          : Icons.skip_next,
                    ),
                  ),
                  // Tekrar düğmesiyle simetri
                  const SizedBox(width: AppSizes.minTouch),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Kârî seçimi: liste (seçili işaretli), altta ses kaynağı
Future<void> showReciterSheet(BuildContext context, {QuranPlayer? player}) {
  final current = player ?? QuranPlayer.instance;
  final channelName = AppLocalizations.of(context)!.quranAudioChannel;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) {
      final loc = AppLocalizations.of(context)!;
      final theme = Theme.of(context);
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.only(
            bottom: AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Semantics(
                header: true,
                child: Text(
                  loc.quranAudioChooseReciter,
                  style: theme.textTheme.titleLarge,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final reciter in current.reciters)
              AppListTile(
                title: reciter.name,
                subtitle: reciter.style.isEmpty ? null : reciter.style,
                showChevron: false,
                trailing: reciter == current.reciter
                    ? Icon(Icons.check, color: theme.colorScheme.primary)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  current.setReciter(reciter, channelName: channelName);
                },
              ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                loc.quranAudioSource,
                style: theme.textTheme.bodySmall!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
