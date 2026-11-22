import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;
import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';

import '../../../data/services/hatim.dart';
import '../../../data/services/hatim_service.dart';
import '../../../data/services/prayer_tracker.dart';
import '../../../data/services/quran_service.dart';
import '../view/hatim_view.dart';

/// Kur'an listesinin başındaki hatim kartı (reklamsız):
/// - Hatim yok: kısa açıklama + "Hatim Başlat" (plan seçenekleri)
/// - Sürüyor: ilerleme ölçeği "Sayfa X / 604 · %Y", "Bugün a / b sayfa",
///   "Devam Et" ve (hedef tamam değilse) tek dokunuşla "Okudum"; karta
///   dokununca Hatim ekranı (cüzler, niyet, hatırlatma, plan, toplu hatim)
/// - Bitti: tarih, tamamlanan hatim sayısı ve "Yeni Hatim Başlat"
class HatimCard extends StatelessWidget {
  final HatimState state;
  final QuranService service;

  const HatimCard({super.key, required this.state, required this.service});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodyMedium!.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final today = PrayerTracker.day(DateTime.now());
    final plan = state.plan;
    void openDetails() => Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => HatimView(service: service)),
    );

    if (plan == null || plan.isFinished) {
      final finished = plan?.finished;
      return AppCard(
        onTap: openDetails,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (finished != null) ...[
                  Icon(
                    Icons.check_circle,
                    color: PrayerColors.of(context).success,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: Text(
                    finished == null ? loc.hatimTitle : loc.hatimDone,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            if (finished == null)
              Text(loc.hatimIntro, style: muted)
            else ...[
              Text(
                DateFormat.yMMMMd(loc.localeName).format(finished),
                style: muted,
              ),
              if (state.count > 0)
                Text(loc.hatimCount(state.count), style: muted),
            ],
            const SizedBox(height: AppSpacing.md),
            FilledButton.tonalIcon(
              onPressed: () => chooseHatimPlan(context),
              icon: const Icon(Icons.flag_outlined),
              label: Text(finished == null ? loc.hatimStart : loc.hatimNew),
            ),
          ],
        ),
      );
    }

    final read = plan.readOn(today);
    final goal = plan.dailyGoal(today);
    final percent = NumberFormat.percentPattern(
      loc.localeName,
    ).format(plan.progress);
    return AppCard(
      onTap: openDetails,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(loc.hatimTitle, style: theme.textTheme.titleMedium),
              ),
              Tooltip(
                message: loc.hatimDetails,
                child: Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.chevron_left
                      : Icons.chevron_right,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            loc.hatimProgress(plan.position, HatimPlan.pageCount, percent),
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          // Ölçek: dolgu marka rengi, iz aynı tonun açığı (temadan);
          // değer üstteki yazıda (ekran okuyucu onu okur)
          ExcludeSemantics(
            child: LinearProgressIndicator(
              value: plan.position / HatimPlan.pageCount,
              minHeight: AppSpacing.sm,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              if (read >= goal) ...[
                Icon(
                  Icons.check_circle,
                  size: 20,
                  color: PrayerColors.of(context).success,
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              Expanded(child: Text(loc.hatimToday(read, goal), style: muted)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: () => openHatimReading(context, service: service),
            icon: const Icon(Icons.auto_stories),
            label: Text(loc.hatimContinue),
          ),
          if (read < goal) ...[
            const SizedBox(height: AppSpacing.sm),
            FilledButton.tonalIcon(
              onPressed: () => HatimService().markTodayRead(),
              icon: const Icon(Icons.check),
              label: Text(loc.hatimMarkRead),
            ),
          ],
        ],
      ),
    );
  }
}
