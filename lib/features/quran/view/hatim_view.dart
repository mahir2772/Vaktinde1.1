import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;
import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';

import '../../../data/services/hatim.dart';
import '../../../data/services/hatim_service.dart';
import '../../../data/services/prayer_tracker.dart';
import '../../../data/services/quran_service.dart';
import '../../common/share_card.dart';
import '../../duas/dua_data.dart';
import '../../duas/view/duas_view.dart';
import '../../imsakiye/imsakiye_logic.dart';
import '../../imsakiye/ramadan_calendar_loader.dart';
import '../../main_wrapper/main_tabs.dart';
import '../../zikirmatik/view/dhikr_names.dart';
import '../widgets/go_to_ayah_dialog.dart';
import 'surah_reader_view.dart';

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

/// Plan seçenekleri; [plan] verilirse ("Planı Değiştir") kalan sayfalar
/// için hedef değişir, yoksa yeni hatim başlar
Future<void> chooseHatimPlan(BuildContext context, {HatimPlan? plan}) async {
  final calendar = await loadRamadanCalendar();
  if (!context.mounted) return;
  final loc = AppLocalizations.of(context)!;
  final target = await showHatimSheet<DateTime>(
    context,
    (context) => HatimSheetBody(
      title: plan == null ? loc.hatimStart : loc.hatimChangePlan,
      children: _planOptions(
        context,
        plan: plan,
        calendar: calendar,
        onPick: (target) => Navigator.pop(context, target),
      ),
    ),
  );
  if (target == null) return;
  final hatim = HatimService();
  await (plan == null ? hatim.begin(target) : hatim.changeTarget(target));
}

/// Hedef seçenekleri (30 gün, 2 ay, 4 ay; Ramazan'a yakınsa "Ramazan'da
/// hatim"): günlük sayfa sayısıyla
List<Widget> _planOptions(
  BuildContext context, {
  required HatimPlan? plan,
  required RamadanCalendar calendar,
  required ValueChanged<DateTime> onPick,
}) {
  final loc = AppLocalizations.of(context)!;
  final today = PrayerTracker.day(DateTime.now());
  final remaining = plan?.remainingOn(today) ?? HatimPlan.pageCount;
  final ramadanEnd = HatimPlan.ramadanTarget(calendar, today);
  String perDay(DateTime target) => loc.hatimPagesPerDay(
    HatimPlan.goalFor(remaining, PrayerTracker.daysBetween(today, target) + 1),
  );
  return [
    for (final days in HatimPlan.optionDays)
      AppListTile(
        title:
            '${perDay(PrayerTracker.addDays(today, days))} · '
            '${loc.hatimDuration(days ~/ 30)}',
        onTap: () => onPick(PrayerTracker.addDays(today, days)),
      ),
    if (ramadanEnd != null)
      AppListTile(
        title: loc.hatimRamadan,
        subtitle: perDay(ramadanEnd),
        onTap: () => onPick(ramadanEnd),
      ),
  ];
}

/// Hatim ekranı (Kur'an listesindeki karttan; reklamsız):
/// - Sürüyor: büyük ilerleme, bugünkü okuma (sayfa aralığı, "Devam Et",
///   tek dokunuşla "Okudum", mushaftan okuyana "Sayfa Gir"), 30 cüz ızgarası
///   (dokununca işaretle / kaldır) ve ayarlar (niyet, hatırlatma, plan,
///   toplu hatim, sil)
/// - Bitti: tarih, sayaç, hatim duası ve yeni hatim
/// - Yok: açıklama ve plan seçenekleri
/// [service]: test için.
class HatimView extends StatefulWidget {
  final QuranService? service;

  const HatimView({super.key, this.service});

  @override
  State<HatimView> createState() => _HatimViewState();
}

class _HatimViewState extends State<HatimView> {
  late final QuranService _quran = widget.service ?? QuranService();
  HatimState? _state;
  QuranPages? _pages;
  RamadanCalendar? _calendar;
  Dua? _dua;

  @override
  void initState() {
    super.initState();
    HatimService.changes.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    HatimService.changes.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final state = await HatimService().load();
    QuranPages? pages;
    Dua? dua;
    RamadanCalendar? calendar;
    try {
      pages = await HatimService.loadPages();
    } catch (_) {}
    try {
      dua = (DuaLibrary.loaded ?? await DuaLibrary.load()).byId('tekabbel');
    } catch (_) {}
    if (state.plan == null) calendar = await loadRamadanCalendar();
    if (!mounted) return;
    setState(() {
      _state = state;
      _pages = pages;
      _dua = dua;
      _calendar = calendar ?? _calendar;
    });
  }

  /// Hatim bu işlemle bittiyse kısa bildirim
  void _completedSnack(bool completed) {
    if (!completed || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.hatimCompleted)),
      );
  }

  Future<void> _enterPage() async {
    final loc = AppLocalizations.of(context)!;
    final page = await showNumberDialog(
      context,
      title: loc.hatimEnterPage,
      label: loc.hatimPageLabel(HatimPlan.pageCount),
      confirmLabel: loc.save,
      max: HatimPlan.pageCount,
    );
    if (page == null) return;
    _completedSnack(await HatimService().setPosition(page));
  }

  Future<void> _toggleJuz(HatimPlan plan, QuranPages pages, int juz) async {
    final loc = AppLocalizations.of(context)!;
    final done = plan.juzState(pages, juz) == HatimJuzState.done;
    final confirmed = await showConfirmDialog(
      context,
      title: loc.quranJuz(juz),
      message: done ? loc.hatimJuzMarkUnread(juz) : loc.hatimJuzMarkRead(juz),
      confirmLabel: done ? loc.hatimUnmark : loc.hatimMark,
    );
    if (!confirmed) return;
    _completedSnack(await HatimService().toggleJuz(pages, juz));
  }

  Future<void> _editNote(HatimPlan plan) async {
    final note = await showDialog<String>(
      context: context,
      builder: (_) => _NoteDialog(initial: plan.note ?? ''),
    );
    if (note != null) await HatimService().setNote(note);
  }

  Future<void> _delete() async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showConfirmDialog(
      context,
      title: loc.hatimDelete,
      message: loc.hatimDeleteConfirm,
      confirmLabel: loc.hatimDelete,
      destructive: true,
    );
    if (confirmed) await HatimService().delete();
  }

  void _openGroup(HatimPlan? plan) =>
      showHatimSheet<void>(context, (_) => _GroupHatimSheet(note: plan?.note));

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final state = _state;
    final plan = state?.plan;
    final today = PrayerTracker.day(DateTime.now());
    final groupTile = AppListTile(
      leadingIcon: Icons.groups_outlined,
      title: loc.hatimGroup,
      subtitle: loc.hatimGroupDesc,
      onTap: () => _openGroup(plan),
    );
    return AppScaffold(
      title: loc.hatimTitle,
      showBanner: false,
      body: state == null
          ? const LoadingState()
          : ListView(
              padding: EdgeInsets.only(
                top: AppSpacing.lg,
                bottom: AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                if (plan == null) ...[
                  _Padded(
                    AppCard(
                      child: Text(
                        loc.hatimIntro,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ),
                  if (_calendar case final calendar?)
                    AppListSection(
                      title: loc.hatimStart,
                      children: _planOptions(
                        context,
                        plan: null,
                        calendar: calendar,
                        onPick: HatimService().begin,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  AppListSection(children: [groupTile]),
                ] else if (plan.isFinished) ...[
                  _Padded(_FinishedCard(plan: plan, count: state.count)),
                  if (_dua case final dua?) _Padded(_DuaCard(dua: dua)),
                  AppListSection(children: [groupTile]),
                ] else ...[
                  _Padded(_ProgressCard(plan: plan, pages: _pages)),
                  _Padded(
                    _TodayCard(
                      plan: plan,
                      today: today,
                      onRead: () => openHatimReading(context, service: _quran),
                      onMarkRead: () async =>
                          _completedSnack(await HatimService().markTodayRead()),
                      onEnterPage: _enterPage,
                    ),
                  ),
                  if (_pages case final pages?) ...[
                    SectionHeader(loc.quranTabJuz),
                    _Padded(
                      _JuzGrid(
                        plan: plan,
                        pages: pages,
                        onTap: (juz) => _toggleJuz(plan, pages, juz),
                      ),
                    ),
                  ],
                  AppListSection(
                    children: [
                      AppListTile(
                        leadingIcon: Icons.favorite_border,
                        title: loc.hatimNote,
                        subtitle: plan.note ?? loc.hatimNoteAdd,
                        onTap: () => _editNote(plan),
                      ),
                      AppListTile(
                        leadingIcon: Icons.notifications_outlined,
                        title: loc.hatimReminder,
                        subtitle: state.reminder
                            ? '${loc.hatimReminderDaily} · '
                                  '${_formatMinute(state.reminderTime, loc)}'
                            : null,
                        onTap: () => showHatimSheet<void>(
                          context,
                          (_) => HatimReminderSheet(
                            enabled: state.reminder,
                            time: state.reminderTime,
                          ),
                        ),
                      ),
                      AppListTile(
                        leadingIcon: Icons.event_outlined,
                        title: loc.hatimChangePlan,
                        onTap: () => chooseHatimPlan(context, plan: plan),
                      ),
                      groupTile,
                      AppListTile(
                        leadingIcon: Icons.delete_outline,
                        title: loc.hatimDelete,
                        onTap: _delete,
                      ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }
}

String _formatMinute(int minute, AppLocalizations loc) => formatPrayerTime(
  '${minute ~/ 60}:${(minute % 60).toString().padLeft(2, '0')}',
  loc.localeName,
);

/// Kart: yanlarda liste kenar boşluğu, altta kartlar arası boşluk
class _Padded extends StatelessWidget {
  final Widget child;

  const _Padded(this.child);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      0,
      AppSpacing.lg,
      AppSpacing.lg,
    ),
    child: child,
  );
}

/// Büyük ilerleme halkası (yüzde ortada), sayfa, cüz, hedef tarihi, niyet
class _ProgressCard extends StatelessWidget {
  final HatimPlan plan;
  final QuranPages? pages;

  const _ProgressCard({required this.plan, required this.pages});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium!.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final percent = NumberFormat.percentPattern(
      loc.localeName,
    ).format(plan.progress);
    // Izgaradaki gibi: bitmemiş ilk cüz
    final pages = this.pages;
    final juz = pages == null
        ? null
        : [
            for (var j = 1; j <= 30; j++) j,
          ].firstWhere((j) => plan.juzState(pages, j) != HatimJuzState.done);
    return AppCard(
      child: Row(
        children: [
          SizedBox.square(
            dimension: 96,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ExcludeSemantics(
                  child: CircularProgressIndicator(
                    value: plan.position / HatimPlan.pageCount,
                    strokeWidth: AppSpacing.sm,
                    backgroundColor: theme.colorScheme.primaryContainer,
                  ),
                ),
                Center(
                  child: ExcludeSemantics(
                    child: FittedBox(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Text(percent, style: theme.textTheme.titleLarge),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.hatimProgress(
                    plan.position,
                    HatimPlan.pageCount,
                    percent,
                  ),
                  style: theme.textTheme.titleMedium,
                ),
                if (juz != null) Text(loc.quranJuz(juz), style: muted),
                Text(
                  loc.hatimTargetLine(
                    DateFormat.yMMMMd(loc.localeName).format(plan.target),
                  ),
                  style: muted,
                ),
                if (plan.note case final note?)
                  Text('${loc.hatimNote}: $note', style: muted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bugünkü okuma: sayfa aralığı, okunan / hedef, "Devam Et", "Okudum" (hedef
/// tamamsa yerine onay), "Sayfa Gir"
class _TodayCard extends StatelessWidget {
  final HatimPlan plan;
  final DateTime today;
  final VoidCallback onRead;
  final VoidCallback onMarkRead;
  final VoidCallback onEnterPage;

  const _TodayCard({
    required this.plan,
    required this.today,
    required this.onRead,
    required this.onMarkRead,
    required this.onEnterPage,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final read = plan.readOn(today);
    final goal = plan.dailyGoal(today);
    final met = read >= goal;
    final range = plan.todayRange(today);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            range.from == range.to
                ? loc.quranPage(range.to)
                : loc.hatimTodayRange(range.from, range.to),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          ExcludeSemantics(
            child: LinearProgressIndicator(
              value: (read / goal).clamp(0.0, 1.0),
              minHeight: AppSpacing.sm,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              if (met) ...[
                Icon(
                  Icons.check_circle,
                  size: 20,
                  color: PrayerColors.of(context).success,
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              Expanded(
                child: Text(
                  met ? loc.hatimGoalMet : loc.hatimToday(read, goal),
                  style: theme.textTheme.bodyMedium!.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: onRead,
            icon: const Icon(Icons.auto_stories),
            label: Text(loc.hatimContinue),
          ),
          if (!met) ...[
            const SizedBox(height: AppSpacing.sm),
            FilledButton.tonalIcon(
              onPressed: onMarkRead,
              icon: const Icon(Icons.check),
              label: Text(loc.hatimMarkRead),
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          TextButton.icon(
            onPressed: onEnterPage,
            icon: const Icon(Icons.edit_outlined),
            label: Text(loc.hatimEnterPage),
          ),
        ],
      ),
    );
  }
}

/// 30 cüz: okundu (dolu), okunuyor (çerçeveli), okunmadı; dokununca onaylı
/// işaretle / kaldır
class _JuzGrid extends StatelessWidget {
  final HatimPlan plan;
  final QuranPages pages;
  final ValueChanged<int> onTap;

  const _JuzGrid({
    required this.plan,
    required this.pages,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            loc.hatimJuzHint,
            style: theme.textTheme.bodyMedium!.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 300 ? 6 : 5;
              final size =
                  (constraints.maxWidth - AppSpacing.sm * (columns - 1)) /
                  columns;
              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (var juz = 1; juz <= 30; juz++)
                    _juzCell(context, juz, size, loc, scheme),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _juzCell(
    BuildContext context,
    int juz,
    double size,
    AppLocalizations loc,
    ColorScheme scheme,
  ) {
    final state = plan.juzState(pages, juz);
    final (background, foreground, label) = switch (state) {
      HatimJuzState.done => (
        scheme.primary,
        scheme.onPrimary,
        loc.hatimJuzDone,
      ),
      HatimJuzState.current => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
        loc.hatimJuzCurrent,
      ),
      HatimJuzState.pending => (
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
        loc.hatimJuzPending,
      ),
    };
    return Semantics(
      button: true,
      label: '${loc.quranJuz(juz)}: $label',
      excludeSemantics: true,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: state == HatimJuzState.current
              ? BorderSide(color: scheme.primary, width: 2)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onTap(juz),
          child: SizedBox(
            width: size,
            height: size < AppSizes.minTouch ? AppSizes.minTouch : size,
            child: Center(
              child: FittedBox(
                child: Text(
                  '$juz',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium!.copyWith(color: foreground),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bitti: tarih, tamamlanan hatim sayısı, "Yeni Hatim Başlat"
class _FinishedCard extends StatelessWidget {
  final HatimPlan plan;
  final int count;

  const _FinishedCard({required this.plan, required this.count});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium!.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: PrayerColors.of(context).success),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(loc.hatimDone, style: theme.textTheme.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            DateFormat.yMMMMd(loc.localeName).format(plan.finished!),
            style: muted,
          ),
          if (plan.note case final note?)
            Text('${loc.hatimNote}: $note', style: muted),
          if (count > 0) Text(loc.hatimCount(count), style: muted),
          const SizedBox(height: AppSpacing.md),
          FilledButton.tonalIcon(
            onPressed: () => chooseHatimPlan(context),
            icon: const Icon(Icons.flag_outlined),
            label: Text(loc.hatimNew),
          ),
        ],
      ),
    );
  }
}

/// Hatim duası (Bakara 127): Arapça ve anlam; dokununca dua sayfası
class _DuaCard extends StatelessWidget {
  final Dua dua;

  const _DuaCard({required this.dua});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    final meaning = dua.meaningFor(lang);
    return AppCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => DuaDetailView(dua: dua)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            loc.hatimDuaHeader,
            style: theme.textTheme.titleSmall!.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            dua.arabic,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: arabicDhikrStyle(context, fontSize: 24),
          ),
          if (meaning != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(meaning, style: theme.textTheme.bodyMedium),
          ],
          if (dua.sourceFor(lang) case final source?)
            Text(
              '— $source',
              style: theme.textTheme.bodySmall!.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

/// Niyet: tek satır, en çok [HatimPlan.noteMaxLength] karakter; boş = kaldır
class _NoteDialog extends StatefulWidget {
  final String initial;

  const _NoteDialog({required this.initial});

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(loc.hatimNote),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: HatimPlan.noteMaxLength,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(hintText: loc.hatimNoteHint),
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(loc.save),
        ),
      ],
    );
  }
}

/// Toplu hatim: kişi sayısına göre cüz dağıtımı ve paylaşılacak liste
/// (kayıt tutulmaz; isimler gruba yazılır)
class _GroupHatimSheet extends StatefulWidget {
  final String? note;

  const _GroupHatimSheet({required this.note});

  @override
  State<_GroupHatimSheet> createState() => _GroupHatimSheetState();
}

class _GroupHatimSheetState extends State<_GroupHatimSheet> {
  int _people = 30;

  List<String> _lines(AppLocalizations loc) => [
    for (final (i, share) in HatimPlan.juzShares(_people).indexed)
      loc.hatimGroupLine(
        i + 1,
        share.from == share.to
            ? loc.quranJuz(share.from)
            : loc.hatimGroupRange(share.from, share.to),
      ),
  ];

  String _text(AppLocalizations loc) => [
    [loc.hatimGroup, ?widget.note].join(' · '),
    '',
    ..._lines(loc),
    '',
    loc.hatimGroupFooter,
  ].join('\n');

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return HatimSheetBody(
      title: loc.hatimGroup,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                loc.hatimGroupDesc,
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(loc.hatimGroupPeople, style: theme.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              CounterStepper(
                value: _people,
                min: 2,
                max: 30,
                semanticLabel: loc.hatimGroupPeople,
                onChanged: (value) => setState(() => _people = value),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: () => shareAsText(
                  context,
                  text: _text(loc),
                  title: loc.hatimGroup,
                  campaign: 'quran',
                ),
                icon: const Icon(Icons.share_rounded),
                label: Text(loc.hatimGroupShare),
              ),
              const SizedBox(height: AppSpacing.md),
              for (final line in _lines(loc))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Text(line, style: theme.textTheme.bodyLarge),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// "Hatırlatma": her gün seçilen saatte (varsayılan 21:00) bildirim; açılıp
/// kapanınca ve saat değişince hemen kaydedilir
class HatimReminderSheet extends StatefulWidget {
  final bool enabled;
  final int time;

  const HatimReminderSheet({
    super.key,
    required this.enabled,
    required this.time,
  });

  @override
  State<HatimReminderSheet> createState() => _HatimReminderSheetState();
}

class _HatimReminderSheetState extends State<HatimReminderSheet> {
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
    return HatimSheetBody(
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
              _formatMinute(_time, loc),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            onTap: _pickTime,
          ),
      ],
    );
  }
}

Future<T?> showHatimSheet<T>(BuildContext context, WidgetBuilder builder) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: builder,
    );

/// Alt sayfa içeriği: başlık ve satırlar (altta sistem çubuğu kadar boşluk)
class HatimSheetBody extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const HatimSheetBody({
    super.key,
    required this.title,
    required this.children,
  });

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
