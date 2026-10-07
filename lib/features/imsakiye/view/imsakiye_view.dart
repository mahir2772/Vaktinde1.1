import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';

import '../../../data/models/prayer_times_model.dart';
import '../../../data/services/prayer_time_service.dart';
import '../../../data/services/storage_service.dart';
import '../imsakiye_logic.dart';
import '../ramadan_calendar_loader.dart';

enum ImsakiyeMode { monthly, ramadan }

class _DayRow {
  final DateTime date;
  final List<String> times; // imsak, güneş, öğle, ikindi, akşam, yatsı
  final int? ramadanDay;

  const _DayRow(this.date, this.times, this.ramadanDay);
}

List<String> _timesOf(PrayerTimesModel t) => [
  t.imsak,
  t.gunes,
  t.ogle,
  t.ikindi,
  t.aksam,
  t.yatsi,
].map((e) => e ?? '--:--').toList();

List<String> _headers(AppLocalizations loc) => [
  loc.imsak,
  loc.imsakiyeSunriseShort,
  loc.ogle,
  loc.ikindi,
  loc.aksam,
  loc.yatsi,
];

const _tabular = [FontFeature.tabularFigures()];

class ImsakiyeView extends StatefulWidget {
  const ImsakiyeView({super.key});

  @override
  State<ImsakiyeView> createState() => _ImsakiyeViewState();
}

class _ImsakiyeViewState extends State<ImsakiyeView> {
  static const double _baseRowHeight = 48;
  static const double _shareWidth = 440;
  double _rowHeight = _baseRowHeight;

  final ScrollController _scroll = ScrollController();
  late ImsakiyeMode _mode;
  late DateTime _month; // ayın 1'i
  RamadanRange? _ramadan; // Diyanet takvimi yüklenince belirlenir
  bool _modeTouched = false;

  List<_DayRow>? _rows;
  bool _loading = true;
  bool _noLocation = false;
  bool _failed = false;
  bool _sharing = false;
  String _city = '';
  int _loadId = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _mode = ImsakiyeMode.monthly;
    _loadCity();
    _init();
  }

  Future<void> _init() async {
    final calendar = await loadRamadanCalendar();
    if (!mounted) return;
    final now = DateTime.now();
    setState(() {
      _ramadan ??= calendar.currentOrNext(now);
      // Ramazan içindeysek doğrudan Ramazan imsakiyesi açılır
      if (!_modeTouched && calendar.dayOf(now) != null) {
        _mode = ImsakiyeMode.ramadan;
      }
    });
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadCity() async {
    try {
      final storage = StorageService();
      final label = cityLabel(
        await storage.loadLocation(),
        await storage.loadDistrict(),
      );
      if (mounted) setState(() => _city = label);
    } catch (_) {}
  }

  void _reload() {
    setState(() {
      _loading = true;
      _noLocation = false;
      _failed = false;
    });
    _load();
  }

  Future<void> _load() async {
    final id = ++_loadId;
    try {
      final calendar = await loadRamadanCalendar();
      if (!mounted || id != _loadId) return;
      final ramadan = _ramadan ??= calendar.currentOrNext(DateTime.now());
      final mode = _mode;
      final days = mode == ImsakiyeMode.ramadan
          ? ramadan.days
          : daysOfMonth(_month.year, _month.month);
      final service = PrayerTimeService();
      final rows = <_DayRow>[];
      for (var i = 0; i < days.length; i++) {
        final times = await service.forDate(days[i]);
        if (times == null) {
          if (!mounted || id != _loadId) return;
          setState(() {
            _rows = null;
            _noLocation = true;
            _loading = false;
          });
          return;
        }
        rows.add(
          _DayRow(
            days[i],
            _timesOf(times),
            mode == ImsakiyeMode.ramadan ? i + 1 : null,
          ),
        );
      }
      if (!mounted || id != _loadId) return;
      setState(() {
        _rows = rows;
        _loading = false;
      });
      _scrollToToday();
    } catch (_) {
      if (!mounted || id != _loadId) return;
      setState(() {
        _rows = null;
        _failed = true;
        _loading = false;
      });
    }
  }

  void _scrollToToday() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rows = _rows;
      if (!mounted || rows == null || !_scroll.hasClients) return;
      final today = dateOnly(DateTime.now());
      final index = rows.indexWhere((r) => r.date == today);
      final position = _scroll.position;
      var target = 0.0;
      if (index >= 0) {
        target =
            index * _rowHeight - (position.viewportDimension - _rowHeight) / 2;
      }
      _scroll.jumpTo(target.clamp(0.0, position.maxScrollExtent));
    });
  }

  void _shiftMonth(int delta) {
    _month = DateTime(_month.year, _month.month + delta);
    _reload();
  }

  void _setMode(ImsakiyeMode mode) {
    _modeTouched = true;
    if (mode == _mode) return;
    _mode = mode;
    _reload();
  }

  String _title(AppLocalizations loc, String lc) {
    if (_mode == ImsakiyeMode.monthly) {
      return DateFormat('MMMM yyyy', lc).format(_month);
    }
    final ramadan = _ramadan;
    return ramadan == null ? '' : loc.imsakiyeRamadanTitle(ramadan.hijriYear);
  }

  String? _rangeText(String lc) {
    final ramadan = _ramadan;
    if (_mode != ImsakiyeMode.ramadan || ramadan == null) return null;
    final start = ramadan.start;
    final end = ramadan.end;
    final startFormat = start.year == end.year ? 'd MMMM' : 'd MMMM yyyy';
    return '${DateFormat(startFormat, lc).format(start)} – '
        '${DateFormat('d MMMM yyyy', lc).format(end)}';
  }

  // Paylaşım: tablonun tamamı ekran dışında, kaydırmasız ayrı bir düzende
  // çizilir, PNG'ye çevrilir ve paylaşılır.
  Future<void> _share(AppLocalizations loc, String lc) async {
    final rows = _rows;
    if (rows == null || _sharing) return;
    setState(() => _sharing = true);

    final messenger = ScaffoldMessenger.of(context);
    final overlay = Overlay.of(context);
    final boundaryKey = GlobalKey();
    final isRamadan = _mode == ImsakiyeMode.ramadan;
    final shareTitle = isRamadan
        ? _title(loc, lc)
        : '${loc.imsakiyeTitle} · ${_title(loc, lc)}';
    final subtitle = _rangeText(lc);
    final city = _city;

    final entry = OverlayEntry(
      builder: (_) => Positioned(
        left: -_shareWidth * 3,
        top: 0,
        width: _shareWidth,
        child: IgnorePointer(
          child: MediaQuery.withNoTextScaling(
            child: RepaintBoundary(
              key: boundaryKey,
              child: _ImsakiyeShareSheet(
                appName: loc.appTitle,
                title: shareTitle,
                subtitle: subtitle,
                city: city,
                dayHeader: loc.imsakiyeDay,
                headers: _headers(loc),
                rows: rows,
                localeCode: lc,
              ),
            ),
          ),
        ),
      ),
    );

    var inserted = false;
    try {
      overlay.insert(entry);
      inserted = true;
      await WidgetsBinding.instance.endOfFrame;
      try {
        await GoogleFonts.pendingFonts();
      } catch (_) {}
      await WidgetsBinding.instance.endOfFrame;

      final boundary = boundaryKey.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary) {
        throw StateError('share boundary not found');
      }
      final image = await boundary.toImage(pixelRatio: 2.5);
      final ByteData? data;
      try {
        data = await image.toByteData(format: ui.ImageByteFormat.png);
      } finally {
        image.dispose();
      }
      if (data == null) throw StateError('png encode failed');

      entry.remove();
      inserted = false;

      const fileName = 'vaktinde_imsakiye.png';
      await Share.shareXFiles(
        [
          XFile.fromData(
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
            mimeType: 'image/png',
            name: fileName,
          ),
        ],
        fileNameOverrides: const [fileName],
        text: city.isEmpty ? shareTitle : '$shareTitle - $city',
      );
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(loc.imsakiyeShareError)));
    } finally {
      if (inserted) entry.remove();
      entry.dispose();
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final lc = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    // Büyük yazıda iki satırlı tarih hücresi sığsın (kaydırma hedefi de buna göre)
    _rowHeight = MediaQuery.textScalerOf(context).scale(_baseRowHeight);
    if (_rowHeight < _baseRowHeight) _rowHeight = _baseRowHeight;

    return AppScaffold(
      title: loc.imsakiyeTitle,
      actions: [
        if (_sharing)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.appBarTheme.foregroundColor,
                ),
              ),
            ),
          )
        else
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: loc.share,
            onPressed: (_rows == null || _loading)
                ? null
                : () => _share(loc, lc),
          ),
      ],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<ImsakiyeMode>(
                segments: [
                  ButtonSegment(
                    value: ImsakiyeMode.monthly,
                    label: Text(loc.monthly),
                    icon: const Icon(Icons.calendar_month),
                  ),
                  ButtonSegment(
                    value: ImsakiyeMode.ramadan,
                    label: Text(loc.imsakiyeRamadan),
                    icon: const Icon(Icons.nightlight_round),
                  ),
                ],
                selected: {_mode},
                showSelectedIcon: false,
                onSelectionChanged: (s) => _setMode(s.first),
                style: SegmentedButton.styleFrom(
                  minimumSize: const Size(0, AppSizes.minTouch),
                  backgroundColor: theme.cardTheme.color,
                  foregroundColor: theme.colorScheme.onSurface,
                  selectedBackgroundColor: theme.colorScheme.primary,
                  selectedForegroundColor: theme.colorScheme.onPrimary,
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
              ),
            ),
          ),
          _buildHeader(loc, lc),
          Expanded(child: _buildBody(loc, lc)),
        ],
      ),
    );
  }

  Widget _buildHeader(AppLocalizations loc, String lc) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isMonthly = _mode == ImsakiyeMode.monthly;
    final range = _rangeText(lc);
    final subStyle = theme.textTheme.bodySmall!.copyWith(
      color: scheme.onSurfaceVariant,
    );

    Widget navButton(IconData icon, String tooltip, int delta) => IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      color: scheme.primary,
      onPressed: () => _shiftMonth(delta),
    );

    return AppCard(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          if (isMonthly)
            navButton(Icons.chevron_left, loc.imsakiyePrevMonth, -1)
          else
            const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _title(loc, lc),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
                if (range != null)
                  Text(range, textAlign: TextAlign.center, style: subStyle),
                if (_city.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            _city,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: subStyle,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (isMonthly)
            navButton(Icons.chevron_right, loc.imsakiyeNextMonth, 1)
          else
            const SizedBox(width: AppSpacing.md),
        ],
      ),
    );
  }

  Widget _buildBody(AppLocalizations loc, String lc) {
    if (_loading) return const LoadingState();
    final rows = _rows;
    if (_noLocation) {
      return EmptyState(
        icon: Icons.location_off_outlined,
        title: loc.imsakiyeNoLocation,
      );
    }
    if (_failed || rows == null) {
      return ErrorState(message: loc.noData, onRetry: _reload);
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isRamadan = _mode == ImsakiyeMode.ramadan;
    final dateFlex = isRamadan ? 22 : 16;
    final today = dateOnly(DateTime.now());
    // Koyu temada başlık, bugünün satırıyla (sıradaki vakit rengi) karışmasın
    final isLight = theme.brightness == Brightness.light;
    final headerBackground = isLight
        ? scheme.primaryContainer
        : scheme.surfaceContainerHigh;
    final headerStyle = theme.textTheme.labelMedium!.copyWith(
      color: isLight ? scheme.onPrimaryContainer : scheme.primary,
      fontWeight: FontWeight.w600,
    );

    return AppCard(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 40),
            color: headerBackground,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Row(
              children: [
                Expanded(
                  flex: dateFlex,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: _fit(
                      Text(loc.imsakiyeDay, style: headerStyle),
                      AlignmentDirectional.centerStart,
                    ),
                  ),
                ),
                for (final h in _headers(loc))
                  Expanded(
                    flex: 10,
                    child: Center(
                      child: _fit(
                        Text(h, style: headerStyle),
                        Alignment.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              itemExtent: _rowHeight,
              itemCount: rows.length,
              itemBuilder: (context, i) => _buildRow(
                rows[i],
                i,
                lc,
                dateFlex,
                rows[i].date == today,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Dar ekranlarda / büyük yazı boyutunda taşma olmasın diye küçültür
  // (yan boşluk: dar ekranda sütunlar birbirine yapışmasın)
  Widget _fit(Widget child, AlignmentGeometry alignment) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 2),
    child: FittedBox(fit: BoxFit.scaleDown, alignment: alignment, child: child),
  );

  Widget _buildRow(
    _DayRow row,
    int index,
    String lc,
    int dateFlex,
    bool isToday,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = PrayerColors.of(context);
    final isLight = theme.brightness == Brightness.light;

    // Bugün: ana ekrandaki "sıradaki vakit" renkleri
    Color? background;
    if (isToday) {
      background = colors.nextContainer;
    } else if (index.isOdd) {
      background = isLight
          ? scheme.surfaceContainerLow
          : scheme.surfaceContainer;
    }
    final textColor = isToday ? colors.onNextContainer : scheme.onSurface;
    final subColor = isToday ? colors.onNextContainer : scheme.onSurfaceVariant;
    final weight = isToday ? FontWeight.w700 : FontWeight.w500;
    final dateStyle = theme.textTheme.bodyMedium!.copyWith(
      fontWeight: weight,
      color: textColor,
      height: 1.25,
    );
    final weekdayStyle = theme.textTheme.bodySmall!.copyWith(
      color: subColor,
      height: 1.25,
    );
    final timeStyle = theme.textTheme.bodyMedium!.copyWith(
      fontWeight: weight,
      color: textColor,
    );

    final ramadanDay = row.ramadanDay;
    final dateCell = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (ramadanDay != null) ...[
          Container(
            width: 26,
            height: 26,
            padding: const EdgeInsets.all(3),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isToday ? colors.onNextContainer : scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$ramadanDay',
                softWrap: false,
                style: theme.textTheme.labelMedium!.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isToday
                      ? colors.nextContainer
                      : scheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat('d MMM', lc).format(row.date), style: dateStyle),
            Text(DateFormat('EEE', lc).format(row.date), style: weekdayStyle),
          ],
        ),
      ],
    );

    return Semantics(
      selected: isToday,
      child: Container(
        color: background,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: 3,
        ),
        child: Row(
          children: [
            Expanded(
              flex: dateFlex,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: _fit(dateCell, AlignmentDirectional.centerStart),
              ),
            ),
            for (final t in row.times)
              Expanded(
                flex: 10,
                child: Center(
                  child: _fit(
                    TabularText(t, style: timeStyle),
                    Alignment.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Paylaşılan görselin düzeni: sabit genişlik, kaydırmasız, açık tema.
class _ImsakiyeShareSheet extends StatelessWidget {
  final String appName;
  final String title;
  final String? subtitle;
  final String city;
  final String dayHeader;
  final List<String> headers;
  final List<_DayRow> rows;
  final String localeCode;

  const _ImsakiyeShareSheet({
    required this.appName,
    required this.title,
    required this.subtitle,
    required this.city,
    required this.dayHeader,
    required this.headers,
    required this.rows,
    required this.localeCode,
  });

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    TextStyle style(double size, FontWeight weight, Color color) =>
        base.copyWith(
          fontSize: size,
          fontWeight: weight,
          color: color,
          height: 1.25,
          decoration: TextDecoration.none,
        );

    final isRamadan = rows.isNotEmpty && rows.first.ramadanDay != null;
    final dateFlex = isRamadan ? 30 : 24;
    final dark = Colors.blueGrey.shade900;
    final teal = Colors.teal.shade700;

    Widget fit(Widget child, AlignmentGeometry alignment) =>
        FittedBox(fit: BoxFit.scaleDown, alignment: alignment, child: child);

    Widget tableRow({
      required Widget dateCell,
      required List<Widget> cells,
      required Color color,
      required double vertical,
    }) => Container(
      color: color,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: vertical),
      child: Row(
        children: [
          Expanded(
            flex: dateFlex,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: fit(dateCell, AlignmentDirectional.centerStart),
            ),
          ),
          for (final c in cells)
            Expanded(flex: 10, child: Center(child: fit(c, Alignment.center))),
        ],
      ),
    );

    return Material(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade800, Colors.teal.shade400],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_filled,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      appName,
                      style: style(20, FontWeight.w700, Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(title, style: style(16, FontWeight.w600, Colors.white)),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      style: style(12, FontWeight.w500, Colors.white70),
                    ),
                  ),
                if (city.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.white70,
                          size: 15,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            city,
                            style: style(13, FontWeight.w500, Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          tableRow(
            dateCell: Text(dayHeader, style: style(12, FontWeight.w700, teal)),
            cells: [
              for (final h in headers)
                Text(h, style: style(12, FontWeight.w700, teal)),
            ],
            color: const Color(0xFFE0F2F1),
            vertical: 8,
          ),
          for (var i = 0; i < rows.length; i++)
            tableRow(
              dateCell: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (rows[i].ramadanDay != null) ...[
                    SizedBox(
                      width: 26,
                      child: Text(
                        '${rows[i].ramadanDay}',
                        textAlign: TextAlign.center,
                        softWrap: false,
                        style: style(12, FontWeight.w700, teal),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    '${DateFormat('d MMM', localeCode).format(rows[i].date)}  '
                    '${DateFormat('EEE', localeCode).format(rows[i].date)}',
                    style: style(12.5, FontWeight.w500, dark),
                  ),
                ],
              ),
              cells: [
                for (final t in rows[i].times)
                  Text(
                    t,
                    style: style(
                      13,
                      FontWeight.w500,
                      dark,
                    ).copyWith(fontFeatures: _tabular),
                  ),
              ],
              color: i.isOdd ? const Color(0xFFF3F8F7) : Colors.white,
              vertical: 6,
            ),
          Container(height: 4, color: teal),
        ],
      ),
    );
  }
}
