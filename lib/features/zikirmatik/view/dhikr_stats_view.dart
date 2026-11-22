import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import '../view_model/zikir_view_model.dart';

/// Zikir istatistikleri: bu ayın günleri / bu yılın ayları (çubuk grafik)
class DhikrStatsView extends StatelessWidget {
  const DhikrStatsView({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 2,
      child: AppScaffold(
        title: loc.statisticsTitle,
        bottom: TabBar(
          tabs: [
            Tab(text: loc.monthly),
            Tab(text: loc.yearly),
          ],
        ),
        body: Consumer<ZikirViewModel>(
          builder: (context, viewModel, child) {
            return TabBarView(
              children: [
                _StatsTab(stats: viewModel.dailyStats, monthly: true),
                _StatsTab(stats: viewModel.dailyStats, monthly: false),
              ],
            );
          },
        ),
      ),
    );
  }
}

String _two(int n) => n.toString().padLeft(2, '0');

class _StatsTab extends StatelessWidget {
  final Map<String, int> stats;
  final bool monthly;

  const _StatsTab({required this.stats, required this.monthly});

  String _monthName(String locale, int year, int month) {
    try {
      return DateFormat.MMM(locale).format(DateTime(year, month));
    } catch (_) {
      return '$month';
    }
  }

  String _periodTitle(String locale, DateTime now) {
    if (!monthly) return '${now.year}';
    try {
      return DateFormat.yMMMM(locale).format(now);
    } catch (_) {
      return '${_two(now.month)}.${now.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final now = DateTime.now();
    final values = <int>[];
    final labels = <String>[];

    if (monthly) {
      final days = DateUtils.getDaysInMonth(now.year, now.month);
      for (var day = 1; day <= days; day++) {
        values.add(stats['${now.year}-${_two(now.month)}-${_two(day)}'] ?? 0);
        labels.add('$day');
      }
    } else {
      for (var month = 1; month <= 12; month++) {
        final prefix = '${now.year}-${_two(month)}-';
        var sum = 0;
        stats.forEach((key, value) {
          if (key.startsWith(prefix)) sum += value;
        });
        values.add(sum);
        labels.add(_monthName(loc.localeName, now.year, month));
      }
    }
    final total = values.fold<int>(0, (a, b) => a + b);
    final today = stats['${now.year}-${_two(now.month)}-${_two(now.day)}'] ?? 0;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          children: [
            Expanded(
              child: StatTile(
                value: '$total',
                label: loc.totalDhikr,
                icon: Icons.functions,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: StatTile(
                value: '$today',
                label: loc.today,
                icon: Icons.today_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Text(
                  _periodTitle(loc.localeName, now),
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 260,
                child: _BarChart(
                  values: values,
                  labels: labels,
                  highlight: monthly ? now.day - 1 : now.month - 1,
                  itemWidth: monthly ? 36 : 52,
                ),
              ),
            ],
          ),
        ),
        if (total == 0)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            child: Text(
              loc.statsEmpty,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium!.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

/// Kaydırılabilir çubuk grafik; etiketler çubuklarla birlikte kayar.
/// Bugün/bu ay koyu, diğerleri açık marka tonunda; açılışta görünür kaydırılır.
class _BarChart extends StatefulWidget {
  final List<int> values;
  final List<String> labels;
  final int highlight;
  final double itemWidth;

  const _BarChart({
    required this.values,
    required this.labels,
    required this.highlight,
    required this.itemWidth,
  });

  @override
  State<_BarChart> createState() => _BarChartState();
}

class _BarChartState extends State<_BarChart> {
  static const double _valueHeight = 22;
  static const double _labelHeight = 28;
  static const int _gridLines = 5;

  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealHighlight());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _revealHighlight() {
    if (!mounted || !_controller.hasClients) return;
    final position = _controller.position;
    final end = (widget.highlight + 1) * widget.itemWidth;
    final offset = end - position.viewportDimension + widget.itemWidth;
    if (offset > 0) {
      _controller.jumpTo(offset.clamp(0.0, position.maxScrollExtent));
    }
  }

  /// Y ekseni üst sınırı: 10, 20 … 50, 100 … 500, 1000 … şeklinde yuvarlak
  static int _niceTopMax(int maxValue) {
    var top = 10;
    while (top < maxValue) {
      if (top < 50) {
        top += 10;
      } else if (top < 500) {
        top += 50;
      } else if (top < 5000) {
        top += 500;
      } else if (top < 50000) {
        top += 5000;
      } else {
        top += 50000;
      }
    }
    return top;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final values = widget.values;
    final maxValue = values.isEmpty ? 0 : values.reduce(math.max);
    final topMax = _niceTopMax(maxValue);
    final step = topMax / _gridLines;
    final axisStyle = theme.textTheme.bodySmall!.copyWith(
      color: scheme.onSurfaceVariant,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final plotHeight = math.max(
          0.0,
          constraints.maxHeight - _valueHeight - _labelHeight,
        );
        return Row(
          children: [
            // Y ekseni
            SizedBox(
              width: 44,
              child: Stack(
                children: [
                  for (var i = 0; i <= _gridLines; i++)
                    PositionedDirectional(
                      top: _valueHeight + plotHeight * i / _gridLines - 10,
                      height: 20,
                      start: 0,
                      end: 0,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerEnd,
                        child: Text(
                          '${(topMax - step * i).round()}',
                          style: axisStyle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _GridPainter(
                        top: _valueHeight,
                        height: plotHeight,
                        lines: _gridLines,
                        color: scheme.outlineVariant,
                      ),
                    ),
                  ),
                  ListView.builder(
                    controller: _controller,
                    scrollDirection: Axis.horizontal,
                    itemCount: values.length,
                    itemExtent: widget.itemWidth,
                    itemBuilder: (context, index) =>
                        _bar(context, index, plotHeight, topMax),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _bar(BuildContext context, int index, double plotHeight, int topMax) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final value = widget.values[index];
    final label = widget.labels[index];
    final highlighted = index == widget.highlight;
    final color = highlighted
        ? scheme.primary
        : scheme.primary.withValues(alpha: 0.5);
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Column(
        children: [
          SizedBox(
            height: _valueHeight,
            child: value > 0
                ? Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '$value',
                        style: theme.textTheme.labelSmall!.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                  )
                : null,
          ),
          SizedBox(
            height: plotHeight,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: topMax == 0 ? 0 : value / topMax,
                widthFactor: 0.66,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: _labelHeight,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall!.copyWith(
                    color: highlighted
                        ? scheme.primary
                        : scheme.onSurfaceVariant,
                    fontWeight: highlighted ? FontWeight.w700 : null,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final double top;
  final double height;
  final int lines;
  final Color color;

  _GridPainter({
    required this.top,
    required this.height,
    required this.lines,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var i = 0; i <= lines; i++) {
      final y = top + height * i / lines;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) =>
      old.top != top ||
      old.height != height ||
      old.lines != lines ||
      old.color != color;
}
