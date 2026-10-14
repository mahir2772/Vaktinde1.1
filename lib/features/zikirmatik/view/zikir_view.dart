import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import '../view_model/zikir_view_model.dart';
import '../volume_keys.dart';
import '../zikir_logic.dart';
import 'dhikr_list_view.dart';
import 'dhikr_names.dart';
import 'dhikr_stats_view.dart';
import 'zikir_settings_view.dart';

/// Zikirmatik sekmesi: seçili zikir (kaydırınca / oklarla önceki-sonraki) +
/// hedef, büyük sayaç (modern: hedef halkalı düğme, klasik: tesbih) ve altta
/// "Sayacı Düzenle". Sıfırla üst çubukta (onaylı). Sayacın çevresindeki boş
/// alana dokunmak da sayar. "Ses tuşlarıyla say" açıksa sekme görünür ve
/// uygulama ön plandayken ses tuşları sayar (ZikirVolumeKeys).
class ZikirView extends StatefulWidget {
  const ZikirView({super.key});

  /// Büyük sayaç ve hedef halkası (testler)
  static const Key counterKey = ValueKey('zikir_counter');
  static const Key ringKey = ValueKey('zikir_ring');

  /// Seçili zikir kartı (kaydırılır)
  static const Key headerKey = ValueKey('zikir_header');

  @override
  State<ZikirView> createState() => _ZikirViewState();
}

class _ZikirViewState extends State<ZikirView> with WidgetsBindingObserver {
  late final ZikirViewModel _viewModel;
  late final ZikirVolumeKeys _volumeKeys;

  // Sekme görünür (IndexedStack) ve üstünde sayfa/pencere yok
  bool _visible = false;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Durum henüz bildirilmediyse (açılış) ön planda sayılır
    final state = WidgetsBinding.instance.lifecycleState;
    _foreground = state == null || state == AppLifecycleState.resumed;
    _viewModel = context.read<ZikirViewModel>();
    _volumeKeys = ZikirVolumeKeys(onKey: _onVolumeKey);
    _viewModel.addListener(_syncVolumeKeys);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Gizli sekme (IndexedStack), üstüne açılan sayfa ya da pencere (sıfırla
    // onayı, ayarlar): ses tuşları sisteme döner
    _visible =
        Visibility.of(context) &&
        TickerMode.of(context) &&
        (ModalRoute.isCurrentOf(context) ?? true);
    _syncVolumeKeys();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // inactive/hidden/paused/detached: ses tuşları sayılmaz
    _foreground = state == AppLifecycleState.resumed;
    _syncVolumeKeys();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _viewModel.removeListener(_syncVolumeKeys);
    _volumeKeys.dispose();
    super.dispose();
  }

  void _syncVolumeKeys() {
    _volumeKeys.update(
      _visible && _foreground && _viewModel.isVolumeKeysEnabled,
    );
  }

  void _onVolumeKey(int delta) {
    if (delta > 0) {
      _viewModel.increment();
    } else {
      _viewModel.decrement();
    }
  }

  void _open(Widget page) {
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        // Dört düğmeyle dar ekranda / büyük yazıda tam ad sığmazsa kısa ad
        title: _FittingTitle(full: loc.zikirmatikTitle, short: loc.navZikir),
        automaticallyImplyLeading: false,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: loc.resetCounter,
            onPressed: () => _confirmReset(context, _viewModel, loc),
          ),
          IconButton(
            icon: const Icon(Icons.list_alt_rounded),
            tooltip: loc.dhikrListTitle,
            onPressed: () => _open(const DhikrListView()),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: loc.statisticsTitle,
            onPressed: () => _open(const DhikrStatsView()),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: loc.zikirSettings,
            onPressed: () => _open(const ZikirSettingsView()),
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<ZikirViewModel>(
          builder: (context, viewModel, child) {
            final name = dhikrDisplayName(viewModel.selectedDhikr, loc);
            final arabic = viewModel.getArabicForDhikr(viewModel.selectedDhikr);
            final progress = viewModel.progress;
            void editCount() => _editCount(context, viewModel, loc);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    0,
                  ),
                  child: _DhikrHeader(
                    dhikrId: viewModel.selectedDhikr,
                    name: name,
                    arabic: arabic,
                    targetLabel: loc.targetCount(viewModel.target),
                    onEditTarget: () => _editTarget(context, viewModel, loc),
                    onPrevious: () => viewModel.selectAdjacentDhikr(-1),
                    onNext: () => viewModel.selectAdjacentDhikr(1),
                  ),
                ),
                Expanded(
                  // İlk ziyarette ipucu sayacın üstünde yüzer (küçük ekranda
                  // sayaç sıkışmaz)
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: viewModel.viewMode == 0
                            ? _ModernCounter(
                                viewModel: viewModel,
                                progress: progress,
                                dhikrName: name,
                                onEdit: editCount,
                              )
                            : _ClassicTasbihView(
                                viewModel: viewModel,
                                progress: progress,
                                dhikrName: name,
                                onEdit: editCount,
                              ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: FeatureTip(
                          id: 'zikir',
                          icon: Icons.swipe_outlined,
                          message: loc.tipZikir,
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          floating: true,
                        ),
                      ),
                    ],
                  ),
                ),
                _ActionRow(onEdit: editCount),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Üst çubuk başlığı: [full] sığmıyorsa üç noktalı ad yerine [short]
/// ("Compteur de dhi…" değil "Dhikr")
class _FittingTitle extends StatelessWidget {
  final String full;
  final String short;

  const _FittingTitle({required this.full, required this.short});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: full, style: DefaultTextStyle.of(context).style),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          maxLines: 1,
        )..layout();
        final fits = painter.width <= constraints.maxWidth;
        painter.dispose();
        return Text(
          fits ? full : short,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}

Future<void> _editCount(
  BuildContext context,
  ZikirViewModel viewModel,
  AppLocalizations loc,
) async {
  final value = await _askNumber(
    context,
    title: loc.editCounterTitle,
    // Tur kipinde turun içindeki sayı (ekrandaki)
    initial: viewModel.progress.count,
    hint: loc.exampleHint(2000),
    min: 0,
  );
  if (value != null) await viewModel.setCount(value);
}

Future<void> _editTarget(
  BuildContext context,
  ZikirViewModel viewModel,
  AppLocalizations loc,
) async {
  final value = await _askNumber(
    context,
    title: loc.setTarget,
    initial: viewModel.target,
    hint: loc.exampleHint(99),
    min: 1,
  );
  if (value != null) await viewModel.setTarget(value);
}

Future<void> _confirmReset(
  BuildContext context,
  ZikirViewModel viewModel,
  AppLocalizations loc,
) async {
  final confirmed = await showConfirmDialog(
    context,
    title: loc.resetCounter,
    message: loc.resetCounterConfirm,
    confirmLabel: loc.resetCounter,
    destructive: true,
  );
  if (confirmed) await viewModel.reset();
}

/// Sayı girişi; geçersiz/boş giriş değişiklik yapmadan kapanır (null)
Future<int?> _askNumber(
  BuildContext context, {
  required String title,
  required int initial,
  required String hint,
  required int min,
}) {
  return showDialog<int>(
    context: context,
    builder: (_) => _NumberInputDialog(
      title: title,
      initial: initial,
      hint: hint,
      min: min,
    ),
  );
}

class _NumberInputDialog extends StatefulWidget {
  final String title;
  final int initial;
  final String hint;
  final int min;

  const _NumberInputDialog({
    required this.title,
    required this.initial,
    required this.hint,
    required this.min,
  });

  @override
  State<_NumberInputDialog> createState() => _NumberInputDialogState();
}

class _NumberInputDialogState extends State<_NumberInputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final text = '${widget.initial}';
    // Değer seçili gelir: yazınca yerine geçer
    _controller = TextEditingController(text: text)
      ..selection = TextSelection(baseOffset: 0, extentOffset: text.length);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = int.tryParse(_controller.text.trim());
    Navigator.pop(context, value != null && value >= widget.min ? value : null);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(9),
        ],
        decoration: InputDecoration(hintText: widget.hint),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(loc.save)),
      ],
    );
  }
}

/// Seçili zikir (ad + Arapça) ve hedef düğmesi. Yana kaydırınca ya da
/// oklarla listedeki önceki/sonraki zikre geçilir (sağdan sola dilde yön de
/// döner: "sonraki" okun ve kaydırmanın yönü okuma yönündedir).
class _DhikrHeader extends StatelessWidget {
  final String dhikrId;
  final String name;
  final String arabic;
  final String targetLabel;
  final VoidCallback onEditTarget;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _DhikrHeader({
    required this.dhikrId,
    required this.name,
    required this.arabic,
    required this.targetLabel,
    required this.onEditTarget,
    required this.onPrevious,
    required this.onNext,
  });

  // Bundan yavaş yana çekme zikir değiştirmez (dikey kaydırmayla karışmasın)
  static const double _minSwipeVelocity = 250;

  void _onSwipe(BuildContext context, DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < _minSwipeVelocity) return;
    // Soldan sağa dilde sola kaydırmak sonraki; sağdan solada tersi
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final forward = rtl ? velocity > 0 : velocity < 0;
    forward ? onNext() : onPrevious();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return GestureDetector(
      key: ZikirView.headerKey,
      onHorizontalDragEnd: (details) => _onSwipe(context, details),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xs,
          AppSpacing.xs,
          AppSpacing.xs,
          AppSpacing.md,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.topCenter,
            children: [...previous, ?current],
          ),
          child: Column(
            key: ValueKey(dhikrId),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    tooltip: loc.zikirPrevious,
                    color: scheme.onSurfaceVariant,
                    onPressed: onPrevious,
                  ),
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    tooltip: loc.zikirNext,
                    color: scheme.onSurfaceVariant,
                    onPressed: onNext,
                  ),
                ],
              ),
              if (arabic.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: ConstrainedBox(
                    // Uzun dualar kartı büyütmez, kayar
                    constraints: const BoxConstraints(maxHeight: 84),
                    child: SingleChildScrollView(
                      child: Text(
                        arabic,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                        style: arabicDhikrStyle(context, fontSize: 24),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: FilledButton.tonalIcon(
                  onPressed: onEditTarget,
                  icon: const Icon(Icons.flag_outlined),
                  label: Text(targetLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hedef halkası: iz (soluk) ve hedefe doğru ilerleme (tepeden saat yönünde)
class _RingPainter extends CustomPainter {
  final double fraction;
  final Color color;
  final Color track;
  final double width;

  const _RingPainter({
    required this.fraction,
    required this.color,
    required this.track,
    required this.width,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(width / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..color = track;
    canvas.drawArc(rect, 0, 2 * math.pi, false, paint);
    if (fraction <= 0) return;
    paint
      ..color = color
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * fraction.clamp(0.0, 1.0),
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction ||
      old.color != color ||
      old.track != track ||
      old.width != width;
}

/// "27 / 33" ve (tur kipinde ya da 2. turdan itibaren) "Tur 2" kapsülü
class _ProgressLine extends StatelessWidget {
  final ZikirProgress progress;

  const _ProgressLine({required this.progress});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = PrayerColors.of(context);
    final reached = progress.reached;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        TabularText(
          loc.zikirProgress(progress.inRound, progress.target),
          style: theme.textTheme.titleMedium!.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        if (progress.showRound)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: reached
                  ? colors.successContainer
                  : scheme.secondaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Text(
              loc.zikirRound(progress.round),
              style: theme.textTheme.labelLarge!.copyWith(
                color: reached
                    ? colors.onSuccessContainer
                    : scheme.onSecondaryContainer,
              ),
            ),
          ),
      ],
    );
  }
}

/// Ekran okuyucunun sayaç değeri: sayı ve (gösteriliyorsa) tur
String _spokenValue(ZikirProgress progress, AppLocalizations loc) =>
    progress.showRound
    ? '${progress.count}, ${loc.zikirRound(progress.round)}'
    : '${progress.count}';

/// Modern görünüm: hedef halkalı büyük daire; daireye ya da çevresindeki boş
/// alana dokununca sayar, daireye basılı tutunca düzenlenir
class _ModernCounter extends StatelessWidget {
  final ZikirViewModel viewModel;
  final ZikirProgress progress;
  final String dhikrName;
  final VoidCallback onEdit;

  const _ModernCounter({
    required this.viewModel,
    required this.progress,
    required this.dhikrName,
    required this.onEdit,
  });

  static const double _ringWidth = 10;
  static const double _ringInset = 8;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = PrayerColors.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final reached = progress.reached;
    final accent = reached ? colors.success : scheme.primary;

    // Boş alana dokunmak da sayar (ekran okuyucu daireyi kullanır)
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTap: viewModel.increment,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = math.max(
            0.0,
            math.min(
              300.0,
              math.min(constraints.maxWidth - 48, constraints.maxHeight - 32),
            ),
          );
          return Center(
            child: Semantics(
              container: true,
              button: true,
              label: dhikrName,
              value: _spokenValue(progress, loc),
              hint: loc.tapToCount,
              onLongPressHint: loc.editCounterTitle,
              onTap: viewModel.increment,
              onLongPress: onEdit,
              excludeSemantics: true,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(
                        alpha: isDark ? 0.18 : 0.25,
                      ),
                      blurRadius: 40,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Material(
                  color: theme.cardTheme.color ?? scheme.surfaceContainerLowest,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: viewModel.increment,
                    onLongPress: onEdit,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(_ringInset),
                          child: TweenAnimationBuilder<double>(
                            key: ZikirView.ringKey,
                            tween: Tween(end: progress.fraction),
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, _) => CustomPaint(
                              painter: _RingPainter(
                                fraction: value,
                                color: accent,
                                track: accent.withValues(
                                  alpha: isDark ? 0.24 : 0.16,
                                ),
                                width: _ringWidth,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(size * 0.17),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TabularText(
                                  '${progress.count}',
                                  key: ZikirView.counterKey,
                                  style: TextStyle(
                                    fontSize: 88,
                                    fontWeight: FontWeight.w700,
                                    height: 1.1,
                                    color: reached
                                        ? colors.success
                                        : scheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                _ProgressLine(progress: progress),
                                if (reached) ...[
                                  const SizedBox(height: AppSpacing.sm),
                                  _ReachedChip(text: loc.targetReached),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ReachedChip extends StatelessWidget {
  final String text;

  const _ReachedChip({required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = PrayerColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.successContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.labelLarge!.copyWith(color: colors.onSuccessContainer),
      ),
    );
  }
}

/// Altta "Sayacı Düzenle" (sıfırla üst çubukta). Fotoğraf arka planında da
/// okunsun diye opak (tonal) düğme.
class _ActionRow extends StatelessWidget {
  final VoidCallback onEdit;

  const _ActionRow({required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Center(
        child: FilledButton.tonalIcon(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
          label: Text(loc.editCounterTitle),
        ),
      ),
    );
  }
}

/// Klasik görünüm: aşağı çekilen (veya dokunulan) tesbih boncukları. Sayaç
/// kartına ve çevresine dokunmak da sayar; ses tuşuyla sayınca da boncuk
/// çekilir.
class _ClassicTasbihView extends StatefulWidget {
  final ZikirViewModel viewModel;
  final ZikirProgress progress;
  final String dhikrName;
  final VoidCallback onEdit;

  const _ClassicTasbihView({
    required this.viewModel,
    required this.progress,
    required this.dhikrName,
    required this.onEdit,
  });

  @override
  State<_ClassicTasbihView> createState() => _ClassicTasbihViewState();
}

class _ClassicTasbihViewState extends State<_ClassicTasbihView>
    with SingleTickerProviderStateMixin {
  static const int _visibleBeads = 6;
  static const double _beadHeight = 65.0;

  // Tesbih görseli (temadan bağımsız ahşap tonları)
  static const Color _cord = Color(0xFF4E342E);
  static const Color _beadLight = Color(0xFFFFB74D);
  static const Color _beadDark = Color(0xFF5D4037);

  late final AnimationController _controller;

  // Son çizilen zikir ve ilerleme: dokunuş dışından (ses tuşu) artınca da
  // boncuk çekilir
  late String _shownDhikr;
  late (int, int) _shownProgress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _shownDhikr = widget.viewModel.selectedDhikr;
    _shownProgress = (widget.progress.round, widget.progress.count);
  }

  @override
  void didUpdateWidget(_ClassicTasbihView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final dhikr = widget.viewModel.selectedDhikr;
    final progress = (widget.progress.round, widget.progress.count);
    final advanced =
        dhikr == _shownDhikr &&
        (progress.$1 > _shownProgress.$1 ||
            (progress.$1 == _shownProgress.$1 &&
                progress.$2 > _shownProgress.$2));
    if (advanced && !_controller.isAnimating) _controller.forward(from: 0.0);
    _shownDhikr = dhikr;
    _shownProgress = progress;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _pullBead() {
    if (_controller.isAnimating) return;
    _controller.forward(from: 0.0);
    widget.viewModel.increment();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = PrayerColors.of(context);
    final progress = widget.progress;
    final reached = progress.reached;

    // Boş alana dokunmak da sayar (ekran okuyucu boncuk düğmesini kullanır)
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTap: _pullBead,
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.lg),
          // Sayaç (basılı tutunca düzenlenir)
          Semantics(
            container: true,
            label: widget.dhikrName,
            value: _spokenValue(progress, loc),
            onLongPressHint: loc.editCounterTitle,
            onLongPress: widget.onEdit,
            excludeSemantics: true,
            child: Material(
              color: theme.cardTheme.color ?? scheme.surfaceContainerLowest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                side: BorderSide(
                  color: reached
                      ? colors.success
                      : scheme.primary.withValues(alpha: 0.35),
                  width: 3,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _pullBead,
                onLongPress: widget.onEdit,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 160),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xxl,
                      vertical: AppSpacing.md,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TabularText(
                          '${progress.count}',
                          key: ZikirView.counterKey,
                          style: TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                            color: reached ? colors.success : scheme.onSurface,
                          ),
                        ),
                        _ProgressLine(progress: progress),
                        if (reached) ...[
                          const SizedBox(height: AppSpacing.xs),
                          _ReachedChip(text: loc.targetReached),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // İp ve boncuklar: dokun veya aşağı çek
          Expanded(
            // Dokununca yeni sayı aynı düğmede okunur
            child: Semantics(
              container: true,
              button: true,
              label: widget.dhikrName,
              value: _spokenValue(progress, loc),
              hint: loc.tapToCount,
              onTap: _pullBead,
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragEnd: (details) {
                  final velocity = details.primaryVelocity;
                  if (velocity != null && velocity > 0) _pullBead();
                },
                onTap: _pullBead,
                child: SizedBox(
                  width: double.infinity,
                  child: ClipRect(
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Center(
                          child: SizedBox(
                            width: 150,
                            child: Stack(
                              alignment: Alignment.topCenter,
                              children: [
                                const Positioned.fill(
                                  child: Center(
                                    child: SizedBox(
                                      width: 5,
                                      child: ColoredBox(color: _cord),
                                    ),
                                  ),
                                ),
                                for (int i = -1; i <= _visibleBeads; i++)
                                  Positioned(
                                    top:
                                        (i + _controller.value) * _beadHeight +
                                        10,
                                    child: Opacity(
                                      opacity: (i == _visibleBeads)
                                          ? 1.0 - _controller.value
                                          : (i == -1)
                                          ? _controller.value
                                          : 1.0,
                                      child: _buildBead(),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBead() {
    return Container(
      width: 55,
      height: 45,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 5)),
        ],
        gradient: const RadialGradient(
          colors: [_beadLight, _beadDark],
          center: Alignment(-0.3, -0.3),
          radius: 0.8,
        ),
      ),
      child: const Center(
        child: SizedBox(
          width: 8,
          height: 45,
          child: ColoredBox(color: Color(0x4D000000)),
        ),
      ),
    );
  }
}
