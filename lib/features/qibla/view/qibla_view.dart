import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
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
///
/// Eklenti manyetik kuzeyi verir: yön, konumun manyetik sapmasıyla (MainActivity
/// 'geomagnetic', Dünya Manyetik Modeli) coğrafi kuzeye çevrilir ve titreşime
/// karşı süzülür. Manyetometre ('vaktinde/magnetic', pusulayla aynı yaşam
/// döngüsü) beklenen alandan saparsa parazit uyarısı, doğruluğu düşükse
/// kalibrasyon uyarısı verilir.
class QiblaView extends StatefulWidget {
  /// Pusula olay kaynağı; testte sahte akış verilir
  @visibleForTesting
  final Stream<CompassEvent>? Function() compassEvents;

  /// Manyetometre olay kaynağı; testte sahte akış verilir
  @visibleForTesting
  final Stream<MagneticReading>? Function() magneticEvents;

  const QiblaView({
    super.key,
    this.compassEvents = _platformCompass,
    this.magneticEvents = _platformMagnetic,
  });

  static Stream<CompassEvent>? _platformCompass() => FlutterCompass.events;

  static const EventChannel _magneticChannel = EventChannel(
    'vaktinde/magnetic',
  );

  /// Okunamayan olaylar atlanır; sensör yoksa 'no_sensor' hatası gelir
  static Stream<MagneticReading>? _platformMagnetic() => _magneticChannel
      .receiveBroadcastStream()
      .map(parseMagneticReading)
      .where((reading) => reading != null)
      .map((reading) => reading!);

  @override
  State<QiblaView> createState() => _QiblaViewState();
}

/// Konumun manyetik sapması ve beklenen alan şiddeti; hata/eksik yanıtta null
Future<Geomagnetic?> _queryGeomagnetic(double lat, double lng) async {
  try {
    final result = await const MethodChannel(
      'vaktinde/device',
    ).invokeMethod<Object?>('geomagnetic', {'lat': lat, 'lng': lng});
    return Geomagnetic.tryParse(result);
  } catch (_) {
    return null;
  }
}

String _deg(double value) => '${normalizeDegrees(value).round() % 360}';

/// "152°" sağdan sola metinde de "152°" okunsun (° sayının solunda kalmasın,
/// "+6°" işareti yer değiştirmesin)
String _isolateDegrees(String text, String value) =>
    text.replaceFirst('$value°', '${Unicode.LRI}$value°${Unicode.PDI}');

class _QiblaViewState extends State<QiblaView> with WidgetsBindingObserver {
  static const String _calibrationSeenKey = 'qibla_calibration_dialog_seen';
  static const Duration _noSensorTimeout = Duration(seconds: 4);
  // Kısa doğruluk düşüşlerinde uyarı yanıp sönmesin
  static const Duration _calibrationDelay = Duration(seconds: 2);
  // Parazit uyarısı kısa sapmalarda açılmaz; alan normale dönünce kısa bir
  // bekleyişle kapanır (metal yanından geçerken yanıp sönmesin)
  static const Duration _interferenceDelay = Duration(milliseconds: 1500);
  static const Duration _interferenceClearDelay = Duration(seconds: 1);
  // Bundan küçük yön değişimi yeniden çizim yaptırmaz
  static const double _minHeadingStep = 0.5;

  bool _loading = true;
  bool _initStarted = false;
  _LocationProblem? _problem;
  double? _bearing;
  ({double lat, double lng})? _coords;
  bool _usingSavedLocation = false;

  bool _active = false;
  bool _foreground = true;
  StreamSubscription<CompassEvent>? _compassSubscription;
  StreamSubscription<MagneticReading>? _magneticSubscription;
  Timer? _noSensorTimer;
  Timer? _calibrationTimer;
  Timer? _interferenceTimer;
  bool _noCompass = false;
  bool _hasHeading = false;

  /// Konumun manyetik modeli ve ait olduğu 0,1°'lik hücre (sorgu sürerken de
  /// dolu: aynı konum bir kez sorulur)
  Geomagnetic? _geomagnetic;
  String? _geomagneticCell;

  /// Süzülmüş coğrafi yön; abonelik yeniden açılınca ilk okumayla başlar
  HeadingFilter? _headingFilter;

  /// Son gösterilen yön (0..360) ve kadranın yumuşak dönüşü için sarılmamış yön
  double _heading = 0;
  double _unwrappedHeading = 0;
  bool _aligned = false;

  /// Son okunan doğruluklar: pusula (± derece) ve manyetometre (0..3)
  double? _compassAccuracy;
  int? _magnetometerAccuracy;
  bool _calibrationPoor = false;
  bool _interference = false;

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
      _coords = coords;
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

  /// Manyetik sapma ve beklenen alan şiddeti: konum başına bir kez sorulur
  /// (0,1°'lik hücre). Hata/eksik yanıtta sapma 0 kabul edilir ve parazit
  /// denetimi yapılmaz; pusula beklemez. Başarısız sorgu sonraki açılışta
  /// yeniden denenir.
  void _loadGeomagnetic() {
    final coords = _coords;
    if (coords == null) return;
    final cell = geomagneticCell(coords.lat, coords.lng);
    if (cell == _geomagneticCell) return;
    _geomagneticCell = cell;
    // Beklenen şiddet bilinmeden parazit uyarısı kapanamaz: yeni konumda sıfırdan
    _geomagnetic = null;
    _interference = false;
    _interferenceTimer?.cancel();
    _interferenceTimer = null;
    _queryGeomagnetic(coords.lat, coords.lng).then((info) {
      if (!mounted || _geomagneticCell != cell) return;
      if (info == null) {
        _geomagneticCell = null;
        return;
      }
      // Yön süzgeçten geçtiği için düzeltme kadranı sıçratmadan uygulanır
      setState(() => _geomagnetic = info);
    });
  }

  /// Pusula sadece sekme görünür, uygulama ön planda ve açı hazırken dinlenir
  void _syncCompass() {
    if (_active && _foreground && _bearing != null) {
      _startCompass();
    } else {
      _stopCompass();
    }
  }

  /// Tek abonelik: zaten dinleniyorsa bir şey yapmaz. Manyetometre de
  /// pusulayla birlikte açılır ve kapanır.
  void _startCompass() {
    if (_compassSubscription != null) return;
    final events = widget.compassEvents();
    if (events == null) {
      if (!_noCompass) setState(() => _noCompass = true);
      return;
    }
    // Yanıt genelde ilk yön olayından önce gelir
    _loadGeomagnetic();
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
    _magneticSubscription = widget.magneticEvents()?.listen(
      _onMagneticReading,
      // Manyetometre yok ('no_sensor') / kanal hatası: parazit denetimi yapılmaz
      onError: (Object _) {},
    );
  }

  /// Abonelikleri bırakır (eklentiler sensör dinleyicilerini kaldırır); tekrar
  /// çağrılabilir
  void _stopCompass() {
    _noSensorTimer?.cancel();
    _noSensorTimer = null;
    _calibrationTimer?.cancel();
    _calibrationTimer = null;
    _interferenceTimer?.cancel();
    _interferenceTimer = null;
    _compassSubscription?.cancel();
    _compassSubscription = null;
    _magneticSubscription?.cancel();
    _magneticSubscription = null;
    // Dönüşte eski yöne göre süzülmez (telefon bu arada dönmüş olabilir)
    _headingFilter = null;
  }

  void _onCompassEvent(CompassEvent event) {
    if (!mounted || _bearing == null) return;
    final raw = event.heading;
    if (raw == null) {
      if (!_hasHeading && !_noCompass) setState(() => _noCompass = true);
      return;
    }
    // Bozuk okuma süzgeci kalıcı bozmasın
    if (!raw.isFinite) return;
    _noSensorTimer?.cancel();
    _noSensorTimer = null;
    _compassAccuracy = event.accuracy;
    _updateCalibration();

    // Manyetik kuzey → coğrafi kuzey (kıble açısı coğrafi), sonra titreşim
    // süzgeci
    final filter = smoothHeading(
      _headingFilter,
      trueHeading(raw, _geomagnetic?.declination),
    );
    _headingFilter = filter;
    final heading = filteredHeading(filter);
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

  /// Doğruluk [_calibrationDelay] boyunca zayıf/bilinmiyorsa (ya da
  /// manyetometre kalibrasyon istiyorsa) uyarı açılır, iyi okuma gelince
  /// hemen kapanır
  void _updateCalibration() {
    final poor = calibrationPoor(
      compassAccuracy: _compassAccuracy,
      magnetometerAccuracy: _magnetometerAccuracy,
    );
    if (!poor) {
      _calibrationTimer?.cancel();
      _calibrationTimer = null;
      if (_calibrationPoor) setState(() => _calibrationPoor = false);
      return;
    }
    if (_calibrationPoor || _calibrationTimer != null) return;
    _calibrationTimer = Timer(_calibrationDelay, _onCalibrationPoor);
  }

  /// Manyetometre: doğruluğu kalibrasyon kararına katılır; beklenen alan
  /// şiddeti biliniyorsa parazit denetlenir
  void _onMagneticReading(MagneticReading reading) {
    if (!mounted) return;
    _magnetometerAccuracy = reading.accuracy;
    // Pusula yön vermeden karar verilmez (pusulasız cihazda pencere açılmasın)
    if (_hasHeading) _updateCalibration();
    final deviation = fieldDeviation(reading.magnitude, _geomagnetic?.strength);
    if (deviation == null) return;
    _updateInterference(
      magneticInterference(deviation, warning: _interference),
    );
  }

  /// Parazit [_interferenceDelay] boyunca sürerse uyarı açılır; alan
  /// [_interferenceClearDelay] boyunca normal kalınca kapanır
  void _updateInterference(bool disturbed) {
    if (disturbed == _interference) {
      _interferenceTimer?.cancel();
      _interferenceTimer = null;
      return;
    }
    _interferenceTimer ??= Timer(
      _interference ? _interferenceClearDelay : _interferenceDelay,
      () {
        _interferenceTimer = null;
        if (mounted) setState(() => _interference = !_interference);
      },
    );
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

  String _angleText(AppLocalizations loc, double bearing) {
    final value = _deg(bearing);
    return _isolateDegrees(loc.qiblaAngle(value), value);
  }

  String _headingText(AppLocalizations loc, double heading) {
    final value = _deg(heading);
    return _isolateDegrees(loc.phoneHeading(value), value);
  }

  /// "Doğru sonuç için": ipuçları ve hesaplanan değerler (açılış anındaki)
  void _showAccuracyTips(double bearing) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _AccuracyTipsSheet(
        bearing: bearing,
        declination: _geomagnetic?.declination,
      ),
    );
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: AppSpacing.sm,
                    children: [
                      if (_interference)
                        InfoBanner(
                          message: loc.qiblaInterferenceWarning,
                          tone: InfoTone.warning,
                        ),
                      if (_calibrationPoor)
                        InfoBanner(
                          message: loc.lowAccuracyWarning,
                          icon: Icons.screen_rotation,
                          tone: InfoTone.warning,
                        ),
                      // Uyarı yokken kalibrasyon ipucu
                      if (!_interference && !_calibrationPoor)
                        InfoBanner(
                          message:
                              '${loc.qiblaCalibration} ${loc.keepAwayMetal}',
                          icon: Icons.screen_rotation,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _AccuracyNote(onInfo: () => _showAccuracyTips(bearing)),
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

/// Arka plan resmi seçiliyken (Scaffold şeffaf) fotoğraf üstündeki yazının koyu
/// zemini (SectionHeader kapsülüyle aynı karartma); resim yoksa çocuk olduğu
/// gibi çizilir
class _ImageScrim extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _ImageScrim({
    required this.child,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.xs,
    ),
  });

  static bool onPhoto(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor.a == 0;

  @override
  Widget build(BuildContext context) {
    if (!onPhoto(context)) return child;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: PrayerColors.of(context).heroImageScrim,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(padding: padding, child: child),
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
    // Fotoğraf üstünde koyu zeminde beyaz (marka/başarı rengi okunmaz)
    final onImage = _ImageScrim.onPhoto(context);
    final style = theme.textTheme.titleLarge!.copyWith(
      fontWeight: FontWeight.w700,
    );

    Widget child;
    if (!hasHeading || turn == null) {
      child = Text(
        loc.qiblaDirection,
        textAlign: TextAlign.center,
        style: style.copyWith(
          color: onImage ? colors.onHeroMuted : scheme.onSurfaceVariant,
        ),
      );
    } else if (turn == QiblaTurn.aligned) {
      final color = onImage ? colors.onHero : colors.success;
      child = Semantics(
        liveRegion: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: color, size: 28),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                loc.qiblaFound,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: style.copyWith(color: color),
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
      final color = onImage ? colors.onHero : scheme.primary;
      // Ok her dilde fiziksel dönüş tarafında durur (Arapçada da sağ = sağ)
      final arrow = ExcludeSemantics(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Icon(icon, color: color, size: 30),
        ),
      );
      final text = Flexible(
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: style.copyWith(color: color),
        ),
      );
      child = Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.ltr,
        children: right
            ? [text, const SizedBox(width: AppSpacing.sm), arrow]
            : [arrow, const SizedBox(width: AppSpacing.sm), text],
      );
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: Center(child: _ImageScrim(child: child)),
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
    final colors = PrayerColors.of(context);
    final onImage = _ImageScrim.onPhoto(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Center(
        child: _ImageScrim(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                bearingText,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge!.copyWith(
                  color: onImage ? colors.onHero : scheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (headingText != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  headingText!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge!.copyWith(
                    color: onImage
                        ? colors.onHeroMuted
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Pusulanın altındaki doğruluk notu: her zaman görünür, göze batmaz; bilgi
/// düğmesi "Doğru sonuç için" sayfasını açar
class _AccuracyNote extends StatelessWidget {
  final VoidCallback onInfo;

  const _AccuracyNote({required this.onInfo});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = PrayerColors.of(context);
    final onImage = _ImageScrim.onPhoto(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: _ImageScrim(
        padding: const EdgeInsetsDirectional.only(start: AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Text(
                loc.qiblaAccuracyNote,
                style: theme.textTheme.bodySmall!.copyWith(
                  color: onImage ? colors.onHero : scheme.onSurfaceVariant,
                ),
              ),
            ),
            IconButton(
              onPressed: onInfo,
              tooltip: loc.qiblaTipsTitle,
              color: onImage ? colors.onHero : scheme.primary,
              icon: const Icon(Icons.info_outline),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Doğru sonuç için" alt sayfası: ipuçları ve hesaplanan değerler (kıble
/// açısı coğrafi kuzeyden; sapma biliniyorsa otomatik düzeltildiği)
class _AccuracyTipsSheet extends StatelessWidget {
  final double bearing;
  final double? declination;

  const _AccuracyTipsSheet({required this.bearing, required this.declination});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tips = <(IconData, String)>[
      (Icons.smartphone, loc.qiblaTipFlat),
      (Icons.all_inclusive, loc.qiblaTipCalibrate),
      (Icons.phonelink_erase, loc.qiblaTipMagneticCase),
      (Icons.devices_other, loc.qiblaTipMetal),
      (Icons.mosque, loc.qiblaTipMosque),
    ];
    final angle = _deg(bearing);
    final offset = declination == null ? null : formatDeclination(declination!);
    final values = <(IconData, String)>[
      (
        Icons.explore_outlined,
        _isolateDegrees(loc.qiblaAngleTrueNorth(angle), angle),
      ),
      if (offset != null)
        (Icons.north, _isolateDegrees(loc.qiblaDeclination(offset), offset)),
    ];

    Widget line(IconData icon, String text, TextStyle style, Color iconColor) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(text, style: style)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      // + gezinme çubuğu (uçtan uca): son satır altında kalmasın
      padding: EdgeInsetsDirectional.fromSTEB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(loc.qiblaTipsTitle, style: theme.textTheme.titleLarge),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final (icon, text) in tips)
            line(icon, text, theme.textTheme.bodyLarge!, scheme.primary),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (icon, text) in values)
                  line(
                    icon,
                    text,
                    theme.textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    scheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
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
