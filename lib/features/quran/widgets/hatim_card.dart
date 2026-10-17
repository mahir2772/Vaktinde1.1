import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;
import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';

import '../../../data/services/hatim.dart';
import '../../../data/services/hatim_service.dart';
import '../../../data/services/prayer_tracker.dart';
import '../../../data/services/quran_service.dart';
import '../../imsakiye/ramadan_calendar_loader.dart';
import '../../main_wrapper/main_tabs.dart';
import '../view/surah_reader_view.dart';
import 'go_to_ayah_dialog.dart';

/// Hatim okuması: Kur'an sekmesine geçilir (ana çerçevede), okuyucu okunacak
/// sonraki sayfanın başından hatim kipinde açılır (geri gelince sure listesi ve
/// hatim kartı). Hatim yoksa ya da bittiyse sadece Kur'an sekmesi. Ana ekranın
/// "Bugün için" satırı ve hatırlatma bildirimi ('open|hatim') kullanır.
/// [service]: test için.
Future<void> openHatimReading(
  BuildContext context, {
  QuranService? service,
}) async {
  final quran = service ?? QuranService();
  HatimPlan? plan;
  QuranPages? pages;
  List<Surah>? surahs;
  try {
    plan = (await HatimService().load()).plan;
    pages = await HatimService.loadPages();
    surahs = await quran.loadSurahs();
  } catch (_) {}
  if (!context.mounted) return;
  MainTabRequests.show(MainTab.quran);
  if (plan == null || plan.isFinished || pages == null || surahs == null) {
    return;
  }
  // Okunacak ilk sayfa: bitirilen son sayfadan sonraki
  final start = pages.startOf(plan.position + 1);
  final surah = surahs.where((s) => s.number == start.surah).firstOrNull;
  if (surah == null) return;
  await Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => SurahReaderView(
        surah: surah,
        initialAyah: start.ayah,
        service: quran,
        surahs: surahs,
        hatim: true,
      ),
    ),
  );
}

enum _HatimAction { enterPage, reminder, changePlan, delete }

/// Kur'an listesinin başındaki hatim kartı (reklamsız):
/// - Hatim yok: kısa açıklama + "Hatim Başlat" (plan seçenekleri)
/// - Sürüyor: ilerleme ölçeği "Sayfa X / 604 · %Y", "Bugün a / b sayfa",
///   "Devam Et" ve menü (Sayfa Gir, Hatırlatma, Planı Değiştir, Hatmi Sil)
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

    if (plan == null || plan.isFinished) {
      final finished = plan?.finished;
      return AppCard(
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
              onPressed: () => _choosePlan(context, plan: null, today: today),
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
      // Menü düğmesinin simgesi kartın kenar boşluğuyla hizalı
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.xs,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(loc.hatimTitle, style: theme.textTheme.titleMedium),
              ),
              PopupMenuButton<_HatimAction>(
                onSelected: (action) => _onAction(context, action, plan, today),
                itemBuilder: (_) => [
                  for (final (action, label) in [
                    (_HatimAction.enterPage, loc.hatimEnterPage),
                    (_HatimAction.reminder, loc.hatimReminder),
                    (_HatimAction.changePlan, loc.hatimChangePlan),
                    (_HatimAction.delete, loc.hatimDelete),
                  ])
                    PopupMenuItem(value: action, child: Text(label)),
                ],
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  loc.hatimProgress(
                    plan.position,
                    HatimPlan.pageCount,
                    percent,
                  ),
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
                    Expanded(
                      child: Text(loc.hatimToday(read, goal), style: muted),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  onPressed: () => openHatimReading(context, service: service),
                  icon: const Icon(Icons.auto_stories),
                  label: Text(loc.hatimContinue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onAction(
    BuildContext context,
    _HatimAction action,
    HatimPlan plan,
    DateTime today,
  ) async {
    final loc = AppLocalizations.of(context)!;
    switch (action) {
      case _HatimAction.enterPage:
        final page = await showNumberDialog(
          context,
          title: loc.hatimEnterPage,
          label: loc.hatimPageLabel(HatimPlan.pageCount),
          confirmLabel: loc.save,
          max: HatimPlan.pageCount,
        );
        if (page == null || !context.mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        if (await HatimService().setPosition(page)) {
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(loc.hatimCompleted)));
        }
      case _HatimAction.reminder:
        await _showSheet<void>(
          context,
          (_) =>
              _ReminderSheet(enabled: state.reminder, time: state.reminderTime),
        );
      case _HatimAction.changePlan:
        await _choosePlan(context, plan: plan, today: today);
      case _HatimAction.delete:
        final confirmed = await showConfirmDialog(
          context,
          title: loc.hatimDelete,
          message: loc.hatimDeleteConfirm,
          confirmLabel: loc.hatimDelete,
          destructive: true,
        );
        if (confirmed) await HatimService().delete();
    }
  }

  /// Plan seçenekleri; [plan] verilirse ("Planı Değiştir") kalan sayfalar
  /// için hedef değişir, yoksa yeni hatim başlar
  Future<void> _choosePlan(
    BuildContext context, {
    required HatimPlan? plan,
    required DateTime today,
  }) async {
    final calendar = await loadRamadanCalendar();
    if (!context.mounted) return;
    final loc = AppLocalizations.of(context)!;
    final remaining = plan?.remainingOn(today) ?? HatimPlan.pageCount;
    final ramadanEnd = HatimPlan.ramadanTarget(calendar, today);
    String perDay(DateTime target) => loc.hatimPagesPerDay(
      HatimPlan.goalFor(
        remaining,
        PrayerTracker.daysBetween(today, target) + 1,
      ),
    );

    final target = await _showSheet<DateTime>(
      context,
      (context) => _SheetBody(
        title: plan == null ? loc.hatimStart : loc.hatimChangePlan,
        children: [
          for (final days in HatimPlan.optionDays)
            AppListTile(
              title:
                  '${perDay(PrayerTracker.addDays(today, days))} · '
                  '${loc.hatimDuration(days ~/ 30)}',
              onTap: () =>
                  Navigator.pop(context, PrayerTracker.addDays(today, days)),
            ),
          if (ramadanEnd != null)
            AppListTile(
              title: loc.hatimRamadan,
              subtitle: perDay(ramadanEnd),
              onTap: () => Navigator.pop(context, ramadanEnd),
            ),
        ],
      ),
    );
    if (target == null) return;
    final hatim = HatimService();
    await (plan == null ? hatim.begin(target) : hatim.changeTarget(target));
  }
}

/// "Hatırlatma": her gün seçilen saatte (varsayılan 21:00) bildirim; açılıp
/// kapanınca ve saat değişince hemen kaydedilir
class _ReminderSheet extends StatefulWidget {
  final bool enabled;
  final int time;

  const _ReminderSheet({required this.enabled, required this.time});

  @override
  State<_ReminderSheet> createState() => _ReminderSheetState();
}

class _ReminderSheetState extends State<_ReminderSheet> {
  late bool _enabled = widget.enabled;
  late int _time = widget.time;

  void _setEnabled(bool value) {
    setState(() => _enabled = value);
    HatimService().setReminder(enabled: value);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _time ~/ 60, minute: _time % 60),
    );
    if (picked == null || !mounted) return;
    final time = picked.hour * 60 + picked.minute;
    setState(() => _time = time);
    HatimService().setReminder(time: time);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final time = formatPrayerTime(
      '${_time ~/ 60}:${(_time % 60).toString().padLeft(2, '0')}',
      loc.localeName,
    );
    return _SheetBody(
      title: loc.hatimReminder,
      children: [
        AppListTile(
          leadingIcon: Icons.notifications_outlined,
          title: loc.hatimReminderDaily,
          showChevron: false,
          trailing: Switch(value: _enabled, onChanged: _setEnabled),
          onTap: () => _setEnabled(!_enabled),
        ),
        if (_enabled)
          AppListTile(
            leadingIcon: Icons.schedule,
            title: loc.hatimReminderTime,
            trailing: Text(
              time,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            onTap: _pickTime,
          ),
      ],
    );
  }
}

Future<T?> _showSheet<T>(BuildContext context, WidgetBuilder builder) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: builder,
    );

/// Alt sayfa içeriği: başlık ve satırlar (altta sistem çubuğu kadar boşluk)
class _SheetBody extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SheetBody({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Semantics(
              header: true,
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...children,
        ],
      ),
    );
  }
}
