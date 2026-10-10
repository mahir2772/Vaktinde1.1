import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';

import '../../../data/services/dini_gunler_service.dart';
import '../../../data/services/json_service.dart';
import '../../../data/services/prayer_tracker.dart';
import '../../common/share_card.dart';

typedef _GreetingGroup = ({DiniGunTuru tur, List<String> messages});

/// Dini günler: yıl seçici + liste. Tarihler Diyanet listesinden
/// (religious_days.json), listede olmayan yıl/günler hicri hesaptan.
/// Sıradaki gün "x gün kaldı" ile vurgulanır (açılışta ona kaydırılır),
/// geçmiş günler soluk gösterilir. Tebrik mesajı olan günlerde "Tebrik gönder"
/// (greetings_<dil>.json; kopyala / metin / resimli paylaş).
class ReligiousDaysView extends StatefulWidget {
  const ReligiousDaysView({super.key});

  @override
  State<ReligiousDaysView> createState() => _ReligiousDaysViewState();
}

class _ReligiousDaysViewState extends State<ReligiousDaysView> {
  late int _selectedYear;
  late int _minYear;
  late int _maxYear;
  final GlobalKey _nextKey = GlobalKey();
  bool _scrolledToNext = false;
  // Diyanet tarihleri yüklenene kadar null (yükleniyor)
  List<ResmiDiniGun>? _resmi;
  // Tebrik mesajları (tür adı → mesajlar); yüklenemezse null, düğme çıkmaz
  Map<String, List<String>>? _greetings;
  String? _language;

  @override
  void initState() {
    super.initState();
    final year = DateTime.now().year;
    _selectedYear = year;
    _minYear = year - 1;
    _maxYear = year + 4;
    DiniGunlerService.loadResmiGunler().then((resmi) {
      if (mounted) setState(() => _resmi = resmi);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final language = Localizations.localeOf(context).languageCode;
    if (language != _language) {
      _language = language;
      _loadGreetings(language);
    }
  }

  Future<void> _loadGreetings(String language) async {
    try {
      final greetings = await JsonService().getGreetings(language);
      if (mounted && language == _language) {
        setState(() => _greetings = greetings);
      }
    } catch (_) {}
  }

  /// Günün tebrikleri; Regaib üç ayların ilk haftasında olduğundan üç aylar
  /// tebrikleri de sunulur
  List<_GreetingGroup> _greetingGroups(DiniGunTuru? tur) {
    final greetings = _greetings;
    if (greetings == null || tur == null) return const [];
    return [
      for (final t in [
        tur,
        if (tur == DiniGunTuru.regaipKandili) DiniGunTuru.ucAylar,
      ])
        if (greetings[t.name]?.isNotEmpty ?? false)
          (tur: t, messages: greetings[t.name]!),
    ];
  }

  void _showGreetings(List<_GreetingGroup> groups) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, controller) => SheetMessenger(
          child: _GreetingSheet(controller: controller, groups: groups),
        ),
      ),
    );
  }

  void _changeYear(int delta) {
    final year = _selectedYear + delta;
    if (year < _minYear || year > _maxYear) return;
    setState(() => _selectedYear = year);
  }

  /// Bugün ya da sonrasındaki ilk dini gün (yılın kalanı boşsa gelecek yıl)
  DiniGunModel? _nextDay(
    AppLocalizations loc,
    DateTime today,
    List<ResmiDiniGun> resmi,
  ) {
    for (final year in [today.year, today.year + 1]) {
      for (final day in DiniGunlerService.getYilinDiniGunleri(
        loc,
        year,
        resmi: resmi,
      )) {
        if (PrayerTracker.daysBetween(today, day.tarih) >= 0) return day;
      }
    }
    return null;
  }

  void _scrollToNextOnce() {
    if (_scrolledToNext) return;
    _scrolledToNext = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _nextKey.currentContext;
      if (!mounted || ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.3,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final localeCode = Localizations.localeOf(context).languageCode;
    final today = DateTime.now();
    final resmi = _resmi;

    final switcher = Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: _YearSwitcher(
        title: loc.religiousDaysListTitle(_selectedYear),
        onPrevious: _selectedYear > _minYear ? () => _changeYear(-1) : null,
        onNext: _selectedYear < _maxYear ? () => _changeYear(1) : null,
        previousTooltip: loc.previousYear,
        nextTooltip: loc.nextYear,
      ),
    );

    final days = resmi == null
        ? const <DiniGunModel>[]
        : DiniGunlerService.getYilinDiniGunleri(
            loc,
            _selectedYear,
            resmi: resmi,
          );
    final next = resmi == null ? null : _nextDay(loc, today, resmi);

    final Widget list;
    if (resmi == null) {
      list = const LoadingState();
    } else if (days.isEmpty) {
      list = EmptyState(
        icon: Icons.event_busy,
        title: loc.noDataForYear(_selectedYear),
      );
    } else {
      final children = <Widget>[];
      var hasNext = false;
      for (final day in days) {
        final diff = PrayerTracker.daysBetween(today, day.tarih);
        final isNext =
            next != null &&
            day.isim == next.isim &&
            PrayerTracker.daysBetween(next.tarih, day.tarih) == 0;
        hasNext |= isNext;
        // Bayram birkaç gün sürer: geçen günün tebriği 3 gün daha gönderilebilir
        final greetings = diff >= -3
            ? _greetingGroups(day.tur)
            : const <_GreetingGroup>[];
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _DayCard(
              key: isNext ? _nextKey : null,
              name: day.isim,
              // Dile uygun tam tarih ("10 Aralık 2026 Perşembe",
              // "Thursday, December 10, 2026", "الخميس، ١٠ ديسمبر ٢٠٢٦")
              date: DateFormat.yMMMMEEEEd(localeCode).format(day.tarih),
              state: isNext
                  ? _DayState.next
                  : (diff < 0 ? _DayState.past : _DayState.upcoming),
              countdown: isNext ? loc.daysLeft(diff) : null,
              onGreeting: greetings.isEmpty
                  ? null
                  : () => _showGreetings(greetings),
            ),
          ),
        );
      }
      if (hasNext) _scrollToNextOnce();
      // Hepsi çizilir (yılda ~12 gün): yılın sonlarında da sıradaki güne
      // kaydırılabilsin (tembel listede henüz çizilmemiş kart bulunamıyordu)
      list = SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xs,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      );
    }

    // Yıl seçici sabit; sıradaki güne kaydırınca da görünür kalır
    return AppScaffold(
      title: loc.religiousDaysTitle,
      body: Column(
        children: [
          switcher,
          Expanded(child: list),
        ],
      ),
    );
  }
}

class _YearSwitcher extends StatelessWidget {
  final String title;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final String previousTooltip;
  final String nextTooltip;

  const _YearSwitcher({
    required this.title,
    required this.onPrevious,
    required this.onNext,
    required this.previousTooltip,
    required this.nextTooltip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: previousTooltip,
            color: scheme.primary,
            onPressed: onPrevious,
          ),
          Expanded(
            child: Semantics(
              header: true,
              liveRegion: true,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: nextTooltip,
            color: scheme.primary,
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

enum _DayState { past, next, upcoming }

class _DayCard extends StatelessWidget {
  final String name;
  final String date;
  final _DayState state;
  final String? countdown;
  final VoidCallback? onGreeting;

  const _DayCard({
    super.key,
    required this.name,
    required this.date,
    required this.state,
    this.countdown,
    this.onGreeting,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = PrayerColors.of(context);
    final isNext = state == _DayState.next;
    final isPast = state == _DayState.past;

    final Color titleColor = isNext
        ? colors.onNextContainer
        : (isPast ? colors.past : scheme.onSurface);
    final Color subColor = isNext
        ? colors.onNextContainer
        : (isPast ? colors.past : scheme.onSurfaceVariant);
    final Color iconBackground = isNext
        ? colors.onNextContainer.withValues(alpha: 0.18)
        : (isPast ? scheme.surfaceContainerHigh : scheme.primaryContainer);
    final Color iconColor = isNext
        ? colors.onNextContainer
        : (isPast ? colors.past : scheme.onPrimaryContainer);

    return Semantics(
      selected: isNext,
      child: AppCard(
        color: isNext ? colors.nextContainer : null,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: AppSizes.iconBox,
              height: AppSizes.iconBox,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                isPast ? Icons.event_available : Icons.event,
                size: 22,
                color: iconColor,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.titleMedium!.copyWith(
                      color: titleColor,
                      fontWeight: isPast ? FontWeight.w500 : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date,
                    style: theme.textTheme.bodyMedium!.copyWith(
                      color: subColor,
                    ),
                  ),
                  if (countdown != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: colors.onNextContainer,
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                      ),
                      child: Text(
                        countdown!,
                        style: theme.textTheme.labelLarge!.copyWith(
                          color: colors.nextContainer,
                        ),
                      ),
                    ),
                  ],
                  if (onGreeting != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    TextButton.icon(
                      onPressed: onGreeting,
                      style: isNext
                          ? TextButton.styleFrom(
                              foregroundColor: colors.onNextContainer,
                            )
                          : null,
                      icon: const Icon(Icons.send_rounded, size: 20),
                      label: Text(AppLocalizations.of(context)!.sendGreeting),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tebrik mesajları: tür başına başlık + mesaj kartları (Cuma mesajlarıyla
/// aynı kart: kopyala / metni paylaş / resimli paylaş)
class _GreetingSheet extends StatelessWidget {
  final ScrollController controller;
  final List<_GreetingGroup> groups;

  const _GreetingSheet({required this.controller, required this.groups});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return ListView(
      controller: controller,
      // + gezinme çubuğu (uçtan uca): son kart altında kalmasın
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        Semantics(
          header: true,
          child: Text(
            loc.greetingsTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        for (final group in groups) ...[
          SectionHeader(
            DiniGunlerService.isimOf(group.tur, loc),
            onImage: false,
            padding: const EdgeInsetsDirectional.only(
              top: AppSpacing.lg,
              bottom: AppSpacing.sm,
            ),
          ),
          for (final message in group.messages)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: MessageCard(
                message: message,
                title: DiniGunlerService.isimOf(group.tur, loc),
                campaign: 'greeting',
              ),
            ),
        ],
      ],
    );
  }
}
