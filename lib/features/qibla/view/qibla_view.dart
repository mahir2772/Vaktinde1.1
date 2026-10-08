import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import '../../../data/services/storage_service.dart';
import '../qibla_math.dart';

/// Konum alınamazsa gösterilen hata türü
enum _LocationProblem { serviceOff, permissionDenied, unavailable }

/// Kıble pusulası: konumdan Kâbe yönü (açı) + telefonun yönü.
///
/// Konum: önce GPS (izin istemez; izin tanıtım turundan sonra istenir), olmazsa
/// kayıtlı koordinat. Pusula sadece sekme görünür ve uygulama ön plandayken
/// dinlenir (arka plan, tam ekran reklam, bildirim perdesi → sensörler kapanır).
class QiblaView extends StatefulWidget {
  /// Pusula olay kaynağı; testte sahte akış verilir
  @visibleForTesting
  final Stream<CompassEvent>? Function() compassEvents;

  const QiblaView({super.key, this.compassEvents = _platformCompass});

  static Stream<CompassEvent>? _platformCompass() => FlutterCompass.events;

  @override
  State<QiblaView> createState() => _QiblaViewState();
}

class _QiblaViewState extends State<QiblaView> with WidgetsBindingObserver {
  static const String _calibrationSeenKey = 'qibla_calibration_dialog_seen';
  static const Duration _noSensorTimeout = Duration(seconds: 4);
  // Kısa doğruluk düşüşlerinde uyarı yanıp sönmesin
  static const Duration _calibrationDelay = Duration(seconds: 2);
  // Bundan küçük yön değişimi yeniden çizim yaptırmaz
  static const double _minHeadingStep = 0.5;

  bool _loading = true;
  bool _initStarted = false;
  _LocationProblem? _problem;
  double? _bearing;
  bool _usingSavedLocation = false;

  bool _active = false;
  bool _foreground = true;
  StreamSubscription<CompassEvent>? _compassSubscription;
  Timer? _noSensorTimer;
  Timer? _calibrationTimer;
  bool _noCompass = false;
  bool _hasHeading = false;

  /// Son gösterilen yön (0..360) ve kadranın yumuşak dönüşü için sarılmamış yön
  double _heading = 0;
  double _unwrappedHeading = 0;
  bool _aligned = false;
  bool _calibrationPoor = false;

  bool _calibrationDialogSeen = true;
  bool _showCalibrationDialog = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Durum henüz bildirilmediyse (açılış) ön planda sayılır
    final state = WidgetsBinding.instance.lifecycleState;
    _foreground = state == null || state == AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sekme gizliyken (IndexedStack) veya üstüne sayfa açılınca pusula durur
    final active = Visibility.of(context) && TickerMode.of(context);
    if (active == _active) return;
    _active = active;
    if (active && !_initStarted) {
      _initStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _init();
      });
      return;
    }
    _syncCompass();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // inactive/hidden/paused/detached: sensörler bırakılır
    final foreground = state == AppLifecycleState.resumed;
    if (foreground == _foreground) return;
    _foreground = foreground;
    _syncCompass();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopCompass();
    super.dispose();
  }

  Future<void> _init() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _problem = null;
    });

    var problem = _LocationProblem.unavailable;
    ({double lat, double lng})? coords;
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        problem = _LocationProblem.serviceOff;
      } else {
        // İzin burada istenmez: tanıtım turu bitince bir kez istenir
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          problem = _LocationProblem.permissionDenied;
        } else {
          // timeLimit: süre dolunca yerel konum isteği de durur (dış .timeout
          // sadece beklemeyi bırakır)
          final position =
              await Geolocator.getLastKnownPosition() ??
              await Geolocator.getCurrentPosition(
                desiredAccuracy: LocationAccuracy.medium,
                timeLimit: const Duration(seconds: 8),
              );
          coords = (lat: position.latitude, lng: position.longitude);
        }
      }
    } catch (_) {
      coords = null;
    }

    var usingSaved = false;
    if (coords == null) {
      try {
        coords = await StorageService().loadCoordinates();
        usingSaved = coords != null;
      } catch (_) {
        coords = null;
      }
    }

    var seen = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      seen = prefs.getBool(_calibrationSeenKey) ?? false;
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _loading = false;
      _calibrationDialogSeen = seen;
      if (coords == null) {
        _bearing = null;
        _problem = problem;
      } else {
        _bearing = qiblaBearing(coords.lat, coords.lng);
        _usingSavedLocation = usingSaved;
      }
    });
    _syncCompass();
  }

  /// Pusula sadece sekme görünür, uygulama ön planda ve açı hazırken dinlenir
  void _syncCompass() {
    if (_active && _foreground && _bearing != null) {
      _startCompass();
    } else {
      _stopCompass();
    }
  }

  /// Tek abonelik: zaten dinleniyorsa bir şey yapmaz
  void _startCompass() {
    if (_compassSubscription != null) return;
    final events = widget.compassEvents();
    if (events == null) {
      if (!_noCompass) setState(() => _noCompass = true);
      return;
    }
    _noSensorTimer?.cancel();
    _noSensorTimer = null;
    if (!_hasHeading) {
      // Sensörü olmayan cihazda hiç olay gelmez
      _noSensorTimer = Timer(_noSensorTimeout, () {
        if (mounted && !_hasHeading) setState(() => _noCompass = true);
      });
    }
    _compassSubscription = events.listen(
      _onCompassEvent,
      onError: (Object _) {
        if (mounted && !_hasHeading) setState(() => _noCompass = true);
      },
    );
  }

  /// Aboneliği bırakır (eklenti sensör dinleyicilerini kaldırır); tekrar
  /// çağrılabilir
  void _stopCompass() {
    _noSensorTimer?.cancel();
    _noSensorTimer = null;
    _calibrationTimer?.cancel();
    _calibrationTimer = null;
    _compassSubscription?.cancel();
    _compassSubscription = null;
  }

  void _onCompassEvent(CompassEvent event) {
    if (!mounted || _bearing == null) return;
    final raw = event.heading;
    if (raw == null) {
      if (!_hasHeading && !_noCompass) setState(() => _noCompass = true);
      return;
    }
    _noSensorTimer?.cancel();
    _noSensorTimer = null;
    _updateCalibration(event.accuracy);

    final heading = normalizeDegrees(raw);
    final step = _hasHeading ? signedDelta(_heading, heading) : heading;
    // Saniyede ~30 olay: fark edilmeyecek titreşimde yeniden çizilmez
    if (_hasHeading && !_noCompass && step.abs() < _minHeadingStep) return;
    final aligned = qiblaTurnFor(heading, _bearing!) == QiblaTurn.aligned;
    if (aligned && !_aligned) HapticFeedback.heavyImpact();

    setState(() {
      _hasHeading = true;
      _noCompass = false;
      _heading = heading;
      _unwrappedHeading += step;
      _aligned = aligned;
    });
  }

  /// Doğruluk [_calibrationDelay] boyunca zayıf/bilinmiyorsa uyarı açılır,
  /// iyi okuma gelince hemen kapanır
  void _updateCalibration(double? accuracy) {
    if (!compassAccuracyPoor(accuracy)) {
      _calibrationTimer?.cancel();
      _calibrationTimer = null;
      if (_calibrationPoor) setState(() => _calibrationPoor = false);
      return;
    }
    if (_calibrationPoor || _calibrationTimer != null) return;
    _calibrationTimer = Timer(_calibrationDelay, _onCalibrationPoor);
  }

  void _onCalibrationPoor() {
    _calibrationTimer = null;
    if (!mounted) return;
    var showDialog = _showCalibrationDialog;
    if (!_calibrationDialogSeen) {
      // Kalibrasyon penceresi sadece ilk seferde (kalıcı olarak hatırlanır)
      _calibrationDialogSeen = true;
      showDialog = true;
      SharedPreferences.getInstance()
          .then((prefs) => prefs.setBool(_calibrationSeenKey, true))
          .catchError((Object _) => false);
    }
    setState(() {
      _calibrationPoor = true;
      _showCalibrationDialog = showDialog;
    });
  }

  String _deg(double value) => '${normalizeDegrees(value).round() % 360}';

  /// "152°" sağdan sola metinde de "152°" okunsun (° sayının solunda kalmasın)
  static String _isolateDegrees(String text, String value) =>
      text.replaceFirst('$value°', '\u2066$value°\u2069');

  String _angleText(AppLocalizations loc, double bearing) {
    final value = _deg(bearing);
    return _isolateDegrees(loc.qiblaAngle(value), value);
  }

  String _headingText(AppLocalizations loc, double heading) {
    final value = _deg(heading);
    return _isolateDegrees(loc.phoneHeading(value), value);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.qiblaTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(child: _buildBody(context, loc)),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations loc) {
    if (_loading) return LoadingState(message: loc.fetchingLocation);

    final bearing = _bearing;
    if (bearing == null) {
      final message = switch (_problem) {
        _LocationProblem.serviceOff => loc.locationServiceOff,
        _LocationProblem.permissionDenied => loc.locationPermissionDenied,
        _ => loc.locationError,
      };
      return ErrorState(message: message, onRetry: _init);
    }

    final savedBanner = _usingSavedLocation
        ? Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              0,
            ),
            child: InfoBanner(
              message: loc.usingSavedLocation,
              icon: Icons.location_history,
            ),
          )
        : null;

    if (_noCompass) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ?savedBanner,
          Expanded(
            child: EmptyState(
              icon: Icons.explore_off_outlined,
              title: loc.noCompass,
              message: _angleText(loc, bearing),
            ),
          ),
        ],
      );
    }

    final scroll = LayoutBuilder(
      builder: (context, constraints) {
        final dialSize = math.max(
          180.0,
          math.min(
            300.0,
            math.min(
              constraints.maxWidth - 2 * AppSpacing.xl,
              constraints.maxHeight * 0.5,
            ),
          ),
        );
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: ConstrainedBox(
            // Uzun ekranda içerik dikeyde ortalanır
            constraints: BoxConstraints(
              minHeight: math.max(0, constraints.maxHeight - 2 * AppSpacing.lg),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: _QiblaStatus(
                    hasHeading: _hasHeading,
                    turn: _hasHeading ? qiblaTurnFor(_heading, bearing) : null,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(end: _unwrappedHeading),
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    builder: (context, heading, _) => _CompassDial(
                      size: dialSize,
                      heading: heading,
                      bearing: bearing,
                      aligned: _aligned,
                      semanticLabel: [
                        loc.qiblaDirection,
                        _angleText(loc, bearing),
                        if (_hasHeading) _headingText(loc, _heading),
                      ].join('. '),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _Readouts(
                  bearingText: _angleText(loc, bearing),
                  headingText: _hasHeading ? _headingText(loc, _heading) : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: _calibrationPoor
                      ? InfoBanner(
                          message: loc.lowAccuracyWarning,
                          icon: Icons.screen_rotation,
                          tone: InfoTone.warning,
                        )
                      : InfoBanner(
                          message:
                              '${loc.qiblaCalibration} ${loc.keepAwayMetal}',
                          icon: Icons.screen_rotation,
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ?savedBanner,
        Expanded(child: scroll),
      ],
    );

    if (!_showCalibrationDialog) return content;
    return Stack(
      children: [
        Positioned.fill(child: content),
        // Sayfaya gömülü pencere: diğer sekmelerin üstüne taşmaz
        Positioned.fill(
          child: ModalBarrier(
            color: Colors.black54,
            dismissible: false,
            semanticsLabel: loc.calibrationRequired,
          ),
        ),
        Center(
          child: SingleChildScrollView(
            child: AlertDialog(
              icon: const Icon(Icons.screen_rotation, size: 40),
              title: Text(loc.calibrationRequired, textAlign: TextAlign.center),
              content: Text(
                loc.lowAccuracyWarning,
                textAlign: TextAlign.center,
              ),
              actions: [
                FilledButton(
                  onPressed: () =>
                      setState(() => _showCalibrationDialog = false),
                  child: Text(loc.okUnderstood),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Üstteki yönerge: "Sağa dönün" (ok fiziksel yönde) veya "Kıbleyi buldunuz"
class _QiblaStatus extends StatelessWidget {
  final bool hasHeading;
  final QiblaTurn? turn;

  const _QiblaStatus({required this.hasHeading, required this.turn});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = PrayerColors.of(context);
    final style = theme.textTheme.titleLarge!.copyWith(
      fontWeight: FontWeight.w700,
    );

    Widget child;
    if (!hasHeading || turn == null) {
      child = Text(
        loc.qiblaDirection,
        textAlign: TextAlign.center,
        style: style.copyWith(color: scheme.onSurfaceVariant),
      );
    } else if (turn == QiblaTurn.aligned) {
      child = Semantics(
        liveRegion: true,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: colors.success, size: 28),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                loc.qiblaFound,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: style.copyWith(color: colors.success),
              ),
            ),
          ],
        ),
      );
    } else {
      final (String label, IconData icon, bool right) = switch (turn!) {
        QiblaTurn.right => (loc.qiblaTurnRight, Icons.turn_right, true),
        QiblaTurn.slightRight => (
          loc.qiblaTurnSlightRight,
          Icons.turn_slight_right,
          true,
        ),
        QiblaTurn.left => (loc.qiblaTurnLeft, Icons.turn_left, false),
        _ => (loc.qiblaTurnSlightLeft, Icons.turn_slight_left, false),
      };
      // Ok her dilde fiziksel dönüş tarafında durur (Arapçada da sağ = sağ)
      final arrow = ExcludeSemantics(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Icon(icon, color: scheme.primary, size: 30),
        ),
      );
      final text = Flexible(
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: style.copyWith(color: scheme.primary),
        ),
      );
      child = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        textDirection: TextDirection.ltr,
        children: right
            ? [text, const SizedBox(width: AppSpacing.sm), arrow]
            : [arrow, const SizedBox(width: AppSpacing.sm), text],
      );
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: Center(child: child),
    );
  }
}

/// Kıble açısı (büyük) ve telefon yönü (küçük), ayrı satırlarda
class _Readouts extends StatelessWidget {
  final String bearingText;
  final String? headingText;

  const _Readouts({required this.bearingText, required this.headingText});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          Text(
            bearingText,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge!.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (headingText != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              headingText!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge!.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Pusula kadranı: telefon yönüne göre döner; harfler ve Kâbe simgesi dik kalır.
/// Üstteki sabit işaret telefonun baktığı yöndür. Sağdan sola dillerde
/// aynalanmaz (doğu her zaman sağda).
class _CompassDial extends StatelessWidget {
  final double size;
  final double heading;
  final double bearing;
  final bool aligned;
  final String semanticLabel;

  const _CompassDial({
    required this.size,
    required this.heading,
    required this.bearing,
    required this.aligned,
    required this.semanticLabel,
  });

  /// Kadran üzerindeki [angle] (kuzeyden derece) noktasına, merkezden [radius]
  /// uzaklıkta yerleştirir; içerik döndürülmez
  Widget _polar(double angle, double radius, Widget child) {
    final radians = (angle - heading) * math.pi / 180;
    return Transform.translate(
      offset: Offset(radius * math.sin(radians), -radius * math.cos(radians)),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = PrayerColors.of(context);
    final accent = aligned ? colors.success : scheme.primary;
    final radius = size / 2;
    final letterStyle = theme.textTheme.titleMedium!.copyWith(
      fontWeight: FontWeight.w700,
      color: scheme.onSurfaceVariant,
    );
    final cardinals = <(double, String, Color?)>[
      (0, loc.directionNorth, scheme.error),
      (90, loc.directionEast, null),
      (180, loc.directionSouth, null),
      (270, loc.directionWest, null),
    ];

    return Semantics(
      label: semanticLabel,
      image: true,
      excludeSemantics: true,
      child: SizedBox(
        width: size,
        height: size,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                size: Size.square(size),
                painter: _DialPainter(
                  heading: heading,
                  bearing: bearing,
                  face: scheme.surfaceContainerLowest,
                  ring: aligned ? colors.success : scheme.outlineVariant,
                  ticks: scheme.onSurfaceVariant,
                  needle: accent,
                  lubber: aligned ? colors.success : scheme.onSurface,
                ),
              ),
              for (final (angle, letter, color) in cardinals)
                _polar(
                  angle,
                  radius - 34,
                  Text(
                    letter,
                    style: color == null
                        ? letterStyle
                        : letterStyle.copyWith(color: color),
                  ),
                ),
              _polar(
                bearing,
                radius * 0.62 + 22,
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.mosque,
                    size: 22,
                    color: aligned ? Colors.white : scheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  final double heading;
  final double bearing;
  final Color face;
  final Color ring;
  final Color ticks;
  final Color needle;
  final Color lubber;

  _DialPainter({
    required this.heading,
    required this.bearing,
    required this.face,
    required this.ring,
    required this.ticks,
    required this.needle,
    required this.lubber,
  });

  Offset _point(Offset center, double angleDeg, double radius) {
    final r = (angleDeg - heading) * math.pi / 180;
    return center + Offset(radius * math.sin(r), -radius * math.cos(r));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final dialRadius = radius - 6;

    canvas.drawCircle(center, dialRadius, Paint()..color = face);
    canvas.drawCircle(
      center,
      dialRadius,
      Paint()
        ..color = ring
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Derece çizgileri (her 10°; 30°'lerde uzun)
    final tickPaint = Paint()
      ..color = ticks
      ..strokeCap = StrokeCap.round;
    for (var a = 0; a < 360; a += 10) {
      final major = a % 30 == 0;
      tickPaint.strokeWidth = major ? 2.5 : 1.2;
      canvas.drawLine(
        _point(center, a.toDouble(), dialRadius - 4),
        _point(center, a.toDouble(), dialRadius - (major ? 16 : 10)),
        tickPaint,
      );
    }

    // Kıble iğnesi: merkezden Kâbe simgesine
    final needleEnd = _point(center, bearing, radius * 0.62);
    canvas.drawLine(
      center,
      needleEnd,
      Paint()
        ..color = needle
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(center, 9, Paint()..color = needle);
    canvas.drawCircle(center, 4, Paint()..color = face);

    // Telefonun baktığı yön: üstte sabit üçgen
    final top = Offset(center.dx, center.dy - radius);
    final path = Path()
      ..moveTo(top.dx - 10, top.dy)
      ..lineTo(top.dx + 10, top.dy)
      ..lineTo(top.dx, top.dy + 16)
      ..close();
    canvas.drawPath(path, Paint()..color = lubber);
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.heading != heading ||
      old.bearing != bearing ||
      old.face != face ||
      old.ring != ring ||
      old.ticks != ticks ||
      old.needle != needle ||
      old.lubber != lubber;
}
