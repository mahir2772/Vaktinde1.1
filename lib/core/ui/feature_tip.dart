import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ezan_saati/l10n/app_localizations.dart';
import 'app_tokens.dart';
import 'info_banner.dart';

/// Bağlamsal ipucu (InfoBanner kalıbında): ekranın ilk ziyaretinde, kurulum
/// başına bir kez ('tip_<id>_seen'); "Anladım" ya da eylem düğmesiyle kapanır.
/// Aynı anda tek ipucu görünür; açılış pencereleri (tur, izinler, Yenilikler)
/// açıkken beklenir ([attachGate]). Gösterilmediğinde yer kaplamaz.
class FeatureTip extends StatefulWidget {
  final String id;
  final String message;
  final IconData icon;

  /// İsteğe bağlı eylem (ör. "Widget ekle"); dokununca ipucu da kapanır
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Ek koşul (ör. kullanım günü, başlatıcı desteği); false ise bu ziyarette
  /// gösterilmez. Açılış pencereleri kapandıktan sonra bir kez sorulur.
  final Future<bool> Function()? when;

  /// Görünürken çevresindeki boşluk
  final EdgeInsetsGeometry padding;

  /// İçeriğin üstünde yüzer (gölgeli; sığmayan ekranlarda Stack içinde)
  final bool floating;

  const FeatureTip({
    super.key,
    required this.id,
    required this.message,
    this.icon = Icons.lightbulb_outline,
    this.actionLabel,
    this.onAction,
    this.when,
    this.padding = EdgeInsets.zero,
    this.floating = false,
  });

  static String seenKey(String id) => 'tip_${id}_seen';

  // Açılış pencereleri kapısı (MainWrapper bağlar); bağlı değilse serbest
  static bool Function()? _gate;

  // Ekranda olan ipucu
  static String? _active;

  static void attachGate(bool Function() gate) => _gate = gate;

  static void detachGate(bool Function() gate) {
    if (_gate == gate) _gate = null;
  }

  static bool _isFree(String id) =>
      (_active == null || _active == id) && (_gate?.call() ?? true);

  @visibleForTesting
  static void debugReset() {
    _gate = null;
    _active = null;
  }

  @override
  State<FeatureTip> createState() => _FeatureTipState();
}

class _FeatureTipState extends State<FeatureTip> {
  bool _show = false;
  Timer? _retry;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _retry?.cancel();
    _release();
    super.dispose();
  }

  Future<void> _start() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(FeatureTip.seenKey(widget.id)) ?? false) return;
    } catch (e) {
      return;
    }
    _tryShow();
  }

  // Başka ipucu ya da açılış penceresi varken saniyede bir yeniden denenir
  Future<void> _tryShow() async {
    if (!mounted) return;
    if (!FeatureTip._isFree(widget.id)) {
      _retry = Timer(const Duration(seconds: 1), _tryShow);
      return;
    }
    final when = widget.when;
    if (when != null) {
      try {
        if (!await when()) return;
      } catch (e) {
        return;
      }
      if (!mounted) return;
      if (!FeatureTip._isFree(widget.id)) {
        _retry = Timer(const Duration(seconds: 1), _tryShow);
        return;
      }
    }
    FeatureTip._active = widget.id;
    setState(() => _show = true);
  }

  void _release() {
    if (_show && FeatureTip._active == widget.id) FeatureTip._active = null;
  }

  Future<void> _dismiss() async {
    _release();
    setState(() => _show = false);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(FeatureTip.seenKey(widget.id), true);
    } catch (e) {
      debugPrint('İpucu kaydı yazılamadı: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_show) return const SizedBox.shrink();
    final loc = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final buttonStyle = TextButton.styleFrom(
      foregroundColor: scheme.onPrimaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
    );
    final actionLabel = widget.actionLabel;
    final Widget banner = InfoBanner(
      icon: widget.icon,
      message: widget.message,
      actionBelow: true,
      // Dar ekranda/büyük yazıda düğmeler alt alta geçer
      action: Wrap(
        alignment: WrapAlignment.end,
        children: [
          if (actionLabel != null)
            TextButton(
              style: buttonStyle,
              onPressed: () {
                _dismiss();
                widget.onAction?.call();
              },
              child: Text(actionLabel),
            ),
          TextButton(
            style: buttonStyle,
            onPressed: _dismiss,
            child: Text(loc.tipGotIt),
          ),
        ],
      ),
    );
    return Padding(
      padding: widget.padding,
      child: widget.floating
          ? PhysicalModel(
              color: scheme.primaryContainer,
              shadowColor: scheme.shadow,
              elevation: 4,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: banner,
            )
          : banner,
    );
  }
}
